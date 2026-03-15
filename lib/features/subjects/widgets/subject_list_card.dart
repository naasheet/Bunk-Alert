import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/core/utils/risk_calculator.dart';
import 'package:bunk_alert/domain/entities/attendance_stats_entity.dart';

class SubjectListCard extends StatelessWidget {
  const SubjectListCard({
    super.key,
    required this.stats,
    this.onTap,
    this.onEdit,
    this.onViewDetails,
    this.onArchive,
  });

  final AttendanceStatsEntity stats;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onViewDetails;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final percent = stats.currentPercentage.clamp(0, 100).toDouble();
    final resolvedOnTap = onTap ?? onViewDetails;

    return InkWell(
      onTap: resolvedOnTap,
      onLongPress: () => _showActions(context),
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.subjectName,
                      style: AppTextStyles.headingSmall(palette),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SubjectStatusBadge(level: stats.riskLevel),
                    const SizedBox(height: AppSpacing.sm),
                    BunkStatChip(stats: stats),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: AttendanceRing(
                percentage: percent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showActions(BuildContext context) async {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ActionTile(
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onEdit?.call();
                },
              ),
              _ActionTile(
                icon: Icons.visibility_outlined,
                label: 'View Details',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onViewDetails?.call();
                },
              ),
              _ActionTile(
                icon: Icons.archive_outlined,
                label: 'Archive',
                isDestructive: true,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onArchive?.call();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class SubjectStatusBadge extends StatelessWidget {
  const SubjectStatusBadge({super.key, required this.level});

  final RiskLevel level;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final label = _labelFor(level);
    final color = _colorFor(level, palette);
    final background = _backgroundFor(level, palette);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium(palette).copyWith(color: color),
      ),
    );
  }

  String _labelFor(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return 'Safe';
      case RiskLevel.warning:
        return 'On track';
      case RiskLevel.danger:
        return 'At risk';
      case RiskLevel.critical:
        return 'Critical';
      case RiskLevel.noData:
        return 'No data';
    }
  }

  Color _colorFor(RiskLevel level, AppColorPalette palette) {
    switch (level) {
      case RiskLevel.safe:
        return palette.safe;
      case RiskLevel.warning:
        return palette.warning;
      case RiskLevel.danger:
        return palette.danger;
      case RiskLevel.critical:
        return palette.critical;
      case RiskLevel.noData:
        return palette.textSecondary;
    }
  }

  Color _backgroundFor(RiskLevel level, AppColorPalette palette) {
    switch (level) {
      case RiskLevel.safe:
        return palette.safeSubtle;
      case RiskLevel.warning:
        return palette.warningSubtle;
      case RiskLevel.danger:
        return palette.dangerSubtle;
      case RiskLevel.critical:
        return palette.criticalSubtle;
      case RiskLevel.noData:
        return palette.surface;
    }
  }
}

class BunkStatChip extends StatelessWidget {
  const BunkStatChip({super.key, required this.stats});

  final AttendanceStatsEntity stats;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final needed = stats.classesNeededToReachTarget;
    final safeSkips = stats.classesSafeToSkip;

    String label;
    Color color;
    Color background;

    if (stats.conducted == 0) {
      label = 'Add classes';
      color = palette.textSecondary;
      background = palette.surface;
    } else if (needed > 0) {
      label = 'Attend $needed more';
      color = palette.warning;
      background = palette.warningSubtle;
    } else {
      final skips = safeSkips < 0 ? 0 : safeSkips;
      label = 'Skip $skips';
      color = palette.safe;
      background = palette.safeSubtle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium(palette).copyWith(color: color),
      ),
    );
  }
}

class AttendanceRing extends StatelessWidget {
  const AttendanceRing({
    super.key,
    required this.percentage,
  });

  final double percentage;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final percent = percentage.clamp(0, 100).toDouble();

    Widget buildRing(double progress) {
      return SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              backgroundColor: palette.border,
              valueColor:
                  AlwaysStoppedAnimation<Color>(palette.chartLine),
            ),
            Text(
              '${percent.round()}%',
              style: AppTextStyles.labelMedium(palette).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Animate(
      effects: [
        CustomEffect(
          duration: 1000.ms,
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return buildRing((percent / 100) * value);
          },
        ),
      ],
      child: buildRing(percent / 100),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final color = isDestructive ? palette.danger : palette.textPrimary;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: AppTextStyles.bodyLarge(palette)
            .copyWith(color: color, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }
}
