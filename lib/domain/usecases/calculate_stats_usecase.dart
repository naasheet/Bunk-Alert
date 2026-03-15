import 'package:bunk_alert/domain/entities/attendance_stats_entity.dart';
import 'package:bunk_alert/data/models/attendance_record_model.dart';
import 'package:bunk_alert/data/models/subject_model.dart';

class CalculateStatsUsecase {
  const CalculateStatsUsecase();

  AttendanceStatsEntity call({
    required SubjectModel subject,
    required List<AttendanceRecordModel> records,
    required double globalTargetPercentage,
    required int remainingClasses,
  }) {
    final subjectRecords = records
        .where((record) => record.subjectUuid == subject.uuid)
        .toList();

    var attended = 0;
    var conducted = 0;
    var cancelled = 0;

    for (final record in subjectRecords) {
      switch (record.status) {
        case 'present':
          attended++;
          conducted++;
        case 'absent':
          conducted++;
        case 'cancelled':
          cancelled++;
      }
    }

    return AttendanceStatsEntity(
      subjectUuid: subject.uuid,
      subjectName: subject.name,
      colorTagIndex: subject.colorTagIndex,
      conducted: conducted,
      attended: attended,
      cancelled: cancelled,
      targetPercentage: subject.targetPercentage ?? globalTargetPercentage,
      remainingClasses: remainingClasses,
    );
  }
}
