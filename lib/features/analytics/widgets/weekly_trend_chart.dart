import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/data/models/attendance_record_model.dart';

class WeeklyTrendChart extends StatelessWidget {
  const WeeklyTrendChart({
    super.key,
    required this.records,
    required this.targetPercentage,
  });

  final List<AttendanceRecordModel> records;
  final double targetPercentage;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;

    final now = DateTime.now();
    final days = List.generate(
      7,
      (index) => DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - index)),
    );

    final spots = <FlSpot>[];
    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      final hasRecordsForDay = records.any((record) {
        return record.date == day;
      });
      if (!hasRecordsForDay) {
        continue;
      }
      final endOfDay = day.add(const Duration(days: 1));
      final cumulative = _calculateTotals(
        records.where((record) => record.date.isBefore(endOfDay)).toList(),
      );
      final percentage = cumulative.conducted == 0
          ? 0.0
          : (cumulative.attended / cumulative.conducted) * 100;
      spots.add(FlSpot(i.toDouble(), percentage));
    }

    Widget buildChart(double factor) {
      final scaledSpots = spots
          .map((spot) => FlSpot(spot.x, spot.y * factor))
          .toList();
      return LineChart(
        LineChartData(
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: 100.0,
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: targetPercentage,
                color: palette.textTertiary,
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
            ],
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= days.length) {
                    return const SizedBox.shrink();
                  }
                  final label = DateFormat('E').format(days[index]);
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      label,
                      style: AppTextStyles.caption(palette)
                          .copyWith(color: palette.textTertiary),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: scaledSpots,
              isCurved: true,
              color: palette.chartLine,
              barWidth: 2,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: palette.chartFill.withOpacity(0.4),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => palette.surface,
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.round()}%',
                    AppTextStyles.caption(palette)
                        .copyWith(color: palette.textPrimary),
                  );
                }).toList();
              },
            ),
            getTouchedSpotIndicator:
                (LineChartBarData barData, List<int> indicators) {
              return indicators.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: palette.border,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                  FlDotData(show: true),
                );
              }).toList();
            },
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: SizedBox(
        height: 220.0,
        child: Animate(
          effects: [
            CustomEffect(
              duration: 1000.ms,
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => buildChart(value),
            ),
          ],
          child: buildChart(1),
        ),
      ),
    );
  }

  _Totals _calculateTotals(List<AttendanceRecordModel> records) {
    var attended = 0;
    var conducted = 0;
    for (final record in records) {
      switch (record.status) {
        case 'present':
          attended++;
          conducted++;
        case 'absent':
          conducted++;
        case 'cancelled':
          break;
      }
    }
    return _Totals(attended: attended, conducted: conducted);
  }
}

class _Totals {
  const _Totals({
    required this.attended,
    required this.conducted,
  });

  final int attended;
  final int conducted;
}
