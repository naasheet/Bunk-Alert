import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMemberSubjectSummary {
  const GroupMemberSubjectSummary({
    required this.subjectId,
    required this.name,
    required this.attended,
    required this.conducted,
    required this.percentage,
    required this.isArchived,
    this.updatedAt,
  });

  final String subjectId;
  final String name;
  final int attended;
  final int conducted;
  final double percentage;
  final bool isArchived;
  final DateTime? updatedAt;

  factory GroupMemberSubjectSummary.fromMap({
    required String subjectId,
    required Map<String, dynamic> data,
  }) {
    final updatedAt = data['updatedAt'];
    return GroupMemberSubjectSummary(
      subjectId: subjectId,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? data['name'] as String
          : 'Subject',
      attended: (data['attended'] as num?)?.toInt() ?? 0,
      conducted: (data['conducted'] as num?)?.toInt() ?? 0,
      percentage: (data['percentage'] as num?)?.toDouble() ?? 0,
      isArchived: data['isArchived'] as bool? ?? false,
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
    );
  }
}
