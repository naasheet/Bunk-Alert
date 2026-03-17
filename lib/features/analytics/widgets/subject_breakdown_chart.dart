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

    double normalizePercent(double value) {
      if (value.isNaN || value.isInfinite) {
        return 0.0;
      }
      return value.clamp(0.0, 100.0);
    }

    final maxPercent = stats
        .map((entry) => normalizePercent(entry.currentPercentage))
        .fold<double>(0, math.max);
    final clampedTarget = normalizePercent(targetPercentage);
    final maxY = math.max(100.0, math.max(maxPercent, clampedTarget));
    final noDataCount =
        stats.where((entry) => entry.conducted == 0).length;
    const barSlotWidth = 64.0;
    const barWidth = 20.0;
    const chartHeight = 240.0;

    List<BarChartGroupData> buildGroups(double factor) {
      final groups = <BarChartGroupData>[];
      for (var i = 0; i < stats.length; i++) {
        final entry = stats[i];
        final color = _barColor(
          palette,
          entry.currentPercentage,
          entry.targetPercentage,
        );
        final percent = normalizePercent(entry.currentPercentage);
        groups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                fromY: 0,
                toY: percent * factor,
                width: barWidth,
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
            showingTooltipIndicators: const [0],
          ),
        );
      }
      return groups;
    }

    Widget buildChart(double factor) {
      return BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY,
          barGroups: buildGroups(factor),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: palette.border,
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          alignment: BarChartAlignment.spaceAround,
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: clampedTarget,
                color: palette.textTertiary,
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
            ],
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 25,
                getTitlesWidget: (value, meta) {
                  final rounded = value.round();
                  final isWhole = (value - rounded).abs() < 0.001;
                  if (!isWhole || rounded % 25 != 0) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    '$rounded',
                    style: AppTextStyles.caption(palette)
                        .copyWith(color: palette.textTertiary),
                  );
                },
              ),
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
                reservedSize: 56,
                getTitlesWidget: (value, meta) {
                  final rounded = value.round();
                  if ((value - rounded).abs() >= 0.001) {
                    return const SizedBox.shrink();
                  }
                  final index = rounded;
                  if (index < 0 || index >= stats.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: SizedBox(
                      width: barSlotWidth - 8,
                      child: Text(
                        stats[index].subjectName,
                        style: AppTextStyles.caption(palette)
                            .copyWith(color: palette.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
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
                final hasData = stats[groupIndex].conducted > 0;
                if (!hasData) {
                  return null;
                }
                final value = rod.toY.round();
                final label = '$value%';
                return BarTooltipItem(
                  label,
                  AppTextStyles.caption(palette)
                      .copyWith(color: palette.textPrimary),
                );
              },
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final minChartWidth = constraints.maxWidth;
              final neededChartWidth = stats.length * barSlotWidth;
              final chartWidth = math.max(minChartWidth, neededChartWidth);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: chartWidth,
                  height: chartHeight,
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
            },
          ),
          if (noDataCount > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'No data for $noDataCount subject${noDataCount == 1 ? '' : 's'} yet.',
              style: AppTextStyles.caption(palette)
                  .copyWith(color: palette.textTertiary),
            ),
          ],
        ],
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
