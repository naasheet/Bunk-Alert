import 'package:isar/isar.dart';

part 'timetable_entry_model.g.dart';

@collection
class TimetableEntryModel {
  TimetableEntryModel({
    required this.uuid,
    required this.subjectUuid,
    required this.dayOfWeek,
    required this.startMinutes,
    required this.endMinutes,
    this.isActive = true,
    this.syncStatus = 'pending',
    required this.createdAt,
  });

  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String uuid;

  @Index()
  final String subjectUuid;

  @Index()
  final int dayOfWeek;

  final int startMinutes;
  final int endMinutes;
  final bool isActive;
  final String syncStatus;
  final DateTime createdAt;

  TimetableEntryModel copyWith({
    String? uuid,
    String? subjectUuid,
    int? dayOfWeek,
    int? startMinutes,
    int? endMinutes,
    bool? isActive,
    String? syncStatus,
    DateTime? createdAt,
  }) {
    return TimetableEntryModel(
      uuid: uuid ?? this.uuid,
      subjectUuid: subjectUuid ?? this.subjectUuid,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      isActive: isActive ?? this.isActive,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
    )..id = id;
  }
}
