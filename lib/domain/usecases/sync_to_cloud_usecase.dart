import 'package:flutter/foundation.dart';

import 'package:bunk_alert/data/repositories/attendance_repository.dart';
import 'package:bunk_alert/shared/auth/app_auth.dart';

class SyncToCloudUsecase {
  SyncToCloudUsecase({required AttendanceRepository repository})
      : _repository = repository;

  final AttendanceRepository _repository;

  Future<int> call() async {
    try {
      if (AppAuthOverrides.isTest) {
        return 0;
      }
      final userId = AppAuth.currentUser?.uid;
      if (userId == null) {
        return 0;
      }
      return await _repository.syncPendingRecords(userId: userId);
    } catch (error, stackTrace) {
      debugPrint('Sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return 0;
    }
  }
}
