import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bunk_alert/core/router/route_names.dart';
import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/domain/entities/attendance_stats_entity.dart';

class RecoveryPlanCard extends StatelessWidget {
  const RecoveryPlanCard({
    super.key,
    required this.stats,
  });

  final AttendanceStatsEntity stats;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final target = stats.targetPercentage.round();
    final needed = stats.recoveryPlan.classesNeeded;
    final message = needed == -1
        ? 'Attend every remaining class to reach $target%.'
        : 'Attend $needed more classes to reach $target%.';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: () => context.go('${RouteNames.subjects}/${stats.subjectUuid}'),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: palette.warningSubtle,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: palette.warning),
          ),
          child: Row(
            children: [
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
                      message,
                      style: AppTextStyles.bodyMedium(palette),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: palette.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
