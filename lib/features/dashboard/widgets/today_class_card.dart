import 'package:flutter/material.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/features/dashboard/widgets/attendance_action_row.dart';

class TodayClass {
  const TodayClass({
    required this.subjectUuid,
    required this.timetableEntryUuid,
    required this.subjectName,
    required this.startMinutes,
    required this.endMinutes,
    required this.needsAttention,
    required this.selectedStatus,
    required this.attended,
    required this.conducted,
    required this.targetPercentage,
  });

  final String subjectUuid;
  final String timetableEntryUuid;
  final String subjectName;
  final int startMinutes;
  final int endMinutes;
  final bool needsAttention;
  final String? selectedStatus;
  final int attended;
  final int conducted;
  final double targetPercentage;
}

class TodayClassCard extends StatelessWidget {
  const TodayClassCard({
    super.key,
    required this.classItem,
    this.onMarked,
  });

  final TodayClass classItem;
  final VoidCallback? onMarked;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final timeLabel =
        _formatRange(context, classItem.startMinutes, classItem.endMinutes);
    final percent = classItem.conducted == 0
        ? 0
        : (classItem.attended / classItem.conducted) * 100;
    final percentLabel = '${percent.round()}%';
    final subtitle = '$timeLabel · $percentLabel';
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: palette.textPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          classItem.subjectName,
                          style: AppTextStyles.bodyLarge(palette)
                              .copyWith(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (classItem.needsAttention) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: palette.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall(palette)
                      .copyWith(color: palette.textSecondary),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              height: 0.5,
              color: palette.border,
            ),
            const SizedBox(height: AppSpacing.sm),
            AttendanceActionRow(
              subjectUuid: classItem.subjectUuid,
              timetableEntryUuid: classItem.timetableEntryUuid,
              initialStatus: classItem.selectedStatus,
              onMarked: onMarked,
            ),
          ],
        ),
      ),
    );
  }

  String _formatRange(BuildContext context, int startMinutes, int endMinutes) {
    final startTime = TimeOfDay(
      hour: startMinutes ~/ 60,
      minute: startMinutes % 60,
    );
    final endTime = TimeOfDay(
      hour: endMinutes ~/ 60,
      minute: endMinutes % 60,
    );
    final formattedStart =
        MaterialLocalizations.of(context).formatTimeOfDay(startTime);
    final formattedEnd =
        MaterialLocalizations.of(context).formatTimeOfDay(endTime);

    final startParts = formattedStart.split(' ');
    final endParts = formattedEnd.split(' ');
    if (startParts.length > 1 &&
        endParts.length > 1 &&
        startParts.last == endParts.last) {
      final trimmedStart =
          formattedStart.replaceFirst(' ${startParts.last}', '');
      return '$trimmedStart \u2013 $formattedEnd';
    }
    return '$formattedStart \u2013 $formattedEnd';
  }
}

