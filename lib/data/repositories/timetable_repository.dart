import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isar/isar.dart';

import 'package:bunk_alert/data/database/local_database_service.dart';
import 'package:bunk_alert/data/firebase/firestore_service.dart';
import 'package:bunk_alert/data/models/timetable_entry_model.dart';
import 'package:bunk_alert/data/notifications/notification_scheduler_service.dart';
import 'package:bunk_alert/shared/auth/app_auth.dart';

class TimetableRepository {
  TimetableRepository({
    LocalDatabaseService? localDatabaseService,
    FirestoreService? firestoreService,
  })  : _localDatabaseService =
            localDatabaseService ?? LocalDatabaseService.instance,
        _firestoreService = firestoreService ?? FirestoreService();

  final LocalDatabaseService _localDatabaseService;
  final FirestoreService _firestoreService;

  Future<List<TimetableEntryModel>> getByDayOfWeek(int dayOfWeek) async {
    return _localDatabaseService.timetableEntries
        .filter()
        .dayOfWeekEqualTo(dayOfWeek)
        .isActiveEqualTo(true)
        .sortByStartMinutes()
        .findAll();
  }

  Future<int> getActiveEntryCount() async {
    return _localDatabaseService.timetableEntries
        .filter()
        .isActiveEqualTo(true)
        .count();
  }

  Future<List<TimetableEntryModel>> getAllActiveEntries() async {
    return _localDatabaseService.timetableEntries
        .filter()
        .isActiveEqualTo(true)
        .findAll();
  }

  Future<List<TimetableEntryModel>> getAllEntries() async {
    return _localDatabaseService.timetableEntries.where().findAll();
  }

  Future<void> addEntries(List<TimetableEntryModel> entries) async {
    if (entries.isEmpty) {
      return;
    }
    final isar = _localDatabaseService.isar;
    await isar.writeTxn(() async {
      await isar.timetableEntryModels.putAll(entries);
    });
    if (!AppAuthOverrides.isTest) {
      unawaited(
        Future.wait(
          entries.map(
            NotificationSchedulerService.instance.scheduleClassReminder,
          ),
        ),
      );
      _queueSync();
    }
  }

  Future<void> deactivateEntry(TimetableEntryModel entry) async {
    final isar = _localDatabaseService.isar;
    final updated = entry.copyWith(
      isActive: false,
      syncStatus: 'pending',
    );
    await isar.writeTxn(() async {
      await isar.timetableEntryModels.put(updated);
    });
    if (!AppAuthOverrides.isTest) {
      unawaited(
        NotificationSchedulerService.instance.cancelClassReminder(entry.uuid),
      );
      _queueSync();
    }
  }

  Future<List<TimetableEntryModel>> getPendingEntries() async {
    return _localDatabaseService.timetableEntries
        .filter()
        .syncStatusEqualTo('pending')
        .findAll();
  }

  Future<void> syncPendingToCloud({
    required String userId,
  }) async {
    final pending = await getPendingEntries();
    if (pending.isEmpty) {
      return;
    }
    for (final entry in pending) {
      await _firestoreService.upsertTimetableEntry(
        userId: userId,
        entryId: entry.uuid,
        subjectId: entry.subjectUuid,
        dayOfWeek: entry.dayOfWeek,
        startMinutes: entry.startMinutes,
        endMinutes: entry.endMinutes,
        isActive: entry.isActive,
        createdAt: entry.createdAt,
        updatedAt: DateTime.now(),
      );
    }

    final isar = _localDatabaseService.isar;
    await isar.writeTxn(() async {
      for (final entry in pending) {
        final updated = entry.copyWith(syncStatus: 'synced');
        await isar.timetableEntryModels.put(updated);
      }
    });
  }

  Future<void> syncAllToCloud({
    required String userId,
  }) async {
    final entries = await getAllEntries();
    if (entries.isEmpty) {
      return;
    }
    for (final entry in entries) {
      await _firestoreService.upsertTimetableEntry(
        userId: userId,
        entryId: entry.uuid,
        subjectId: entry.subjectUuid,
        dayOfWeek: entry.dayOfWeek,
        startMinutes: entry.startMinutes,
        endMinutes: entry.endMinutes,
        isActive: entry.isActive,
        createdAt: entry.createdAt,
        updatedAt: DateTime.now(),
      );
    }

    final isar = _localDatabaseService.isar;
    await isar.writeTxn(() async {
      for (final entry in entries) {
        final updated = entry.copyWith(syncStatus: 'synced');
        await isar.timetableEntryModels.put(updated);
      }
    });
  }

  Future<void> pullFromCloud({
    required String userId,
  }) async {
    final snapshot = await _firestoreService.getUserTimetableEntries(userId);
    if (snapshot.docs.isEmpty) {
      return;
    }
    final entries = snapshot.docs.map(_entryFromDoc).toList();
    final isar = _localDatabaseService.isar;
    await isar.writeTxn(() async {
      await isar.timetableEntryModels.putAll(entries);
    });
  }

  TimetableEntryModel _entryFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final createdAt = _timestampToDateTime(data['createdAt']);
    return TimetableEntryModel(
      uuid: doc.id,
      subjectUuid: (data['subjectId'] as String?) ?? '',
      dayOfWeek: (data['dayOfWeek'] as num?)?.toInt() ?? DateTime.monday,
      startMinutes: (data['startMinutes'] as num?)?.toInt() ?? 0,
      endMinutes: (data['endMinutes'] as num?)?.toInt() ?? 0,
      isActive: (data['isActive'] as bool?) ?? true,
      syncStatus: 'synced',
      createdAt: createdAt,
    );
  }

  DateTime _timestampToDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.now();
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
