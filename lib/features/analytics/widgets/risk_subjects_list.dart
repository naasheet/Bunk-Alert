import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bunk_alert/core/router/route_names.dart';
import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/core/utils/risk_calculator.dart';
import 'package:bunk_alert/domain/entities/attendance_stats_entity.dart';

class RiskSubjectsList extends StatelessWidget {
  const RiskSubjectsList({
    super.key,
    required this.stats,
  });

  final List<AttendanceStatsEntity> stats;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final atRisk = stats.where((entry) {
      return entry.riskLevel == RiskLevel.danger ||
          entry.riskLevel == RiskLevel.critical;
    }).toList()
      ..sort((a, b) => a.currentPercentage.compareTo(b.currentPercentage));

    if (atRisk.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Column(
        children: atRisk.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _RiskSubjectTile(
              stats: entry,
              palette: palette,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RiskSubjectTile extends StatelessWidget {
  const _RiskSubjectTile({
    required this.stats,
    required this.palette,
  });

  final AttendanceStatsEntity stats;
  final AppColorPalette palette;

  @override
  Widget build(BuildContext context) {
    final badgeColor = stats.riskLevel == RiskLevel.critical
        ? palette.danger
        : palette.warning;
    final badgeText = stats.riskLevel == RiskLevel.critical
        ? 'CRITICAL'
        : 'DANGER';
    final needed = stats.recoveryPlan.classesNeeded;
    final description = needed == -1
        ? 'Need perfect attendance to recover'
        : 'Need $needed more classes to recover';

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      onTap: () => context.go('${RouteNames.subjects}/${stats.subjectUuid}'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
              ),
              child: Text(
                badgeText,
                style: AppTextStyles.caption(palette)
                    .copyWith(color: badgeColor),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stats.subjectName,
                    style: AppTextStyles.labelLarge(palette),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: AppTextStyles.caption(palette)
                        .copyWith(color: palette.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${stats.currentPercentage.round()}%',
              style: AppTextStyles.headingSmall(palette),
            ),
          ],
        ),
      ),
    );
  }
}
