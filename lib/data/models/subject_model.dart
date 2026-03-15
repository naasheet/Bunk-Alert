import 'package:isar/isar.dart';

part 'subject_model.g.dart';

@collection
class SubjectModel {
  SubjectModel({
    required this.uuid,
    required this.name,
    required this.colorTagIndex,
    this.targetPercentage,
    this.expectedTotalClasses,
    this.isArchived = false,
    this.syncStatus = 'pending',
    required this.createdAt,
    required this.updatedAt,
  });

  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String uuid;

  final String name;
  final double? targetPercentage;
  final int? expectedTotalClasses;
  final int colorTagIndex;
  final bool isArchived;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubjectModel copyWith({
    String? uuid,
    String? name,
    double? targetPercentage,
    int? expectedTotalClasses,
    int? colorTagIndex,
    bool? isArchived,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubjectModel(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      targetPercentage: targetPercentage ?? this.targetPercentage,
      expectedTotalClasses:
          expectedTotalClasses ?? this.expectedTotalClasses,
      colorTagIndex: colorTagIndex ?? this.colorTagIndex,
      isArchived: isArchived ?? this.isArchived,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    )..id = id;
  }
}
