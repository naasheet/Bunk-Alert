import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';

class EmptyTimetableState extends StatelessWidget {
  const EmptyTimetableState({super.key, required this.dayName});

  final String dayName;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.calendarBlank,
              size: 36,
              color: palette.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No classes on $dayName. Tap + to add one.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(palette)
                  .copyWith(color: palette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
