import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';

class TimeRangePicker extends StatelessWidget {
  const TimeRangePicker({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final ValueChanged<TimeOfDay> onStartChanged;
  final ValueChanged<TimeOfDay> onEndChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TimeField(
            time: startTime,
            onTap: () => _showPicker(
              context,
              initial: startTime,
              onChanged: onStartChanged,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _TimeField(
            time: endTime,
            onTap: () => _showPicker(
              context,
              initial: endTime,
              onChanged: onEndChanged,
            ),
          ),
        ),
      ],
    );
  }

  void _showPicker(
    BuildContext context, {
    required TimeOfDay initial,
    required ValueChanged<TimeOfDay> onChanged,
  }) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (popupContext) {
        return Container(
          color: palette.surface,
          height: 280,
          child: SafeArea(
            top: false,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: DateTime(
                0,
                1,
                1,
                initial.hour,
                initial.minute,
              ),
              use24hFormat: false,
              onDateTimeChanged: (value) {
                onChanged(
                  TimeOfDay(hour: value.hour, minute: value.minute),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.time,
    required this.onTap,
  });

  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final formatted = MaterialLocalizations.of(context).formatTimeOfDay(time);

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          border: Border.all(color: palette.border),
        ),
        child: Text(
          formatted,
          style: AppTextStyles.headingSmall(palette),
        ),
      ),
    );
  }
}
