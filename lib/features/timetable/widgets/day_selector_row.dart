import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/shared/providers/timetable_stream_provider.dart';

class DaySelectorRow extends ConsumerWidget {
  const DaySelectorRow({super.key});

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const double _headerHeight = 56;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final selectedDay = ref.watch(selectedTimetableDayProvider);
    final today = DateTime.now().weekday;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _DaySelectorHeader(
        child: SizedBox(
          height: _headerHeight,
          child: Container(
            color: palette.background,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: List.generate(_labels.length, (index) {
                final day = index + 1;
                final isSelected = day == selectedDay;
                final isToday = day == today;
                final textColor =
                    isSelected ? palette.textPrimary : palette.textTertiary;

                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppSpacing.lg),
                    onTap: () => ref
                        .read(selectedTimetableDayProvider.notifier)
                        .state = day,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: isToday ? palette.surfaceElevated : null,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.xl),
                            border: isToday
                                ? Border.all(color: palette.border)
                                : null,
                          ),
                          child: Text(
                            _labels[index],
                            style: AppTextStyles.labelMedium(palette)
                                .copyWith(color: textColor),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          height: 2,
                          width: 2,
                          decoration: BoxDecoration(
                            color: palette.textPrimary,
                            shape: BoxShape.circle,
                          ),
                        )
                            .animate(target: isSelected ? 1 : 0)
                            .fade(
                              duration: 220.ms,
                              curve: Curves.easeInOut,
                              begin: 0,
                              end: 1,
                            )
                            .scale(
                              duration: 220.ms,
                              curve: Curves.easeInOut,
                              begin: const Offset(0.6, 0.6),
                              end: const Offset(1, 1),
                            ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _DaySelectorHeader extends SliverPersistentHeaderDelegate {
  _DaySelectorHeader({required this.child});

  final Widget child;

  @override
  double get minExtent => DaySelectorRow._headerHeight;

  @override
  double get maxExtent => DaySelectorRow._headerHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _DaySelectorHeader oldDelegate) {
    return oldDelegate.child != child;
  }
}
