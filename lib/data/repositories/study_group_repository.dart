import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isar/isar.dart';

import 'package:bunk_alert/data/database/local_database_service.dart';
import 'package:bunk_alert/data/firebase/firestore_service.dart';
import 'package:bunk_alert/data/models/group_member_summary.dart';
import 'package:bunk_alert/data/models/group_member_subject_summary.dart';
import 'package:bunk_alert/data/models/study_group_model.dart';
import 'package:bunk_alert/shared/auth/app_auth.dart';

class StudyGroupFailure implements Exception {
  StudyGroupFailure(this.message);
  final String message;
}

class StudyGroupRepository {
  StudyGroupRepository({
    LocalDatabaseService? localDatabaseService,
    FirestoreService? firestoreService,
  })  : _localDatabaseService =
            localDatabaseService ?? LocalDatabaseService.instance,
        _firestoreService = firestoreService ?? FirestoreService();

  static final StudyGroupRepository instance = StudyGroupRepository();

  final LocalDatabaseService _localDatabaseService;
  final FirestoreService _firestoreService;
  final Random _random = Random.secure();

  Stream<List<StudyGroupModel>> watchGroupsForCurrentUser() {
    final userId = AppAuth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(const <StudyGroupModel>[]);
    }
    return _firestoreService.watchGroupsForUser(userId).map(
      (snapshot) {
        return snapshot.docs
            .map((doc) => StudyGroupModel.fromMap(
                  id: doc.id,
                  data: doc.data(),
                ))
            .toList();
      },
    );
  }

  Stream<StudyGroupModel?> watchGroup(String groupId) {
    return _firestoreService.watchGroup(groupId).map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return StudyGroupModel.fromMap(id: snapshot.id, data: data);
    });
  }

  Stream<List<GroupMemberSummary>> watchLeaderboard(
    String groupId,
  ) {
    return _watchLeaderboardFromUserData(groupId);
  }

  Stream<List<GroupMemberSubjectSummary>> watchMemberSubjectSummaries({
    required String groupId,
    required String userId,
  }) {
    return _watchMemberSubjectSummariesFromUserData(userId);
  }

  Future<List<GroupMemberSubjectSummary>> getLocalSubjectSummaries() async {
    final subjects = await _localDatabaseService.subjects.where().findAll();
    final records =
        await _localDatabaseService.attendanceRecords.where().findAll();
    final perSubject = <String, _SubjectTally>{};
    for (final record in records) {
      switch (record.status) {
        case 'present':
          perSubject.update(
            record.subjectUuid,
            (value) => value.add(attended: 1, conducted: 1),
            ifAbsent: () =>
                const _SubjectTally().add(attended: 1, conducted: 1),
          );
        case 'absent':
          perSubject.update(
            record.subjectUuid,
            (value) => value.add(attended: 0, conducted: 1),
            ifAbsent: () =>
                const _SubjectTally().add(attended: 0, conducted: 1),
          );
        case 'cancelled':
          break;
      }
    }

    final summaries = subjects
        .where((subject) => !subject.isArchived)
        .map((subject) {
      final tally = perSubject[subject.uuid] ?? const _SubjectTally();
      final percentage = tally.conducted == 0
          ? 0.0
          : (tally.attended / tally.conducted) * 100;
      return GroupMemberSubjectSummary(
        subjectId: subject.uuid,
        name: subject.name,
        attended: tally.attended,
        conducted: tally.conducted,
        percentage: percentage,
        isArchived: subject.isArchived,
        updatedAt: null,
      );
    }).toList();

    summaries.sort((a, b) => a.name.compareTo(b.name));
    return summaries;
  }

  Stream<List<GroupMemberSummary>> watchTopMembers(
    String groupId, {
    int limit = 3,
  }) {
    return watchLeaderboard(groupId).map((members) {
      if (members.length <= limit) {
        return members;
      }
      return members.take(limit).toList();
    });
  }

  Stream<List<GroupMemberSummary>> _watchLeaderboardFromUserData(
    String groupId,
  ) {
    final controller =
        StreamController<List<GroupMemberSummary>>.broadcast();
    StreamSubscription<StudyGroupModel?>? groupSubscription;
    final memberSubscriptions =
        <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};
    final memberStats = <String, _MemberAttendanceStats>{};
    final memberNames = <String, String>{};
    var currentMembers = <String>[];

    void pushUpdate() {
      if (controller.isClosed) {
        return;
      }
      final summaries = currentMembers.map((memberId) {
        final stats = memberStats[memberId] ?? const _MemberAttendanceStats();
        final percent = stats.conducted == 0
            ? 0.0
            : (stats.attended / stats.conducted) * 100;
        final displayName =
            memberNames[memberId] ?? _fallbackDisplayName(memberId);
        return GroupMemberSummary(
          userId: memberId,
          displayName: displayName,
          overallPercentage: percent,
          updatedAt: null,
        );
      }).toList()
        ..sort((a, b) {
          final diff =
              b.overallPercentage.compareTo(a.overallPercentage);
          if (diff != 0) {
            return diff;
          }
          return a.displayName.compareTo(b.displayName);
        });
      controller.add(summaries);
    }

    Future<void> ensureDisplayName(String memberId) async {
      if (memberNames.containsKey(memberId)) {
        return;
      }
      try {
        final profile = await _firestoreService.getUserProfile(memberId);
        final data = profile.data();
        final name = (data?['name'] as String?)?.trim();
        final email = (data?['email'] as String?)?.trim();
        memberNames[memberId] = name?.isNotEmpty == true
            ? name!
            : email?.isNotEmpty == true
                ? email!
                : memberId;
      } catch (_) {
        memberNames[memberId] = memberId;
      }
      pushUpdate();
    }

    void updateMemberStats(
      String memberId,
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      var attended = 0;
      var conducted = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'];
        if (status == 'present') {
          attended++;
          conducted++;
        } else if (status == 'absent') {
          conducted++;
        }
      }
      memberStats[memberId] =
          _MemberAttendanceStats(attended: attended, conducted: conducted);
      pushUpdate();
    }

    void resubscribeMembers(List<String> members) {
      final removed = memberSubscriptions.keys
          .where((id) => !members.contains(id))
          .toList();
      for (final memberId in removed) {
        memberSubscriptions.remove(memberId)?.cancel();
        memberStats.remove(memberId);
        memberNames.remove(memberId);
      }

      for (final memberId in members) {
        if (memberSubscriptions.containsKey(memberId)) {
          continue;
        }
        ensureDisplayName(memberId);
        memberSubscriptions[memberId] = _firestoreService
            .watchUserAttendanceRecords(memberId)
            .listen(
          (snapshot) => updateMemberStats(memberId, snapshot),
          onError: (_) {},
        );
      }
      currentMembers = members;
      pushUpdate();
    }

    groupSubscription = watchGroup(groupId).listen(
      (group) {
        if (group == null) {
          currentMembers = [];
          for (final sub in memberSubscriptions.values) {
            sub.cancel();
          }
          memberSubscriptions.clear();
          memberStats.clear();
          memberNames.clear();
          pushUpdate();
          return;
        }
        resubscribeMembers(group.members);
      },
      onError: (error, stack) {
        if (!controller.isClosed) {
          controller.addError(error, stack);
        }
      },
    );

    controller.onCancel = () {
      groupSubscription?.cancel();
      for (final sub in memberSubscriptions.values) {
        sub.cancel();
      }
      memberSubscriptions.clear();
    };

    return controller.stream;
  }

  Stream<List<GroupMemberSubjectSummary>>
      _watchMemberSubjectSummariesFromUserData(String userId) {
    final controller =
        StreamController<List<GroupMemberSubjectSummary>>.broadcast();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subjectsSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? recordsSub;
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? subjects;
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? records;

    void recompute() {
      if (subjects == null || records == null) {
        return;
      }
      final subjectMap = <String, Map<String, dynamic>>{};
      for (final doc in subjects!) {
        subjectMap[doc.id] = doc.data();
      }
      final tallies = <String, _MemberAttendanceStats>{};
      for (final doc in records!) {
        final data = doc.data();
        final subjectId = data['subjectId'] as String?;
        if (subjectId == null) {
          continue;
        }
        final status = data['status'];
        final current = tallies[subjectId] ??
            const _MemberAttendanceStats(attended: 0, conducted: 0);
        if (status == 'present') {
          tallies[subjectId] = _MemberAttendanceStats(
            attended: current.attended + 1,
            conducted: current.conducted + 1,
          );
        } else if (status == 'absent') {
          tallies[subjectId] = _MemberAttendanceStats(
            attended: current.attended,
            conducted: current.conducted + 1,
          );
        }
      }

      final summaries = <GroupMemberSubjectSummary>[];
      for (final entry in subjectMap.entries) {
        final data = entry.value;
        final tally = tallies[entry.key] ?? const _MemberAttendanceStats();
        final percent = tally.conducted == 0
            ? 0.0
            : (tally.attended / tally.conducted) * 100;
        summaries.add(
          GroupMemberSubjectSummary(
            subjectId: entry.key,
            name: (data['name'] as String?)?.trim().isNotEmpty == true
                ? data['name'] as String
                : 'Subject',
            attended: tally.attended,
            conducted: tally.conducted,
            percentage: percent,
            isArchived: data['isArchived'] as bool? ?? false,
            updatedAt: null,
          ),
        );
      }

      for (final entry in tallies.entries) {
        if (subjectMap.containsKey(entry.key)) {
          continue;
        }
        final tally = entry.value;
        final percent = tally.conducted == 0
            ? 0.0
            : (tally.attended / tally.conducted) * 100;
        summaries.add(
          GroupMemberSubjectSummary(
            subjectId: entry.key,
            name: 'Subject',
            attended: tally.attended,
            conducted: tally.conducted,
            percentage: percent,
            isArchived: false,
            updatedAt: null,
          ),
        );
      }

      summaries.removeWhere((summary) => summary.isArchived);
      summaries.sort((a, b) => a.name.compareTo(b.name));
      if (!controller.isClosed) {
        controller.add(summaries);
      }
    }

    subjectsSub = _firestoreService
        .watchUserSubjects(userId)
        .listen((snapshot) {
      subjects = snapshot.docs;
      recompute();
    }, onError: (error, stack) {
      if (!controller.isClosed) {
        controller.addError(error, stack);
      }
    });

    recordsSub = _firestoreService
        .watchUserAttendanceRecords(userId)
        .listen((snapshot) {
      records = snapshot.docs;
      recompute();
    }, onError: (error, stack) {
      if (!controller.isClosed) {
        controller.addError(error, stack);
      }
    });

    controller.onCancel = () {
      subjectsSub?.cancel();
      recordsSub?.cancel();
    };

    return controller.stream;
  }

  String _fallbackDisplayName(String memberId) {
    final currentUser = AppAuth.currentUser;
    if (currentUser != null && currentUser.uid == memberId) {
      return _resolveDisplayName(currentUser);
    }
    return memberId;
  }

  Future<StudyGroupModel> createGroup({
    required String name,
  }) async {
    final user = AppAuth.currentUser;
    if (user == null) {
      throw StudyGroupFailure('Please sign in to create a group.');
    }
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw StudyGroupFailure('Group name is required.');
    }

    final inviteCode = await _generateUniqueInviteCode();
    await _firestoreService.upsertGroup(
      groupId: inviteCode,
      name: trimmedName,
      inviteCode: inviteCode,
      createdBy: user.uid,
      members: [user.uid],
      setCreatedAt: true,
    );
    return StudyGroupModel(
      id: inviteCode,
      name: trimmedName,
      inviteCode: inviteCode,
      createdBy: user.uid,
      members: [user.uid],
      createdAt: DateTime.now(),
    );
  }

  Future<StudyGroupModel> joinGroup({
    required String inviteCode,
  }) async {
    final user = AppAuth.currentUser;
    if (user == null) {
      throw StudyGroupFailure('Please sign in to join a group.');
    }
    final code = inviteCode.trim().toUpperCase();
    if (code.isEmpty) {
      throw StudyGroupFailure('Enter a valid invite code.');
    }
    try {
      final snapshot = await _firestoreService.getGroup(code);
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        throw StudyGroupFailure('Invite code not found.');
      }
      await _firestoreService.addGroupMember(
        groupId: code,
        userId: user.uid,
      );
      final refreshed = await _firestoreService.getGroup(code);
      final refreshedData = refreshed.data();
      if (!refreshed.exists || refreshedData == null) {
        throw StudyGroupFailure('Invite code not found.');
      }
      return StudyGroupModel.fromMap(id: refreshed.id, data: refreshedData);
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') {
        rethrow;
      }
    }
    try {
      final payload = await _firestoreService.joinGroupByInviteCode(
        inviteCode: code,
      );
      final groupId = (payload['groupId'] as String?)?.trim();
      final data = Map<String, dynamic>.from(payload)
        ..remove('groupId');
      return StudyGroupModel.fromMap(
        id: groupId?.isNotEmpty == true ? groupId! : code,
        data: data,
      );
    } on FirebaseException catch (error) {
      if (error.code == 'not-found' &&
          (error.message ?? '').toLowerCase().contains('invite code')) {
        throw StudyGroupFailure('Invite code not found.');
      }
      if (error.code == 'not-found') {
        throw StudyGroupFailure(
          'Join service is not deployed. Deploy Cloud Functions and retry.',
        );
      }
      rethrow;
    }
  }

  Future<void> leaveGroup({
    required String groupId,
  }) async {
    final user = AppAuth.currentUser;
    if (user == null) {
      throw StudyGroupFailure('Please sign in to leave a group.');
    }
    await _firestoreService.removeGroupMember(
      groupId: groupId,
      userId: user.uid,
    );
    await _firestoreService.deleteAttendanceSummary(
      groupId: groupId,
      userId: user.uid,
    );
  }

  Future<void> renameGroup({
    required StudyGroupModel group,
    required String name,
  }) async {
    final user = AppAuth.currentUser;
    if (user == null) {
      throw StudyGroupFailure('Please sign in to edit this group.');
    }
    if (group.createdBy != user.uid) {
      throw StudyGroupFailure('Only the group owner can edit this group.');
    }
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw StudyGroupFailure('Group name is required.');
    }
    await _firestoreService.groupDoc(group.id).update({
      'name': trimmedName,
    });
  }

  Future<void> kickMember({
    required StudyGroupModel group,
    required String memberId,
  }) async {
    final user = AppAuth.currentUser;
    if (user == null) {
      throw StudyGroupFailure('Please sign in to manage members.');
    }
    if (group.createdBy != user.uid) {
      throw StudyGroupFailure('Only the group owner can remove members.');
    }
    if (memberId == user.uid) {
      throw StudyGroupFailure('You cannot remove yourself.');
    }
    await _firestoreService.removeGroupMember(
      groupId: group.id,
      userId: memberId,
    );
    await _firestoreService.deleteAttendanceSummary(
      groupId: group.id,
      userId: memberId,
    );
  }

  Future<void> deleteGroup({
    required StudyGroupModel group,
  }) async {
    final user = AppAuth.currentUser;
    if (user == null) {
      throw StudyGroupFailure('Please sign in to delete this group.');
    }
    if (group.createdBy != user.uid) {
      throw StudyGroupFailure('Only the group owner can delete this group.');
    }
    await _firestoreService.groupDoc(group.id).delete();
  }

  Future<void> syncOverallSummary({List<String>? groupIds}) async {
    return;
  }

  Future<String> _generateUniqueInviteCode() async {
    const charset = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    for (var attempt = 0; attempt < 8; attempt++) {
      final code = List.generate(
        6,
        (_) => charset[_random.nextInt(charset.length)],
      ).join();
      final snapshot = await _firestoreService.getGroup(code);
      if (!snapshot.exists) {
        return code;
      }
    }
    throw StudyGroupFailure(
      'Unable to generate a unique invite code.',
    );
  }

  String _resolveDisplayName(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    final email = user.email?.trim();
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'Student';
  }
}

class _MemberAttendanceStats {
  const _MemberAttendanceStats({this.attended = 0, this.conducted = 0});

  final int attended;
  final int conducted;
}

class _SubjectTally {
  const _SubjectTally({this.attended = 0, this.conducted = 0});

  final int attended;
  final int conducted;

  _SubjectTally add({required int attended, required int conducted}) {
    return _SubjectTally(
      attended: this.attended + attended,
      conducted: this.conducted + conducted,
    );
  }
}
