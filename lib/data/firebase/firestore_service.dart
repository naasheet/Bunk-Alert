import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:bunk_alert/data/models/attendance_record_model.dart';

class FirestoreService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> userProfileDoc(String userId) {
    return _firestore.collection('users').doc(userId).collection('profile').doc('profile');
  }

  CollectionReference<Map<String, dynamic>> userSubjectsCollection(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('subjects');
  }

  CollectionReference<Map<String, dynamic>> userTimetableCollection(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('timetable_entries');
  }

  CollectionReference<Map<String, dynamic>> userAttendanceCollection(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('attendance_records');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUserSubjects(
    String userId,
  ) {
    return userSubjectsCollection(userId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUserAttendanceRecords(
    String userId,
  ) {
    return userAttendanceCollection(userId).snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(
    String userId,
  ) {
    return userProfileDoc(userId).get();
  }

  CollectionReference<Map<String, dynamic>> userFcmTokensCollection(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('fcm_tokens');
  }

  DocumentReference<Map<String, dynamic>> groupDoc(String groupId) {
    return _firestore.collection('groups').doc(groupId);
  }

  DocumentReference<Map<String, dynamic>> groupAttendanceSummaryDoc({
    required String groupId,
    required String userId,
  }) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('attendance_summary')
        .doc(userId);
  }

  CollectionReference<Map<String, dynamic>> groupMemberSubjectSummaries({
    required String groupId,
    required String userId,
  }) {
    return groupAttendanceSummaryDoc(groupId: groupId, userId: userId)
        .collection('subjects');
  }

  DocumentReference<Map<String, dynamic>> _attendanceDoc({
    required String userId,
    required String recordId,
  }) {
    return userAttendanceCollection(userId).doc(recordId);
  }

  Map<String, dynamic> _attendanceToMap(
    AttendanceRecordModel record, {
    String? note,
  }) {
    return {
      'subjectId': record.subjectUuid,
      'date': record.date,
      'status': record.status,
      if (record.timetableEntryUuid != null)
        'timetableEntryUuid': record.timetableEntryUuid,
      if ((record.note ?? note)?.trim().isNotEmpty == true)
        'note': (record.note ?? note)!.trim(),
      'syncedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> upsertUserProfile({
    required String userId,
    required String name,
    required String email,
    required int targetPercentage,
    bool setCreatedAt = false,
  }) {
    final data = <String, dynamic>{
      'name': name,
      'email': email,
      'targetPercentage': targetPercentage,
      if (setCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
    };
    return userProfileDoc(userId).set(data, SetOptions(merge: true));
  }

  Future<void> upsertSubject({
    required String userId,
    required String subjectId,
    required String name,
    required int colorTagIndex,
    double? targetPercentage,
    int? expectedTotalClasses,
    required bool isArchived,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return userSubjectsCollection(userId).doc(subjectId).set(
      {
        'name': name,
        'colorTagIndex': colorTagIndex,
        if (targetPercentage != null) 'targetPercentage': targetPercentage,
        if (expectedTotalClasses != null)
          'expectedTotalClasses': expectedTotalClasses,
        'isArchived': isArchived,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> upsertTimetableEntry({
    required String userId,
    required String entryId,
    required String subjectId,
    required int dayOfWeek,
    required int startMinutes,
    required int endMinutes,
    required bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return userTimetableCollection(userId).doc(entryId).set(
      {
        'subjectId': subjectId,
        'dayOfWeek': dayOfWeek,
        'startMinutes': startMinutes,
        'endMinutes': endMinutes,
        'isActive': isActive,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> upsertAttendanceRecord({
    required String userId,
    required AttendanceRecordModel record,
    String? note,
  }) {
    return _attendanceDoc(
      userId: userId,
      recordId: record.uuid,
    ).set(
      _attendanceToMap(record, note: note),
      SetOptions(merge: true),
    );
  }

  WriteBatch buildAttendanceBatch({
    required String userId,
    required List<AttendanceRecordModel> records,
    String? note,
  }) {
    final batch = _firestore.batch();
    for (final record in records) {
      batch.set(
        _attendanceDoc(
          userId: userId,
          recordId: record.uuid,
        ),
        _attendanceToMap(record, note: note),
        SetOptions(merge: true),
      );
    }
    return batch;
  }

  Future<void> upsertGroup({
    required String groupId,
    required String name,
    required String inviteCode,
    required String createdBy,
    required List<String> members,
    bool setCreatedAt = false,
  }) {
    final data = <String, dynamic>{
      'name': name,
      'inviteCode': inviteCode,
      'createdBy': createdBy,
      'members': members,
      if (setCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
    };
    return groupDoc(groupId).set(data, SetOptions(merge: true));
  }

  Future<void> upsertAttendanceSummary({
    required String groupId,
    required String userId,
    required double overallPercentage,
    required String displayName,
  }) {
    return groupAttendanceSummaryDoc(groupId: groupId, userId: userId).set(
      {
        'displayName': displayName,
        'overallPercentage': overallPercentage,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> upsertMemberSubjectSummary({
    required String groupId,
    required String userId,
    required String subjectId,
    required String name,
    required int attended,
    required int conducted,
    required double percentage,
    required bool isArchived,
  }) {
    return groupMemberSubjectSummaries(groupId: groupId, userId: userId)
        .doc(subjectId)
        .set(
      {
        'name': name,
        'attended': attended,
        'conducted': conducted,
        'percentage': percentage,
        'isArchived': isArchived,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchGroupsForUser(
    String userId,
  ) {
    return _firestore
        .collection('groups')
        .where('members', arrayContains: userId)
        .snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getGroupsForUser(
    String userId,
  ) {
    return _firestore
        .collection('groups')
        .where('members', arrayContains: userId)
        .get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getUserSubjects(
    String userId,
  ) {
    return userSubjectsCollection(userId).get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getUserTimetableEntries(
    String userId,
  ) {
    return userTimetableCollection(userId).get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getUserAttendanceRecords(
    String userId,
  ) {
    return userAttendanceCollection(userId).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchGroup(
    String groupId,
  ) {
    return groupDoc(groupId).snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getGroup(
    String groupId,
  ) {
    return groupDoc(groupId).get();
  }

  Future<void> addGroupMember({
    required String groupId,
    required String userId,
  }) {
    return groupDoc(groupId).update({
      'members': FieldValue.arrayUnion([userId]),
    });
  }

  Future<Map<String, dynamic>> joinGroupByInviteCode({
    required String inviteCode,
  }) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('joinGroupByInviteCode');
    final result = await callable.call(<String, dynamic>{
      'inviteCode': inviteCode,
    });
    final payload = result.data;
    if (payload is Map) {
      return Map<String, dynamic>.from(payload as Map);
    }
    throw FirebaseException(
      plugin: 'cloud_functions',
      code: 'data-loss',
      message: 'joinGroupByInviteCode returned an invalid payload.',
    );
  }

  Future<void> removeGroupMember({
    required String groupId,
    required String userId,
  }) {
    return groupDoc(groupId).update({
      'members': FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> deleteAttendanceSummary({
    required String groupId,
    required String userId,
  }) {
    return groupAttendanceSummaryDoc(groupId: groupId, userId: userId)
        .delete();
  }

  Query<Map<String, dynamic>> attendanceSummaryQuery(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('attendance_summary');
  }

  Future<void> upsertFcmToken({
    required String userId,
    required String token,
    required String platform,
  }) {
    return userFcmTokensCollection(userId).doc(token).set(
      {
        'token': token,
        'platform': platform,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteSubject({
    required String userId,
    required String subjectId,
  }) {
    return userSubjectsCollection(userId).doc(subjectId).delete();
  }

  Future<void> deleteTimetableEntriesBySubject({
    required String userId,
    required String subjectId,
  }) {
    final query = userTimetableCollection(userId)
        .where('subjectId', isEqualTo: subjectId);
    return _deleteByQuery(query);
  }

  Future<void> deleteAttendanceRecordsBySubject({
    required String userId,
    required String subjectId,
  }) {
    final query = userAttendanceCollection(userId)
        .where('subjectId', isEqualTo: subjectId);
    return _deleteByQuery(query);
  }

  Future<void> deleteAttendanceRecord({
    required String userId,
    required String recordId,
  }) {
    return userAttendanceCollection(userId).doc(recordId).delete();
  }

  Future<void> _deleteByQuery(
    Query<Map<String, dynamic>> query,
  ) async {
    var snapshot = await query.limit(200).get();
    while (snapshot.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      snapshot = await query.limit(200).get();
    }
  }
}
