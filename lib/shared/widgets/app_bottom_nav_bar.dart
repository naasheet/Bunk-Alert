import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(
          top: BorderSide(
            color: palette.border,
            width: 0.5,
          ),
        ),
      ),
      child: SizedBox(
        height: AppSpacing.section,
        child: Row(
          children: [
            _NavItem(
              label: 'Home',
              isActive: currentIndex == 0,
              activeIcon: PhosphorIconsFill.house,
              inactiveIcon: PhosphorIconsRegular.house,
              palette: palette,
              onTap: () => _handleTap(0),
            ),
            _NavItem(
              label: 'Subjects',
              isActive: currentIndex == 1,
              activeIcon: PhosphorIconsFill.book,
              inactiveIcon: PhosphorIconsRegular.book,
              palette: palette,
              onTap: () => _handleTap(1),
            ),
            _NavItem(
              label: 'Timetable',
              isActive: currentIndex == 2,
              activeIcon: PhosphorIconsFill.calendarBlank,
              inactiveIcon: PhosphorIconsRegular.calendarBlank,
              palette: palette,
              onTap: () => _handleTap(2),
            ),
            _NavItem(
              label: 'Analytics',
              isActive: currentIndex == 3,
              activeIcon: PhosphorIconsFill.chartBar,
              inactiveIcon: PhosphorIconsRegular.chartBar,
              palette: palette,
              onTap: () => _handleTap(3),
            ),
            _NavItem(
              label: 'Social',
              isActive: currentIndex == 4,
              activeIcon: PhosphorIconsFill.users,
              inactiveIcon: PhosphorIconsRegular.users,
              palette: palette,
              onTap: () => _handleTap(4),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(int index) {
    HapticFeedback.selectionClick();
    onTap(index);
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.isActive,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final AppColorPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? palette.textPrimary : palette.textTertiary;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              isActive ? activeIcon : inactiveIcon,
              size: 22,
              color: color,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.labelSmall(palette).copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
