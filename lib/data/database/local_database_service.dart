import 'dart:async';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bunk_alert/data/models/attendance_record_model.dart';
import 'package:bunk_alert/data/models/subject_model.dart';
import 'package:bunk_alert/data/models/timetable_entry_model.dart';

class LocalDatabaseService {
  LocalDatabaseService._();

  static final LocalDatabaseService instance = LocalDatabaseService._();

  Isar? _isar;
  String? _activeUserId;
  StreamSubscription<String?>? _userSubscription;
  Future<void> _switchFuture = Future.value();

  Future<void> initialize() async {
    await initializeForUser(_activeUserId);
  }

  Future<void> initializeForUser(String? userId) {
    _switchFuture = _switchFuture.then((_) async {
      if (userId == null || userId.isEmpty) {
        await close();
        _activeUserId = null;
        return;
      }

      if (_activeUserId == userId && _isar != null) {
        return;
      }

      await close();
      _activeUserId = userId;

      final directory = await getApplicationDocumentsDirectory();
      final name = _databaseNameForUser(userId);
      try {
        _isar = await Isar.open(
          [
            SubjectModelSchema,
            TimetableEntryModelSchema,
            AttendanceRecordModelSchema,
          ],
          directory: directory.path,
          name: name,
        );
      } catch (_) {
        await _deleteIsarFiles(directory.path, name);
        _isar = await Isar.open(
          [
            SubjectModelSchema,
            TimetableEntryModelSchema,
            AttendanceRecordModelSchema,
          ],
          directory: directory.path,
          name: name,
        );
      }

      await _migrateLegacyIfNeeded(
        userId: userId,
        directoryPath: directory.path,
      );
    });
    return _switchFuture;
  }

  Future<void> bindToUserIdStream(Stream<String?> userIdStream) async {
    await _userSubscription?.cancel();
    _userSubscription = userIdStream.distinct().listen(
      (userId) async {
        await initializeForUser(userId);
      },
    );
  }

  Isar get isar {
    final isar = _isar;
    if (isar == null) {
      throw StateError('Local database has not been initialized.');
    }
    return isar;
  }

  IsarCollection<SubjectModel> get subjects => isar.subjectModels;

  IsarCollection<TimetableEntryModel> get timetableEntries =>
      isar.timetableEntryModels;

  IsarCollection<AttendanceRecordModel> get attendanceRecords =>
      isar.attendanceRecordModels;

  Future<void> close() async {
    await _isar?.close();
    _isar = null;
    _activeUserId = null;
  }

  String _databaseNameForUser(String userId) {
    final sanitized = userId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    return 'bunk_alert_$sanitized';
  }

  Future<void> _deleteIsarFiles(String directoryPath, String name) async {
    final separator = Platform.pathSeparator;
    final dataFile = File('$directoryPath$separator$name.isar');
    final lockFile = File('$directoryPath$separator$name.isar.lock');
    if (await dataFile.exists()) {
      await dataFile.delete();
    }
    if (await lockFile.exists()) {
      await lockFile.delete();
    }
  }

  Future<void> _migrateLegacyIfNeeded({
    required String userId,
    required String directoryPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'legacy_migrated_$userId';
    final legacyOwnerKey = 'legacy_owner_user_id';
    if (prefs.getBool(key) == true) {
      return;
    }
    final legacyOwner = prefs.getString(legacyOwnerKey);
    if (legacyOwner != null && legacyOwner != userId) {
      await prefs.setBool(key, true);
      return;
    }

    final separator = Platform.pathSeparator;
    final legacyFile = File('$directoryPath$separator${_legacyName}.isar');
    if (!await legacyFile.exists()) {
      await prefs.setBool(key, true);
      return;
    }
    if (legacyOwner == null) {
      await prefs.setString(legacyOwnerKey, userId);
    }

    final target = _isar;
    if (target == null) {
      return;
    }

    final hasTargetData = await _hasAnyData(target);
    if (hasTargetData) {
      await prefs.setBool(key, true);
      return;
    }

    Isar? legacy;
    try {
      legacy = await Isar.open(
        [
          SubjectModelSchema,
          TimetableEntryModelSchema,
          AttendanceRecordModelSchema,
        ],
        directory: directoryPath,
        name: _legacyName,
      );

      final subjects = await legacy.subjectModels.where().findAll();
      final timetable = await legacy.timetableEntryModels.where().findAll();
      final records = await legacy.attendanceRecordModels.where().findAll();

      if (subjects.isEmpty && timetable.isEmpty && records.isEmpty) {
        await prefs.setBool(key, true);
        return;
      }

      for (final subject in subjects) {
        subject.id = Isar.autoIncrement;
      }
      for (final entry in timetable) {
        entry.id = Isar.autoIncrement;
      }
      for (final record in records) {
        record.id = Isar.autoIncrement;
      }

      await target.writeTxn(() async {
        if (subjects.isNotEmpty) {
          await target.subjectModels.putAll(subjects);
        }
        if (timetable.isNotEmpty) {
          await target.timetableEntryModels.putAll(timetable);
        }
        if (records.isNotEmpty) {
          await target.attendanceRecordModels.putAll(records);
        }
      });
      await prefs.setString(legacyOwnerKey, userId);
    } catch (_) {
      // Ignore migration failures; user can continue with a fresh db.
    } finally {
      await legacy?.close();
      await prefs.setBool(key, true);
    }
  }

  Future<bool> _hasAnyData(Isar isar) async {
    final subjectCount = await isar.subjectModels.where().count();
    if (subjectCount > 0) {
      return true;
    }
    final timetableCount =
        await isar.timetableEntryModels.where().count();
    if (timetableCount > 0) {
      return true;
    }
    final recordCount =
        await isar.attendanceRecordModels.where().count();
    return recordCount > 0;
  }
}

const String _legacyName = 'default';
