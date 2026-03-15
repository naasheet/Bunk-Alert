import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/domain/usecases/mark_attendance_usecase.dart';

class AttendanceActionRow extends StatefulWidget {
  const AttendanceActionRow({
    super.key,
    required this.subjectUuid,
    required this.timetableEntryUuid,
    required this.initialStatus,
    this.markAttendanceUsecase,
    this.onMarked,
  });

  final String subjectUuid;
  final String timetableEntryUuid;
  final String? initialStatus;
  final MarkAttendanceUsecase? markAttendanceUsecase;
  final VoidCallback? onMarked;

  @override
  State<AttendanceActionRow> createState() => _AttendanceActionRowState();
}

class _AttendanceActionRowState extends State<AttendanceActionRow> {
  late final MarkAttendanceUsecase _markAttendanceUsecase =
      widget.markAttendanceUsecase ?? MarkAttendanceUsecase();

  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
  }

  @override
  void didUpdateWidget(covariant AttendanceActionRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStatus != widget.initialStatus) {
      _selectedStatus = widget.initialStatus;
    }
  }

  Future<void> _handleTap(String status) async {
    if (_selectedStatus == status) {
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _selectedStatus = status;
    });
    unawaited(
      _markAttendanceUsecase
          .call(
            subjectUuid: widget.subjectUuid,
            status: status,
            date: DateTime.now(),
            timetableEntryUuid: widget.timetableEntryUuid,
          )
          .then((_) => widget.onMarked?.call()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionChip(
          label: 'Present',
          icon: PhosphorIconsRegular.checkCircle,
          isSelected: _selectedStatus == 'present',
          selectedColor: palette.safe,
          selectedBackground: palette.safeSubtle,
          unselectedBackground: palette.surfaceElevated,
          onTap: () => _handleTap('present'),
        ),
        _ActionChip(
          label: 'Absent',
          icon: PhosphorIconsRegular.xCircle,
          isSelected: _selectedStatus == 'absent',
          selectedColor: palette.danger,
          selectedBackground: palette.dangerSubtle,
          unselectedBackground: palette.surfaceElevated,
          onTap: () => _handleTap('absent'),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.selectedColor,
    required this.selectedBackground,
    required this.unselectedBackground,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final Color selectedBackground;
  final Color unselectedBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final color = isSelected ? selectedColor : palette.textTertiary;
    final background =
        isSelected ? selectedBackground : unselectedBackground;

    return GestureDetector(
      onTap: onTap,
      child: Animate(
        target: isSelected ? 1 : 0,
        effects: [
          CustomEffect(
            duration: 220.ms,
            curve: Curves.easeInOut,
            builder: (context, value, _) {
              final chipColor = Color.lerp(
                palette.textTertiary,
                selectedColor,
                value,
              )!;
              final chipBackground = Color.lerp(
                unselectedBackground,
                selectedBackground,
                value,
              )!;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: chipBackground,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.chipRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhosphorIcon(
                      icon,
                      size: 16,
                      color: chipColor,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      label,
                      style: AppTextStyles.labelMedium(palette)
                          .copyWith(color: chipColor),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.labelMedium(palette)
                    .copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
