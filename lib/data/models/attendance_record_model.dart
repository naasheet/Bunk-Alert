import 'package:isar/isar.dart';

part 'attendance_record_model.g.dart';

@collection
class AttendanceRecordModel {
  AttendanceRecordModel({
    required this.uuid,
    required this.subjectUuid,
    this.timetableEntryUuid,
    required this.date,
    required this.status,
    this.note,
    this.syncStatus = 'pending',
    required this.createdAt,
    required this.updatedAt,
  });

  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String uuid;

  @Index()
  final String subjectUuid;

  @Index()
  final String? timetableEntryUuid;

  @Index()
  final DateTime date;

  final String status;
  final String? note;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceRecordModel copyWith({
    String? uuid,
    String? subjectUuid,
    String? timetableEntryUuid,
    DateTime? date,
    String? status,
    String? note,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceRecordModel(
      uuid: uuid ?? this.uuid,
      subjectUuid: subjectUuid ?? this.subjectUuid,
      timetableEntryUuid: timetableEntryUuid ?? this.timetableEntryUuid,
      date: date ?? this.date,
      status: status ?? this.status,
      note: note ?? this.note,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    )..id = id;
  }

  static DateTime normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
