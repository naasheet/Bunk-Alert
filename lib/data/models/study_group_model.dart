import 'package:cloud_firestore/cloud_firestore.dart';

class StudyGroupModel {
  const StudyGroupModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdBy,
    required this.members,
    this.createdAt,
  });

  final String id;
  final String name;
  final String inviteCode;
  final String createdBy;
  final List<String> members;
  final DateTime? createdAt;

  int get memberCount => members.length;

  factory StudyGroupModel.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final members = (data['members'] as List<dynamic>?)
            ?.map((entry) => entry.toString())
            .toList() ??
        const <String>[];
    final createdAt = data['createdAt'];
    return StudyGroupModel(
      id: id,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? data['name'] as String
          : 'Study Group',
      inviteCode: (data['inviteCode'] as String?)?.trim().isNotEmpty == true
          ? data['inviteCode'] as String
          : id,
      createdBy: (data['createdBy'] as String?) ?? '',
      members: members,
      createdAt:
          createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}
