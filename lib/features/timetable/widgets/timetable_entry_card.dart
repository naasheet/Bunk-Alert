import 'package:flutter/material.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/data/models/timetable_entry_model.dart';

class TimetableEntryCard extends StatelessWidget {
  const TimetableEntryCard({
    super.key,
    required this.entry,
    required this.subjectName,
  });

  final TimetableEntryModel entry;
  final String subjectName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Row(
          children: [
            Text(
              '${_formatMinutes(entry.startMinutes)} - ${_formatMinutes(entry.endMinutes)}',
              style: AppTextStyles.bodyMedium(
                Theme.of(context).brightness == Brightness.dark
                    ? AppColors.dark
                    : AppColors.light,
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: Text(
                subjectName,
                style: AppTextStyles.bodyMedium(
                  Theme.of(context).brightness == Brightness.dark
                      ? AppColors.dark
                      : AppColors.light,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final suffix = h >= 12 ? 'PM' : 'AM';
    final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final mm = m.toString().padLeft(2, '0');
    return '$hour:$mm $suffix';
  }
}
