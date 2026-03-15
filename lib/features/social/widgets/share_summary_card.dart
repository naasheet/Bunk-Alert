import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';

enum ShareCardAspect {
  story,
  square,
}

class ShareSummaryCardData {
  const ShareSummaryCardData({
    required this.appName,
    required this.subjectName,
    required this.percentage,
  });

  final String appName;
  final String subjectName;
  final double percentage;
}

class ShareSummaryCard extends StatelessWidget {
  const ShareSummaryCard({
    super.key,
    required this.data,
    required this.aspect,
  });

  final ShareSummaryCardData data;
  final ShareCardAspect aspect;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final size = _cardSize(aspect);
    final percent = data.percentage.clamp(0, 100).toDouble();

    return SizedBox(
      width: size.width,
      height: size.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.sheetRadius),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                palette.surface,
                palette.surfaceElevated,
                palette.safeSubtle,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -size.height * 0.12,
                right: -size.width * 0.2,
                child: _GlowBlob(
                  diameter: size.width * 0.7,
                  color: palette.safeSubtle,
                ),
              ),
              Positioned(
                bottom: -size.height * 0.18,
                left: -size.width * 0.3,
                child: _GlowBlob(
                  diameter: size.width * 0.8,
                  color: palette.warningSubtle,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.subjectName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingLarge(palette).copyWith(
                        fontSize: aspect == ShareCardAspect.story ? 30 : 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Overall attendance',
                      style: AppTextStyles.caption(palette).copyWith(
                        color: palette.textTertiary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${percent.round()}%',
                      style: AppTextStyles.displayLarge(palette).copyWith(
                        fontSize: aspect == ShareCardAspect.story ? 64 : 52,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ProgressBar(
                      percent: percent,
                      palette: palette,
                    ),
                    const Spacer(),
                    Text(
                      'Tracked with ${data.appName}',
                      style: AppTextStyles.labelSmall(palette).copyWith(
                        color: palette.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Size _cardSize(ShareCardAspect aspect) {
    const width = 360.0;
    switch (aspect) {
      case ShareCardAspect.story:
        return const Size(width, width * 16 / 9);
      case ShareCardAspect.square:
        return const Size(width, width);
    }
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.percent,
    required this.palette,
  });

  final double percent;
  final AppColorPalette palette;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bar = Container(
          height: 10,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: palette.border.withOpacity(0.6)),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: constraints.maxWidth * (percent / 100),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [palette.chartLine, palette.safe],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        );
        return Animate(
          effects: [
            CustomEffect(
              duration: 1000.ms,
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: palette.border.withOpacity(0.6)),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width:
                          constraints.maxWidth * (percent / 100) * value,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [palette.chartLine, palette.safe],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          child: bar,
        );
      },
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.diameter,
    required this.color,
  });

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.55),
            color.withOpacity(0),
          ],
        ),
      ),
    );
  }
}
