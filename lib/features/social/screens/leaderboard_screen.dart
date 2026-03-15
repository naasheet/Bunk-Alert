import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:bunk_alert/core/router/route_names.dart';
import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/data/models/group_member_summary.dart';
import 'package:bunk_alert/data/models/group_member_subject_summary.dart';
import 'package:bunk_alert/data/models/study_group_model.dart';
import 'package:bunk_alert/data/repositories/study_group_repository.dart';
import 'package:bunk_alert/shared/auth/app_auth.dart';
import 'package:bunk_alert/shared/widgets/app_bar_widget.dart';
import 'package:bunk_alert/shared/widgets/app_scaffold.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
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
        final isOwner =
            group != null && group.createdBy == AppAuth.currentUser?.uid;
        return AppScaffold(
          appBar: AppBarWidget(
            title: group?.name ?? 'Leaderboard',
            actions: group != null
                ? [
                    IconButton(
                      icon: const Icon(Icons.key_outlined),
                      tooltip: 'Invite code',
                      onPressed: () => _showInviteCode(group),
                    ),
                    if (isOwner)
                      PopupMenuButton<_OwnerAction>(
                        onSelected: (action) =>
                            _handleOwnerAction(action, group),
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: _OwnerAction.edit,
                            child: Text('Edit group'),
                          ),
                          PopupMenuItem(
                            value: _OwnerAction.members,
                            child: Text('Manage members'),
                          ),
                          PopupMenuItem(
                            value: _OwnerAction.delete,
                            child: Text('Delete group'),
                          ),
                        ],
                      ),
                  ]
                : null,
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
                          final currentUserId = AppAuth.currentUser?.uid;
                          return ListView.separated(
                            itemBuilder: (context, index) {
                              final member = visibleMembers[index];
                              return InkWell(
                                onTap: () =>
                                    _showMemberSubjects(group, member),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.cardRadius,
                                ),
                                child: LeaderboardEntryTile(
                                  rank: index + 1,
                                  member: member,
                                  isCurrentUser:
                                      member.userId == currentUserId,
                                ),
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

  Future<void> _handleOwnerAction(
    _OwnerAction action,
    StudyGroupModel group,
  ) async {
    switch (action) {
      case _OwnerAction.edit:
        await _showEditGroupDialog(group);
      case _OwnerAction.members:
        await _showManageMembersSheet(group);
      case _OwnerAction.delete:
        await _confirmDelete(group);
    }
  }

  Future<void> _showEditGroupDialog(StudyGroupModel group) async {
    var updatedName = group.name;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit group'),
          content: TextFormField(
            initialValue: updatedName,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Group name'),
            onChanged: (value) {
              updatedName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(updatedName),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (!mounted || result == null) {
      return;
    }
    try {
      await _repository.renameGroup(group: group, name: result);
      _showSnack('Group name updated.');
    } on StudyGroupFailure catch (error) {
      _showSnack(error.message);
    } catch (_) {
      _showSnack('Unable to update group.');
    }
  }

  Future<void> _showManageMembersSheet(StudyGroupModel group) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final palette = Theme.of(context).brightness == Brightness.dark
            ? AppColors.dark
            : AppColors.light;
        final height =
            MediaQuery.of(sheetContext).size.height * 0.75;
        return SizedBox(
          height: height,
          child: StreamBuilder<StudyGroupModel?>(
            stream: _repository.watchGroup(group.id),
            builder: (context, groupSnapshot) {
              final latestGroup = groupSnapshot.data ?? group;
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.base,
                  AppSpacing.base,
                  AppSpacing.base,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Members',
                            style: AppTextStyles.headingSmall(palette),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                    Text(
                      '${latestGroup.memberCount} members in this group.',
                      style: AppTextStyles.caption(palette)
                          .copyWith(color: palette.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: StreamBuilder<List<GroupMemberSummary>>(
                        stream: _repository.watchLeaderboard(group.id),
                        builder: (context, snapshot) {
                          final summaries = snapshot.data ?? const [];
                          final summaryMap = {
                            for (final member in summaries)
                              member.userId: member
                          };
                          final members = latestGroup.members;
                          if (members.isEmpty) {
                            return Center(
                              child: Text(
                                'No members yet.',
                                style: AppTextStyles.bodySmall(palette),
                              ),
                            );
                          }
                          final currentUserId = AppAuth.currentUser?.uid;
                          return ListView.separated(
                            itemBuilder: (context, index) {
                              final memberId = members[index];
                              final summary = summaryMap[memberId];
                              final displayName =
                                  summary?.displayName ?? memberId;
                              final isOwner =
                                  memberId == latestGroup.createdBy;
                              final isSelf = memberId == currentUserId;
                              final percent = summary?.overallPercentage;
                              return Container(
                                padding: const EdgeInsets.all(AppSpacing.base),
                                decoration: BoxDecoration(
                                  color: palette.surfaceElevated,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.cardRadius,
                                  ),
                                  border: Border.all(color: palette.border),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: palette.surface,
                                      child: Text(
                                        _initials(displayName),
                                        style:
                                            AppTextStyles.labelMedium(palette)
                                                .copyWith(
                                          color: palette.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayName,
                                            style:
                                                AppTextStyles.bodyLarge(palette),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isOwner
                                                ? 'Owner'
                                                : isSelf
                                                    ? 'You'
                                                    : memberId,
                                            style: AppTextStyles.caption(palette)
                                                .copyWith(
                                              color:
                                                  palette.textSecondary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (percent != null)
                                      Text(
                                        '${percent.toStringAsFixed(1)}%',
                                        style:
                                            AppTextStyles.labelLarge(palette),
                                      ),
                                    if (!isOwner && !isSelf)
                                      TextButton(
                                        onPressed: () async {
                                          final shouldKick =
                                              await _confirmKick(sheetContext);
                                          if (!shouldKick) {
                                            return;
                                          }
                                          try {
                                            await _repository.kickMember(
                                              group: latestGroup,
                                              memberId: memberId,
                                            );
                                          } on StudyGroupFailure catch (error) {
                                            _showSnack(error.message);
                                          } catch (_) {
                                            _showSnack(
                                                'Unable to remove member.');
                                          }
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: palette.danger,
                                        ),
                                        child: const Text('Remove'),
                                      ),
                                  ],
                                ),
                              );
                            },
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemCount: members.length,
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

  Future<void> _showInviteCode(StudyGroupModel group) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) {
        final palette = Theme.of(context).brightness == Brightness.dark
            ? AppColors.dark
            : AppColors.light;
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Invite code',
                style: AppTextStyles.headingSmall(palette),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Share this code to let others join the group.',
                style: AppTextStyles.bodySmall(palette)
                    .copyWith(color: palette.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
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
                child: Text(
                  group.inviteCode,
                  style: AppTextStyles.headingSmall(palette),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: group.inviteCode),
                        );
                        if (sheetContext.mounted) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(content: Text('Code copied.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        await Share.share(
                          'Join my group on Bunk Alert with code: ${group.inviteCode}',
                        );
                      },
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showMemberSubjects(
    StudyGroupModel group,
    GroupMemberSummary member,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final palette = Theme.of(context).brightness == Brightness.dark
            ? AppColors.dark
            : AppColors.light;
        final isSelf = member.userId == AppAuth.currentUser?.uid;
        final height = MediaQuery.of(sheetContext).size.height * 0.7;
        return SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.base,
              AppSpacing.base,
              AppSpacing.base,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.displayName,
                        style: AppTextStyles.headingSmall(palette),
                      ),
                    ),
                    Text(
                      '${member.overallPercentage.toStringAsFixed(1)}%',
                      style: AppTextStyles.labelLarge(palette),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Subject attendance',
                  style: AppTextStyles.caption(palette)
                      .copyWith(color: palette.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: isSelf
                      ? FutureBuilder<List<GroupMemberSubjectSummary>>(
                          future: _repository.getLocalSubjectSummaries(),
                          builder: (context, snapshot) {
                            final items = snapshot.data ?? const [];
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                items.isEmpty) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (items.isEmpty) {
                              return Center(
                                child: Text(
                                  'No subject summaries yet.',
                                  style: AppTextStyles.bodySmall(palette),
                                ),
                              );
                            }
                            return ListView.separated(
                              itemBuilder: (context, index) {
                                final summary = items[index];
                                return _MemberSubjectTile(summary: summary);
                              },
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemCount: items.length,
                            );
                          },
                        )
                      : StreamBuilder<List<GroupMemberSubjectSummary>>(
                          stream: _repository.watchMemberSubjectSummaries(
                            groupId: group.id,
                            userId: member.userId,
                          ),
                          builder: (context, snapshot) {
                            final items = snapshot.data ?? const [];
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                items.isEmpty) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (items.isEmpty) {
                              return Center(
                                child: Text(
                                  'No subject summaries yet.',
                                  style: AppTextStyles.bodySmall(palette),
                                ),
                              );
                            }
                            return ListView.separated(
                              itemBuilder: (context, index) {
                                final summary = items[index];
                                return _MemberSubjectTile(summary: summary);
                              },
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemCount: items.length,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) {
      return '?';
    }
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty
        ? parts.last[0]
        : '';
    final initials = (first + last).toUpperCase();
    return initials.isEmpty ? '?' : initials;
  }

  Future<bool> _confirmKick(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove member?'),
          content: const Text('They will lose access to this group.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _confirmDelete(StudyGroupModel group) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Delete group?'),
              content: const Text(
                'This will delete the group for everyone.',
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
    if (!shouldDelete) {
      return;
    }
    try {
      await _repository.deleteGroup(group: group);
      if (!mounted) {
        return;
      }
      context.go(RouteNames.social);
    } on StudyGroupFailure catch (error) {
      _showSnack(error.message);
    } catch (_) {
      _showSnack('Unable to delete group.');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

enum _OwnerAction { edit, members, delete }

class LeaderboardEntryTile extends StatelessWidget {
  const LeaderboardEntryTile({
    super.key,
    required this.rank,
    required this.member,
    required this.isCurrentUser,
  });

  final int rank;
  final GroupMemberSummary member;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final percent = member.overallPercentage.clamp(0, 100).toDouble();
    final backgroundColor =
        isCurrentUser ? palette.surfaceElevated : palette.surface;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Row(
              children: [
                _RankDot(rank: rank),
                const SizedBox(width: 6),
                Text(
                  rank.toString(),
                  style: AppTextStyles.headingSmall(palette).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.displayName,
                        style: AppTextStyles.bodyLarge(palette),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${percent.toStringAsFixed(1)}%',
                      style: AppTextStyles.labelLarge(palette),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Animate(
                    effects: [
                      CustomEffect(
                        duration: 1000.ms,
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return LinearProgressIndicator(
                            value: (percent / 100) * value,
                            minHeight: 6,
                            backgroundColor: palette.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              palette.chartLine,
                            ),
                          );
                        },
                      ),
                    ],
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      minHeight: 6,
                      backgroundColor: palette.border,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(palette.chartLine),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankDot extends StatelessWidget {
  const _RankDot({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final color = _rankColor(rank);
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD54F);
      case 2:
        return const Color(0xFFB0BEC5);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return Colors.transparent;
    }
  }
}

class _MemberSubjectTile extends StatelessWidget {
  const _MemberSubjectTile({required this.summary});

  final GroupMemberSubjectSummary summary;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final percent = summary.percentage.clamp(0, 100).toDouble();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.name,
                  style: AppTextStyles.bodyLarge(palette),
                ),
                const SizedBox(height: 2),
                Text(
                  '${summary.attended} attended / ${summary.conducted} conducted',
                  style: AppTextStyles.caption(palette)
                      .copyWith(color: palette.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '${percent.toStringAsFixed(1)}%',
            style: AppTextStyles.labelLarge(palette),
          ),
        ],
      ),
    );
  }
}
