import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/core/utils/risk_calculator.dart';
import 'package:bunk_alert/domain/entities/attendance_stats_entity.dart';

class SubjectBreakdownChart extends StatelessWidget {
  const SubjectBreakdownChart({
    super.key,
    required this.stats,
    required this.targetPercentage,
  });

  final List<AttendanceStatsEntity> stats;
  final double targetPercentage;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;

    if (stats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        child: Text(
          'No subject data yet.',
          style: AppTextStyles.bodySmall(palette)
              .copyWith(color: palette.textTertiary),
        ),
      );
    }

    final maxPercent = stats
        .map((entry) => entry.currentPercentage)
        .fold<double>(0, math.max);
    final maxY = math.max(100.0, math.max(maxPercent, targetPercentage));

    List<BarChartGroupData> buildGroups(double factor) {
      final groups = <BarChartGroupData>[];
      for (var i = 0; i < stats.length; i++) {
        final entry = stats[i];
        final color = _barColor(
          palette,
          entry.currentPercentage,
          entry.targetPercentage,
        );
        groups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                fromY: 0,
                toY: entry.currentPercentage * factor,
                width: 14,
                color: color,
                borderRadius: BorderRadius.zero,
              ),
            ],
            showingTooltipIndicators: const [0],
          ),
        );
      }
      return groups;
    }

    final height = math.max(140.0, stats.length * 44.0);

    Widget buildChart(double factor) {
      return RotatedBox(
        quarterTurns: 1,
        child: BarChart(
          BarChartData(
            minY: 0,
            maxY: maxY,
            barGroups: buildGroups(factor),
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            alignment: BarChartAlignment.spaceBetween,
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
                  reservedSize: 90,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= stats.length) {
                      return const SizedBox.shrink();
                    }
                    return RotatedBox(
                      quarterTurns: -1,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          stats[index].subjectName,
                          style: AppTextStyles.caption(palette),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                tooltipMargin: 6,
                getTooltipColor: (_) => palette.surface,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final value = rod.toY.round();
                  return BarTooltipItem(
                    '$value%',
                    AppTextStyles.caption(palette)
                        .copyWith(color: palette.textPrimary),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: SizedBox(
        height: height,
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

  Color _barColor(
    AppColorPalette palette,
    double current,
    double target,
  ) {
    final level = RiskCalculator.calculateRiskLevel(current, target);
    switch (level) {
      case RiskLevel.safe:
        return palette.safe;
      case RiskLevel.warning:
        return palette.warning;
      case RiskLevel.danger:
      case RiskLevel.critical:
        return palette.danger;
      case RiskLevel.noData:
      default:
        return palette.textTertiary;
    }
  }
}
