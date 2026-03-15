import 'package:flutter/material.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/core/utils/bunk_calculator.dart';
import 'package:bunk_alert/core/utils/risk_calculator.dart';

class SkipImpactPreview extends StatefulWidget {
  const SkipImpactPreview({
    super.key,
    required this.attended,
    required this.conducted,
    required this.targetPercentage,
  });

  final int attended;
  final int conducted;
  final double targetPercentage;

  @override
  State<SkipImpactPreview> createState() => _SkipImpactPreviewState();
}

class _SkipImpactPreviewState extends State<SkipImpactPreview> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final prediction = BunkCalculator.predictAfterSkipping(
      widget.attended,
      widget.conducted,
      1,
      widget.targetPercentage,
    );
    final risk = RiskCalculator.calculateRiskLevel(
      prediction.predictedPercentage,
      widget.targetPercentage,
    );
    final indicator = _indicatorForRisk(risk, palette);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Skip impact',
                style: AppTextStyles.caption(palette)
                    .copyWith(color: palette.textSecondary),
              ),
              Icon(
                _isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 18,
                color: palette.textSecondary,
              ),
            ],
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  'If you skip tomorrow \u2192 ${prediction.predictedPercentage.round()}%',
                  style: AppTextStyles.bodySmall(palette),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: indicator.background,
                  borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: indicator.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      indicator.label,
                      style: AppTextStyles.caption(palette)
                          .copyWith(color: indicator.color),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  _RiskIndicator _indicatorForRisk(
    RiskLevel level,
    AppColorPalette palette,
  ) {
    switch (level) {
      case RiskLevel.safe:
        return _RiskIndicator(
          label: 'Safe',
          color: palette.safe,
          background: palette.safeSubtle,
        );
      case RiskLevel.warning:
        return _RiskIndicator(
          label: 'Warning',
          color: palette.warning,
          background: palette.warningSubtle,
        );
      case RiskLevel.danger:
      case RiskLevel.critical:
        return _RiskIndicator(
          label: 'Danger',
          color: palette.danger,
          background: palette.dangerSubtle,
        );
      case RiskLevel.noData:
      default:
        return _RiskIndicator(
          label: 'Unknown',
          color: palette.textSecondary,
          background: palette.surfaceElevated,
        );
    }
  }
}

class _RiskIndicator {
  const _RiskIndicator({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;
}
