import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/core/router/app_router.dart';
import 'package:bunk_alert/core/router/route_names.dart';
import 'package:bunk_alert/shared/widgets/animated_counter.dart';

class OverallStatHeader extends StatelessWidget {
  const OverallStatHeader({
    super.key,
    required this.overallPercentage,
    required this.targetPercentage,
    required this.hasData,
    required this.firstName,
    required this.isLoading,
  });

  final double overallPercentage;
  final double targetPercentage;
  final bool hasData;
  final String firstName;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final clampedPercent = overallPercentage.clamp(0, 100).toDouble();
    final greeting = _greetingForHour(DateTime.now().hour, firstName);
    final isSafe = hasData && clampedPercent >= targetPercentage;
    final toneColor = hasData
        ? (isSafe ? palette.safe : palette.danger)
        : palette.textTertiary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.xl,
        AppSpacing.base,
        AppSpacing.md,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 200),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            greeting,
                            style: AppTextStyles.bodySmall(palette)
                                .copyWith(color: palette.textTertiary),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: () =>
                              AppRouter.router.push(RouteNames.settings),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AnimatedCounter(
                      value: clampedPercent,
                      decimals: 1,
                      textStyle: AppTextStyles.displayHero(palette)
                          .copyWith(color: toneColor),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'across all subjects',
                      style: AppTextStyles.caption(palette)
                          .copyWith(color: palette.textTertiary),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ClipRect(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.base,
                        ),
                        child: Animate(
                          effects: [
                            CustomEffect(
                              duration: 1000.ms,
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) {
                                return LinearPercentIndicator(
                                  padding: EdgeInsets.zero,
                                  lineHeight: 3,
                                  percent: (clampedPercent / 100) * value,
                                  backgroundColor: palette.border,
                                  progressColor: toneColor,
                                  barRadius: Radius.zero,
                                  linearStrokeCap: LinearStrokeCap.butt,
                                );
                              },
                            ),
                          ],
                          child: LinearPercentIndicator(
                            padding: EdgeInsets.zero,
                            lineHeight: 3,
                            percent: clampedPercent / 100,
                            backgroundColor: palette.border,
                            progressColor: toneColor,
                            barRadius: Radius.zero,
                            linearStrokeCap: LinearStrokeCap.butt,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _greetingForHour(int hour, String name) {
    if (hour < 12) {
      return 'Good morning, $name';
    }
    if (hour < 18) {
      return 'Good afternoon, $name';
    }
    return 'Good evening, $name';
  }
}
