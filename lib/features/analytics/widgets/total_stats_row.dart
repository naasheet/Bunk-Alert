import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';

class TotalStatsRow extends StatelessWidget {
  const TotalStatsRow({
    super.key,
    this.totalAttended = 0,
    this.totalConducted = 0,
    this.overallPercentage = 0,
  });

  final int totalAttended;
  final int totalConducted;
  final int overallPercentage;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Row(
        children: [
          Expanded(
            child: _StatBox(
              label: 'Total Classes Attended',
              value: totalAttended.toDouble(),
              palette: palette,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _StatBox(
              label: 'Total Classes Conducted',
              value: totalConducted.toDouble(),
              palette: palette,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _StatBox(
              label: 'Overall Percentage',
              value: overallPercentage.toDouble(),
              suffix: '%',
              palette: palette,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.palette,
    this.suffix = '',
  });

  final String label;
  final double value;
  final String suffix;
  final AppColorPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AnimatedStatValue(
            value: value,
            suffix: suffix,
            style: AppTextStyles.headingLarge(palette),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.caption(palette)
                .copyWith(color: palette.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _AnimatedStatValue extends StatelessWidget {
  const _AnimatedStatValue({
    required this.value,
    required this.style,
    this.suffix = '',
  });

  final double value;
  final TextStyle style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Animate(
      key: ValueKey(value),
      effects: [
        CustomEffect(
          duration: 1000.ms,
          curve: Curves.easeOut,
          builder: (context, current, _) {
            final display = (value * current).round();
            return Text(
              '$display$suffix',
              style: style,
            );
          },
        ),
      ],
      child: const SizedBox.shrink(),
    );
  }
}
