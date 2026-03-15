import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bunk_alert/core/router/route_names.dart';
import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/core/utils/risk_calculator.dart';

class RiskBanner extends StatelessWidget {
  const RiskBanner({super.key, required this.riskScore});

  final OverallRiskScore? riskScore;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final danger = riskScore?.dangerCount ?? 0;
    final critical = riskScore?.criticalCount ?? 0;
    final total = danger + critical;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: () => context.go(RouteNames.analytics),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: palette.dangerSubtle,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: palette.danger),
          ),
          child: Row(
            children: [
              PhosphorIcon(
                PhosphorIconsFill.warningCircle,
                color: palette.danger,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '⚠ $total subjects at risk',
                  style: AppTextStyles.labelLarge(palette)
                      .copyWith(color: palette.danger),
                ),
              ),
              Text(
                'View',
                style: AppTextStyles.labelLarge(palette)
                    .copyWith(color: palette.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
