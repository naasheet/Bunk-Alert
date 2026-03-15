import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMemberSummary {
  const GroupMemberSummary({
    required this.userId,
    required this.displayName,
    required this.overallPercentage,
    this.updatedAt,
  });

  final String userId;
  final String displayName;
  final double overallPercentage;
  final DateTime? updatedAt;

  factory GroupMemberSummary.fromMap({
    required String userId,
    required Map<String, dynamic> data,
  }) {
    final percentageValue = data['overallPercentage'];
    final updatedAt = data['updatedAt'];
    return GroupMemberSummary(
      userId: userId,
      displayName: (data['displayName'] as String?)?.trim().isNotEmpty == true
          ? data['displayName'] as String
          : 'Student',
      overallPercentage: percentageValue is num ? percentageValue.toDouble() : 0,
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
    );
  }
}
