import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isar/isar.dart';

import 'package:bunk_alert/data/database/local_database_service.dart';
import 'package:bunk_alert/data/firebase/firestore_service.dart';
import 'package:bunk_alert/data/models/attendance_record_model.dart';
import 'package:bunk_alert/data/models/subject_model.dart';
import 'package:bunk_alert/data/models/timetable_entry_model.dart';
import 'package:bunk_alert/data/notifications/notification_scheduler_service.dart';
import 'package:bunk_alert/data/repositories/study_group_repository.dart';
import 'package:bunk_alert/shared/auth/app_auth.dart';

class SubjectRepository {
  SubjectRepository({
    LocalDatabaseService? localDatabaseService,
    FirestoreService? firestoreService,
  })
      : _localDatabaseService =
            localDatabaseService ?? LocalDatabaseService.instance,
        _firestoreService = firestoreService ?? FirestoreService();

  final LocalDatabaseService _localDatabaseService;
  final FirestoreService _firestoreService;
  final StudyGroupRepository _studyGroupRepository =
      StudyGroupRepository.instance;

  Future<SubjectModel?> getSubjectById(String subjectId) async {
    final isar = _localDatabaseService.isar;
    return isar.subjectModels
        .filter()
        .uuidEqualTo(subjectId)
        .findFirst();
  }

  Future<void> upsertSubject(SubjectModel subject) async {
    final isar = _localDatabaseService.isar;
    final now = DateTime.now();
    final updated = subject.copyWith(
      syncStatus: 'pending',
      updatedAt: now,
    );
    await isar.writeTxn(() async {
      await isar.subjectModels.put(updated);
    });
    _queueSync();
  }

  Future<void> updateTargetPercentage({
    required String subjectId,
    required double? targetPercentage,
  }) async {
    final isar = _localDatabaseService.isar;
    await isar.writeTxn(() async {
      final subject = await isar.subjectModels
          .filter()
          .uuidEqualTo(subjectId)
          .findFirst();
      if (subject == null) {
        return;
      }
      final updated = subject.copyWith(
        targetPercentage: targetPercentage,
        syncStatus: 'pending',
        updatedAt: DateTime.now(),
      );
      await isar.subjectModels.put(updated);
    });
    _queueSync();
  }

  Future<void> updateExpectedTotalClasses({
    required String subjectId,
    required int? expectedTotalClasses,
  }) async {
    final isar = _localDatabaseService.isar;
    await isar.writeTxn(() async {
      final subject = await isar.subjectModels
          .filter()
          .uuidEqualTo(subjectId)
          .findFirst();
      if (subject == null) {
        return;
      }
      final updated = subject.copyWith(
        expectedTotalClasses: expectedTotalClasses,
        syncStatus: 'pending',
        updatedAt: DateTime.now(),
      );
      await isar.subjectModels.put(updated);
    });
    _queueSync();
  }

  Future<List<SubjectModel>> getActiveSubjects() async {
    final isar = _localDatabaseService.isar;
    return isar.subjectModels
        .filter()
        .isArchivedEqualTo(false)
        .sortByName()
        .findAll();
  }

  Future<List<SubjectModel>> getAllSubjects() async {
    final isar = _localDatabaseService.isar;
    return isar.subjectModels.where().findAll();
  }

  Future<int> getActiveSubjectCount() async {
    final isar = _localDatabaseService.isar;
    return isar.subjectModels
        .filter()
        .isArchivedEqualTo(false)
        .count();
  }

  Future<void> setArchived({
    required String subjectId,
    required bool isArchived,
  }) async {
    final isar = _localDatabaseService.isar;
    await isar.writeTxn(() async {
      final subject = await isar.subjectModels
          .filter()
          .uuidEqualTo(subjectId)
          .findFirst();
      if (subject == null) {
        return;
      }
      final updated = subject.copyWith(
        isArchived: isArchived,
        syncStatus: 'pending',
        updatedAt: DateTime.now(),
      );
      await isar.subjectModels.put(updated);
    });
    _queueSync();
  }

  Future<void> deleteSubject({
    required String subjectId,
  }) async {
    final isar = _localDatabaseService.isar;
    final timetableEntries = await _localDatabaseService.timetableEntries
        .filter()
        .subjectUuidEqualTo(subjectId)
        .findAll();
    await isar.writeTxn(() async {
      final subjectIds = await isar.subjectModels
          .filter()
          .uuidEqualTo(subjectId)
          .idProperty()
          .findAll();
      if (subjectIds.isNotEmpty) {
        await isar.subjectModels.deleteAll(subjectIds);
      }

      final attendanceIds = await _localDatabaseService.attendanceRecords
          .filter()
          .subjectUuidEqualTo(subjectId)
          .idProperty()
          .findAll();
      if (attendanceIds.isNotEmpty) {
        await _localDatabaseService.attendanceRecords.deleteAll(attendanceIds);
      }

      final timetableIds = await _localDatabaseService.timetableEntries
          .filter()
          .subjectUuidEqualTo(subjectId)
          .idProperty()
          .findAll();
      if (timetableIds.isNotEmpty) {
        await _localDatabaseService.timetableEntries.deleteAll(timetableIds);
      }
    });

    if (!AppAuthOverrides.isTest) {
      for (final entry in timetableEntries) {
        unawaited(
          NotificationSchedulerService.instance
              .cancelClassReminder(entry.uuid),
        );
      }
      final userId = AppAuth.currentUser?.uid;
      if (userId != null) {
        await _firestoreService.deleteSubject(
          userId: userId,
          subjectId: subjectId,
        );
        await _firestoreService.deleteTimetableEntriesBySubject(
          userId: userId,
          subjectId: subjectId,
        );
        await _firestoreService.deleteAttendanceRecordsBySubject(
          userId: userId,
          subjectId: subjectId,
        );
      }
      unawaited(_studyGroupRepository.syncOverallSummary());
    }
  }

  Future<List<SubjectModel>> getPendingSubjects() async {
    final isar = _localDatabaseService.isar;
    return isar.subjectModels.filter().syncStatusEqualTo('pending').findAll();
  }

  Future<void> syncPendingToCloud({
    required String userId,
  }) async {
    final pending = await getPendingSubjects();
    if (pending.isEmpty) {
      return;
    }
    for (final subject in pending) {
      await _firestoreService.upsertSubject(
        userId: userId,
        subjectId: subject.uuid,
        name: subject.name,
        colorTagIndex: subject.colorTagIndex,
        targetPercentage: subject.targetPercentage,
        expectedTotalClasses: subject.expectedTotalClasses,
        isArchived: subject.isArchived,
        createdAt: subject.createdAt,
        updatedAt: subject.updatedAt,
      );
    }

    final isar = _localDatabaseService.isar;
    await isar.writeTxn(() async {
      for (final subject in pending) {
        final updated = subject.copyWith(
          syncStatus: 'synced',
          updatedAt: DateTime.now(),
        );
        await isar.subjectModels.put(updated);
      }
    });
  }

  Future<void> syncAllToCloud({
    required String userId,
  }) async {
    final subjects = await getAllSubjects();
    if (subjects.isEmpty) {
      return;
    }
    for (final subject in subjects) {
      await _firestoreService.upsertSubject(
        userId: userId,
        subjectId: subject.uuid,
        name: subject.name,
        colorTagIndex: subject.colorTagIndex,
        targetPercentage: subject.targetPercentage,
        expectedTotalClasses: subject.expectedTotalClasses,
        isArchived: subject.isArchived,
        createdAt: subject.createdAt,
        updatedAt: subject.updatedAt,
      );
    }

    final isar = _localDatabaseService.isar;
    await isar.writeTxn(() async {
      for (final subject in subjects) {
        final updated = subject.copyWith(
          syncStatus: 'synced',
          updatedAt: DateTime.now(),
        );
        await isar.subjectModels.put(updated);
      }
    });
  }

  Future<void> pullFromCloud({
    required String userId,
  }) async {
    final snapshot = await _firestoreService.getUserSubjects(userId);
    if (snapshot.docs.isEmpty) {
      return;
    }
    final subjects = snapshot.docs.map(_subjectFromDoc).toList();
    final isar = _localDatabaseService.isar;
    await isar.writeTxn(() async {
      await isar.subjectModels.putAll(subjects);
    });
  }

  SubjectModel _subjectFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final createdAt = _timestampToDateTime(data['createdAt']);
    final updatedAt = _timestampToDateTime(data['updatedAt'], fallback: createdAt);
    final target = data['targetPercentage'];
    final expected = data['expectedTotalClasses'];
    return SubjectModel(
      uuid: doc.id,
      name: (data['name'] as String?) ?? 'Subject',
      colorTagIndex: (data['colorTagIndex'] as num?)?.toInt() ?? 0,
      targetPercentage: target is num ? target.toDouble() : null,
      expectedTotalClasses: expected is num ? expected.toInt() : null,
      isArchived: (data['isArchived'] as bool?) ?? false,
      syncStatus: 'synced',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  DateTime _timestampToDateTime(
    Object? value, {
    DateTime? fallback,
  }) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return fallback ?? DateTime.now();
  }

  void _queueSync() {
    if (AppAuthOverrides.isTest) {
      return;
    }
    final userId = AppAuth.currentUser?.uid;
    if (userId == null) {
      return;
    }
    unawaited(syncPendingToCloud(userId: userId));
  }
}
