import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:bunk_alert/core/router/route_names.dart';
import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/data/models/group_member_summary.dart';
import 'package:bunk_alert/data/models/study_group_model.dart';
import 'package:bunk_alert/data/repositories/study_group_repository.dart';
import 'package:bunk_alert/shared/utils/error_message_mapper.dart';
import 'package:bunk_alert/shared/widgets/app_bar_widget.dart';
import 'package:bunk_alert/shared/widgets/app_scaffold.dart';
import 'package:bunk_alert/shared/widgets/app_text_field.dart';
import 'package:bunk_alert/shared/widgets/primary_button.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final StudyGroupRepository _repository = StudyGroupRepository.instance;
  final TextEditingController _joinController = TextEditingController();
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _joinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;

    return AppScaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
          children: [
            Text(
              'Study Groups',
              style: AppTextStyles.headingMedium(palette).copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Compare attendance with classmates.',
              style: AppTextStyles.caption(
                palette,
              ).copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: 24),
            Text(
              'YOUR GROUPS',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.8,
                color: palette.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<StudyGroupModel>>(
              stream: _repository.watchGroupsForCurrentUser(),
              builder: (context, snapshot) {
                final groups = snapshot.data ?? const [];
                if (snapshot.connectionState == ConnectionState.waiting &&
                    groups.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (groups.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No groups yet. Create one to get started.',
                      style: AppTextStyles.bodySmall(
                        palette,
                      ).copyWith(color: palette.textSecondary),
                    ),
                  );
                }
                return ListView.separated(
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return _GroupCard(
                      group: group,
                      repository: _repository,
                      onTap: () =>
                          context.go('${RouteNames.social}/${group.id}'),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemCount: groups.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Create Group',
              style: AppTextStyles.headingMedium(palette).copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a new study group and invite friends to compare attendance.',
              style: AppTextStyles.bodySmall(palette).copyWith(
                color: palette.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _CreateGroupCard(onTap: () => _showCreateGroupSheet(context)),
            const SizedBox(height: 24),
            Text(
              'Join Group',
              style: AppTextStyles.headingMedium(palette).copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter an invite code shared by a friend.',
              style: AppTextStyles.bodySmall(palette).copyWith(
                color: palette.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _JoinGroupField(
              controller: _joinController,
              isLoading: _isJoining,
              onSubmit: _submitJoin,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateGroupSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _GroupSheet(
          title: 'Create a group',
          hintText: 'Group name',
          buttonLabel: 'Create',
          onSubmit: (value) async {
            final group = await _repository.createGroup(name: value);
            if (!mounted) {
              return;
            }
            Navigator.of(sheetContext).pop();
            await _showInviteCodeDialog(group);
          },
        );
      },
    );
  }

  Future<void> _submitJoin() async {
    final code = _joinController.text.trim();
    if (code.isEmpty) {
      _showSnack('Enter an invite code to continue.');
      return;
    }
    setState(() {
      _isJoining = true;
    });
    try {
      final group = await _repository.joinGroup(inviteCode: code);
      if (!mounted) {
        return;
      }
      _joinController.clear();
      context.go('${RouteNames.social}/${group.id}');
    } on StudyGroupFailure catch (error) {
      _showSnack(error.message);
    } on FirebaseException catch (error) {
      _showSnack(friendlyErrorMessage(error));
    } catch (_) {
      _showSnack('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  Future<void> _showInviteCodeDialog(StudyGroupModel group) async {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Invite code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share this code with friends to join your group.',
                style: AppTextStyles.bodySmall(palette),
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
                child: SelectableText(
                  group.inviteCode,
                  style: AppTextStyles.headingSmall(palette),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: group.inviteCode));
                Navigator.of(dialogContext).pop();
                _showSnack('Invite code copied to clipboard.');
              },
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.go('${RouteNames.social}/${group.id}');
              },
              child: const Text('Open group'),
            ),
          ],
        );
      },
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.repository,
    required this.onTap,
  });

  final StudyGroupModel group;
  final StudyGroupRepository repository;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.border, width: 0.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.name,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: palette.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${group.memberCount} members',
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(height: 0.5, color: palette.border),
                  const SizedBox(height: 12),
                  _TopMembersRow(
                    repository: repository,
                    groupId: group.id,
                    memberIds: group.members,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopMembersRow extends StatelessWidget {
  const _TopMembersRow({
    required this.repository,
    required this.groupId,
    required this.memberIds,
  });

  final StudyGroupRepository repository;
  final String groupId;
  final List<String> memberIds;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    return StreamBuilder<List<GroupMemberSummary>>(
      stream: repository.watchTopMembers(groupId),
      builder: (context, snapshot) {
        final members = snapshot.data ?? const <GroupMemberSummary>[];
        final allowed = memberIds.toSet();
        final visibleMembers = members
            .where((member) => allowed.contains(member.userId))
            .toList();
        return Row(
          children: [
            _AvatarChip(
              label: visibleMembers.isEmpty
                  ? '?'
                  : _initials(visibleMembers.first.displayName),
              backgroundColor: palette.safeSubtle,
              textColor: palette.safe,
            ),
            const SizedBox(width: 8),
            Text(
              'Top members',
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
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
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    final initials = (first + last).toUpperCase();
    return initials.isEmpty ? '?' : initials;
  }
}

class _OverlappingAvatars extends StatelessWidget {
  const _OverlappingAvatars({required this.avatars, required this.borderColor});

  final List<_AvatarChip> avatars;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final itemCount = avatars.length;
    return SizedBox(
      height: 26,
      width: itemCount == 0 ? 0 : (26 + (itemCount - 1) * 18),
      child: Stack(
        children: [
          for (var i = 0; i < itemCount; i++)
            Positioned(
              left: i * 18,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: borderColor,
                  shape: BoxShape.circle,
                ),
                child: avatars[i],
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarChip extends StatelessWidget {
  const _AvatarChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 13,
      backgroundColor: backgroundColor,
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _CreateGroupCard extends StatelessWidget {
  const _CreateGroupCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.border, width: 0.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Create Group',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: palette.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.add,
                color: palette.textSecondary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinGroupField extends StatelessWidget {
  const _JoinGroupField({
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.done,
              style: TextStyle(color: palette.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Invite code',
                hintStyle:
                    TextStyle(color: palette.textSecondary, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          Container(width: 0.5, height: 28, color: palette.border),
          InkWell(
            onTap: isLoading ? null : onSubmit,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(palette.safe),
                      ),
                    )
                  : Text(
                      'Join',
                      style: TextStyle(
                        color: palette.safe,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupSheet extends StatefulWidget {
  const _GroupSheet({
    required this.title,
    required this.hintText,
    required this.buttonLabel,
    required this.onSubmit,
  });

  final String title;
  final String hintText;
  final String buttonLabel;
  final Future<void> Function(String value) onSubmit;

  @override
  State<_GroupSheet> createState() => _GroupSheetState();
}

class _GroupSheetState extends State<_GroupSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
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
              Text(widget.title, style: AppTextStyles.headingSmall(palette)),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _controller,
                label: widget.hintText,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: widget.buttonLabel,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      _showError('Enter a value to continue.');
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      await widget.onSubmit(value);
    } on StudyGroupFailure catch (error) {
      _showError(error.message);
    } on FirebaseException catch (error) {
      _showError(friendlyErrorMessage(error));
    } catch (_) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
