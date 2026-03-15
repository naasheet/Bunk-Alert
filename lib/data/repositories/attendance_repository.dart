import 'dart:async';

import 'package:uuid/uuid.dart';
import 'package:isar/isar.dart';

import 'package:bunk_alert/data/database/local_database_service.dart';
import 'package:bunk_alert/data/firebase/firestore_service.dart';
import 'package:bunk_alert/data/models/attendance_record_model.dart';
import 'package:bunk_alert/data/notifications/notification_scheduler_service.dart';
import 'package:bunk_alert/data/repositories/study_group_repository.dart';
import 'package:bunk_alert/domain/usecases/sync_to_cloud_usecase.dart';
import 'package:bunk_alert/shared/auth/app_auth.dart';

class AttendanceRepository {
  AttendanceRepository({
    LocalDatabaseService? localDatabaseService,
    FirestoreService? firestoreService,
    SyncToCloudUsecase? syncToCloudUsecase,
  })  : _localDatabaseService =
            localDatabaseService ?? LocalDatabaseService.instance,
        _firestoreService = firestoreService ?? FirestoreService() {
    _syncToCloudUsecase = syncToCloudUsecase ??
        SyncToCloudUsecase(repository: this);
  }

  final LocalDatabaseService _localDatabaseService;
  final FirestoreService _firestoreService;
  late final SyncToCloudUsecase _syncToCloudUsecase;
  final StudyGroupRepository _studyGroupRepository =
      StudyGroupRepository.instance;
  final Uuid _uuid = const Uuid();

  Future<AttendanceRecordModel> markAttendance({
    required String subjectUuid,
    required String status,
    DateTime? date,
    String? timetableEntryUuid,
    String? note,
  }) async {
    const allowedStatuses = {'present', 'absent', 'cancelled'};
    if (!allowedStatuses.contains(status)) {
      throw ArgumentError('Invalid status: $status');
    }
    final now = DateTime.now();
    final record = AttendanceRecordModel(
      uuid: _uuid.v4(),
      subjectUuid: subjectUuid,
      timetableEntryUuid: timetableEntryUuid,
      date: AttendanceRecordModel.normalizeDate(date ?? now),
      status: status,
      note: note,
      syncStatus: 'pending',
      createdAt: now,
      updatedAt: now,
    );

    return save(record);
  }

  Stream<List<AttendanceRecordModel>> watchBySubjectUuid(
    String subjectUuid,
  ) {
    return _localDatabaseService.attendanceRecords
        .filter()
        .subjectUuidEqualTo(subjectUuid)
        .sortByDateDesc()
        .watch(fireImmediately: true);
  }

  Stream<List<AttendanceRecordModel>> watchAllRecords() {
    return _localDatabaseService.attendanceRecords
        .where()
        .watch(fireImmediately: true);
  }

  Future<List<AttendanceRecordModel>> getAllRecords() {
    return _localDatabaseService.attendanceRecords.where().findAll();
  }

  Future<AttendanceRecordModel?> getBySubjectUuidAndDate(
    String subjectUuid,
    DateTime date,
  ) {
    final normalized = AttendanceRecordModel.normalizeDate(date);
    return _localDatabaseService.attendanceRecords
        .filter()
        .subjectUuidEqualTo(subjectUuid)
        .dateEqualTo(normalized)
        .findFirst();
  }

  Future<AttendanceRecordModel> save(AttendanceRecordModel record) async {
    final now = DateTime.now();
    final normalizedDate =
        AttendanceRecordModel.normalizeDate(record.date);
    final isar = _localDatabaseService.isar;
    AttendanceRecordModel savedRecord = record;

    await isar.writeTxn(() async {
      final existing = record.timetableEntryUuid == null
          ? await _localDatabaseService.attendanceRecords
              .filter()
              .subjectUuidEqualTo(record.subjectUuid)
              .dateEqualTo(normalizedDate)
              .findFirst()
          : await _localDatabaseService.attendanceRecords
              .filter()
              .timetableEntryUuidEqualTo(record.timetableEntryUuid)
              .dateEqualTo(normalizedDate)
              .findFirst();

      if (existing != null) {
        savedRecord = existing.copyWith(
          status: record.status,
          note: record.note,
          timetableEntryUuid: record.timetableEntryUuid,
          syncStatus: 'pending',
          updatedAt: now,
        );
        await _localDatabaseService.attendanceRecords.put(savedRecord);
      } else {
        savedRecord = record.copyWith(
          date: normalizedDate,
          syncStatus: 'pending',
          updatedAt: now,
        );
        await _localDatabaseService.attendanceRecords.put(savedRecord);
      }
    });

    if (!AppAuthOverrides.isTest) {
      unawaited(_syncToCloudUsecase.call());
      unawaited(
        NotificationSchedulerService.instance.checkAndScheduleRiskAlerts(),
      );
      unawaited(_studyGroupRepository.syncOverallSummary());
    }
    return savedRecord;
  }

  Future<void> deleteBySubjectUuid(String subjectUuid) async {
    final isar = _localDatabaseService.isar;
    await isar.writeTxn(() async {
      final ids = await _localDatabaseService.attendanceRecords
          .filter()
          .subjectUuidEqualTo(subjectUuid)
          .idProperty()
          .findAll();
      await _localDatabaseService.attendanceRecords.deleteAll(ids);
    });
  }

  Future<void> deleteAll() async {
    final isar = _localDatabaseService.isar;
    await isar.writeTxn(() async {
      await _localDatabaseService.attendanceRecords.clear();
    });
  }

  Future<void> deleteRecord(AttendanceRecordModel record) async {
    final isar = _localDatabaseService.isar;
    await isar.writeTxn(() async {
      await _localDatabaseService.attendanceRecords.delete(record.id);
    });
  }

  Future<List<AttendanceRecordModel>> getPendingSyncRecords() {
    return _localDatabaseService.attendanceRecords
        .filter()
        .syncStatusEqualTo('pending')
        .findAll();
  }

  Future<int> syncPendingRecords({
    required String userId,
    String? note,
  }) async {
    final pending = await getPendingSyncRecords();

    if (pending.isEmpty) {
      return 0;
    }

    final batch = _firestoreService.buildAttendanceBatch(
      userId: userId,
      records: pending,
      note: note,
    );
    await batch.commit();

    final isar = _localDatabaseService.isar;
    await isar.writeTxn(() async {
      for (final record in pending) {
        final updated = record.copyWith(
          syncStatus: 'synced',
          updatedAt: DateTime.now(),
        );
        await _localDatabaseService.attendanceRecords.put(updated);
      }
    });

    return pending.length;
  }
}
