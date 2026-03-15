import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:bunk_alert/core/router/route_names.dart';
import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/data/models/group_member_summary.dart';
import 'package:bunk_alert/data/models/study_group_model.dart';
import 'package:bunk_alert/data/repositories/study_group_repository.dart';
import 'package:bunk_alert/shared/auth/app_auth.dart';
import 'package:bunk_alert/shared/utils/error_message_mapper.dart';
import 'package:bunk_alert/shared/widgets/app_bar_widget.dart';
import 'package:bunk_alert/shared/widgets/app_scaffold.dart';

class StudyGroupScreen extends StatefulWidget {
  const StudyGroupScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<StudyGroupScreen> createState() => _StudyGroupScreenState();
}

class _StudyGroupScreenState extends State<StudyGroupScreen> {
  final StudyGroupRepository _repository = StudyGroupRepository.instance;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;

    return StreamBuilder<StudyGroupModel?>(
      stream: _repository.watchGroup(widget.groupId),
      builder: (context, snapshot) {
        final group = snapshot.data;
        return AppScaffold(
          appBar: AppBarWidget(
            title: group?.name ?? 'Study Group',
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: group == null
                    ? null
                    : () => _shareInviteCode(group),
              ),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  group == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (group == null) {
                return Center(
                  child: Text(
                    'Group not found.',
                    style: AppTextStyles.bodySmall(palette),
                  ),
                );
              }
              return Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance is computed from each member\'s records.',
                      style: AppTextStyles.bodySmall(palette),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Invite code',
                      style: AppTextStyles.labelSmall(palette)
                          .copyWith(letterSpacing: 1.1),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _InviteCodeCard(
                      code: group.inviteCode,
                      onCopy: () => _copyCode(group.inviteCode),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton.icon(
                      onPressed: () => _confirmLeaveGroup(group),
                      style: TextButton.styleFrom(
                        foregroundColor: palette.danger,
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text('Leave group'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Leaderboard',
                      style: AppTextStyles.labelSmall(palette)
                          .copyWith(letterSpacing: 1.1),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: StreamBuilder<List<GroupMemberSummary>>(
                        stream: _repository.watchLeaderboard(group.id),
                        builder: (context, leaderboardSnapshot) {
                          final members =
                              leaderboardSnapshot.data ?? const [];
                          final memberIds = group.members.toSet();
                          final visibleMembers = members
                              .where(
                                (member) => memberIds.contains(member.userId),
                              )
                              .toList();
                          if (leaderboardSnapshot.connectionState ==
                                  ConnectionState.waiting &&
                              visibleMembers.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (visibleMembers.isEmpty) {
                            return Center(
                              child: Text(
                                'No attendance updates yet.',
                                style: AppTextStyles.bodySmall(palette),
                              ),
                            );
                          }
                          return ListView.separated(
                            itemBuilder: (context, index) {
                              final member = visibleMembers[index];
                              return _LeaderboardTile(
                                rank: index + 1,
                                member: member,
                              );
                            },
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemCount: visibleMembers.length,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite code copied.')),
    );
  }

  Future<void> _shareInviteCode(StudyGroupModel group) async {
    final message =
        'Join my study group on Bunk Alert. Invite code: ${group.inviteCode}';
    await Share.share(message);
  }

  Future<void> _confirmLeaveGroup(StudyGroupModel group) async {
    final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Leave group?'),
              content: const Text(
                'You will be removed from the leaderboard.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Leave'),
                ),
              ],
            );
          },
        ) ??
        false;
    if (!shouldLeave) {
      return;
    }
    try {
      await _repository.leaveGroup(groupId: group.id);
      if (!mounted) {
        return;
      }
      context.go(RouteNames.social);
    } on StudyGroupFailure catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(error))),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to leave the group.')),
      );
    }
  }
}

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({
    required this.code,
    required this.onCopy,
  });

  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      onTap: onCopy,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                code,
                style: AppTextStyles.headingMedium(palette),
              ),
            ),
            Icon(
              Icons.copy,
              size: 18,
              color: palette.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.rank,
    required this.member,
  });

  final int rank;
  final GroupMemberSummary member;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final userId = AppAuth.currentUser?.uid;
    final isCurrentUser = member.userId == userId;
    final name = isCurrentUser ? '${member.displayName} (You)' : member.displayName;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: isCurrentUser ? palette.chartLine : palette.border,
          width: isCurrentUser ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          _RankBadge(rank: rank),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.bodyLarge(palette),
            ),
          ),
          Text(
            '${member.overallPercentage.toStringAsFixed(1)}%',
            style: AppTextStyles.headingSmall(palette),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: palette.surface,
        shape: BoxShape.circle,
        border: Border.all(color: palette.border),
      ),
      alignment: Alignment.center,
      child: Text(
        rank.toString(),
        style: AppTextStyles.labelMedium(palette),
      ),
    );
  }
}
