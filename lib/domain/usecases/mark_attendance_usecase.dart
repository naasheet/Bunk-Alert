import 'package:bunk_alert/data/models/attendance_record_model.dart';
import 'package:bunk_alert/data/repositories/attendance_repository.dart';

class MarkAttendanceUsecase {
  MarkAttendanceUsecase({AttendanceRepository? repository})
      : _repository = repository ?? AttendanceRepository();

  final AttendanceRepository _repository;

  Future<AttendanceRecordModel> call({
    required String subjectUuid,
    required String status,
    DateTime? date,
    String? timetableEntryUuid,
    String? note,
  }) {
    return _repository.markAttendance(
      subjectUuid: subjectUuid,
      status: status,
      date: date,
      timetableEntryUuid: timetableEntryUuid,
      note: note,
    );
  }
}
