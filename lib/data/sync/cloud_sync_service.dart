import 'dart:async';

import 'package:bunk_alert/data/repositories/attendance_repository.dart';
import 'package:bunk_alert/data/repositories/subject_repository.dart';
import 'package:bunk_alert/data/repositories/timetable_repository.dart';

class CloudSyncService {
  CloudSyncService({
    AttendanceRepository? attendanceRepository,
    SubjectRepository? subjectRepository,
    TimetableRepository? timetableRepository,
  })  : _attendanceRepository =
            attendanceRepository ?? AttendanceRepository(),
        _subjectRepository = subjectRepository ?? SubjectRepository(),
        _timetableRepository = timetableRepository ?? TimetableRepository();

  static final CloudSyncService instance = CloudSyncService();

  final AttendanceRepository _attendanceRepository;
  final SubjectRepository _subjectRepository;
  final TimetableRepository _timetableRepository;

  Future<void> syncAll({
    required String userId,
    bool forceFullSync = false,
  }) async {
    await _attendanceRepository.syncPendingRecords(userId: userId);
    if (forceFullSync) {
      await _subjectRepository.syncAllToCloud(userId: userId);
      await _timetableRepository.syncAllToCloud(userId: userId);
    } else {
      await _subjectRepository.syncPendingToCloud(userId: userId);
      await _timetableRepository.syncPendingToCloud(userId: userId);
    }
    await _attendanceRepository.pullFromCloud(userId: userId);
    await _subjectRepository.pullFromCloud(userId: userId);
    await _timetableRepository.pullFromCloud(userId: userId);
  }

  void syncAllInBackground({
    required String userId,
    bool forceFullSync = false,
  }) {
    unawaited(syncAll(userId: userId, forceFullSync: forceFullSync));
  }
}
