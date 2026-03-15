import 'package:flutter/material.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/data/models/attendance_record_model.dart';

class MonthlyHeatmap extends StatelessWidget {
  const MonthlyHeatmap({
    super.key,
    required this.records,
  });

  final List<AttendanceRecordModel> records;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;

    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final firstWeekday = firstOfMonth.weekday % 7; // Sunday = 0
    final totalCells = firstWeekday + daysInMonth;
    final weeks = (totalCells / 7).ceil();

    final dayMap = <DateTime, _DaySummary>{};
    for (final record in records) {
      dayMap.update(
        record.date,
        (summary) => summary.add(record.status),
        ifAbsent: () => _DaySummary.fromStatus(record.status),
      );
    }

    final cells = <Widget>[];
    for (var i = 0; i < weeks * 7; i++) {
      final dayNumber = i - firstWeekday + 1;
      if (dayNumber < 1 || dayNumber > daysInMonth) {
        cells.add(const SizedBox(width: 32, height: 32));
        continue;
      }
      final date = DateTime(now.year, now.month, dayNumber);
      final summary = dayMap[date];
      final state = _dayState(date, summary, now);
      cells.add(
        _DayCell(
          day: dayNumber,
          color: _stateColor(state, palette),
          isFuture: state == _DayState.future,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: cells,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Green = all attended, amber = some skipped, red = all skipped.',
            style: AppTextStyles.caption(palette)
                .copyWith(color: palette.textTertiary),
          ),
        ],
      ),
    );
  }

  _DayState _dayState(
    DateTime date,
    _DaySummary? summary,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    if (date.isAfter(today)) {
      return _DayState.future;
    }
    if (summary == null || summary.total == 0) {
      return _DayState.noClasses;
    }
    if (summary.attended == summary.total) {
      return _DayState.allAttended;
    }
    if (summary.attended == 0) {
      return _DayState.allSkipped;
    }
    return _DayState.someSkipped;
  }

  Color _stateColor(_DayState state, AppColorPalette palette) {
    switch (state) {
      case _DayState.allAttended:
        return palette.safe;
      case _DayState.someSkipped:
        return palette.warning;
      case _DayState.allSkipped:
        return palette.danger;
      case _DayState.noClasses:
        return palette.border;
      case _DayState.future:
      default:
        return palette.border.withOpacity(0.4);
    }
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.color,
    required this.isFuture,
  });

  final int day;
  final Color color;
  final bool isFuture;

  @override
  Widget build(BuildContext context) {
    final size = 32.0;
    final textColor = isFuture
        ? Colors.transparent
        : Theme.of(context).brightness == Brightness.dark
            ? AppColors.dark.textPrimary
            : AppColors.light.textPrimary;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$day',
        style: TextStyle(
          fontSize: 10,
          color: textColor.withOpacity(0.7),
        ),
      ),
    );
  }
}

class _DaySummary {
  const _DaySummary({
    required this.attended,
    required this.total,
  });

  final int attended;
  final int total;

  factory _DaySummary.fromStatus(String status) {
    switch (status) {
      case 'present':
        return const _DaySummary(attended: 1, total: 1);
      case 'absent':
      case 'cancelled':
      default:
        return const _DaySummary(attended: 0, total: 1);
    }
  }

  _DaySummary add(String status) {
    final extra = _DaySummary.fromStatus(status);
    return _DaySummary(
      attended: attended + extra.attended,
      total: total + extra.total,
    );
  }
}

enum _DayState {
  allAttended,
  someSkipped,
  allSkipped,
  noClasses,
  future,
}
