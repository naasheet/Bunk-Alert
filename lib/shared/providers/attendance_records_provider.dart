import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import 'package:bunk_alert/data/database/local_database_service.dart';
import 'package:bunk_alert/data/models/attendance_record_model.dart';
import 'package:bunk_alert/shared/providers/auth_user_provider.dart';

final attendanceRecordsStreamProvider =
    StreamProvider<List<AttendanceRecordModel>>((ref) {
  final userId = ref.watch(authUserIdProvider).maybeWhen(
        data: (value) => value,
        orElse: () => null,
      );
  if (userId == null) {
    return Stream.value(const <AttendanceRecordModel>[]);
  }
  final isar = LocalDatabaseService.instance.isar;
  final query = isar.attendanceRecordModels.where();
  return query.watch(fireImmediately: true);
});
