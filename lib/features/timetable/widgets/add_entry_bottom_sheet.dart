import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:bunk_alert/core/router/route_names.dart';
import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/data/models/timetable_entry_model.dart';
import 'package:bunk_alert/data/notifications/fcm_service.dart';
import 'package:bunk_alert/data/repositories/timetable_repository.dart';
import 'package:bunk_alert/shared/providers/subjects_stream_provider.dart';
import 'package:bunk_alert/shared/providers/timetable_stream_provider.dart';
import 'package:bunk_alert/shared/utils/error_message_mapper.dart';
import 'package:bunk_alert/shared/widgets/error_state_widget.dart';
import 'package:bunk_alert/shared/widgets/loading_indicator.dart';
import 'package:bunk_alert/shared/widgets/primary_button.dart';

const _uuid = Uuid();

Future<void> showAddEntryBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final palette = Theme.of(sheetContext).brightness == Brightness.dark
          ? AppColors.dark
          : AppColors.light;
      return Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.sheetRadius),
          ),
        ),
        child: const AddEntryBottomSheet(),
      );
    },
  );
}

class AddEntryBottomSheet extends ConsumerStatefulWidget {
  const AddEntryBottomSheet({super.key});

  @override
  ConsumerState<AddEntryBottomSheet> createState() =>
      _AddEntryBottomSheetState();
}

class _AddEntryBottomSheetState extends ConsumerState<AddEntryBottomSheet> {
  final TimetableRepository _timetableRepository = TimetableRepository();

  String? _selectedSubjectId;
  Set<int> _selectedDays = <int>{};
  Duration _startTime = const Duration(hours: 9);
  Duration _endTime = const Duration(hours: 10);
  bool _isSaving = false;
  bool _autoTime = true;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  bool get _isTimeValid => _endTime.inMinutes > _startTime.inMinutes;

  bool get _canSave =>
      _selectedSubjectId != null &&
      _selectedDays.isNotEmpty &&
      _isTimeValid &&
      !_isSaving;

  Future<void> _save() async {
    final subjectId = _selectedSubjectId;
    if (subjectId == null || _selectedDays.isEmpty || !_isTimeValid) {
      return;
    }
    setState(() {
      _isSaving = true;
    });

    final now = DateTime.now();
    final startMinutes = _startTime.inMinutes;
    final endMinutes = _endTime.inMinutes;
    final entries = _selectedDays.map((day) {
      return TimetableEntryModel(
        uuid: _uuid.v4(),
        subjectUuid: subjectId,
        dayOfWeek: day,
        startMinutes: startMinutes,
        endMinutes: endMinutes,
        createdAt: now,
      );
    }).toList();

    await _timetableRepository.addEntries(entries);

    if (!mounted) {
      return;
    }
    await FcmService.instance.requestPermissionsIfReady(context);
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }

  Future<void> _pickTime({
    required Duration initial,
    required ValueChanged<Duration> onSelected,
  }) async {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    Duration temp = initial;
    final result = await showModalBottomSheet<Duration>(
      context: context,
      useSafeArea: true,
      backgroundColor: palette.surface,
      builder: (pickerContext) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                  vertical: AppSpacing.sm,
                ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () =>
                            Navigator.of(pickerContext).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(pickerContext).pop(temp),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: Theme.of(pickerContext).brightness,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle:
                          AppTextStyles.headingSmall(palette),
                    ),
                  ),
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hm,
                    initialTimerDuration: initial,
                    onTimerDurationChanged: (value) {
                      temp = value;
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        _autoTime = false;
      });
      onSelected(result);
    }
  }

  String _formatDuration(Duration duration) {
    final timeOfDay = TimeOfDay(
      hour: duration.inHours % 24,
      minute: duration.inMinutes % 60,
    );
    return MaterialLocalizations.of(context).formatTimeOfDay(timeOfDay);
  }

  void _toggleDaySelection(
    int day,
    List<TimetableEntryModel> entries,
  ) {
    final nextSelected = Set<int>.from(_selectedDays);
    if (nextSelected.contains(day)) {
      nextSelected.remove(day);
    } else {
      nextSelected.add(day);
    }

    Duration? nextStart;
    Duration? nextEnd;
    if (_autoTime && nextSelected.contains(day)) {
      final times = _autoTimesForDay(day, entries);
      if (times != null) {
        nextStart = times.start;
        nextEnd = times.end;
      }
    }

    setState(() {
      _selectedDays = nextSelected;
      if (nextStart != null && nextEnd != null) {
        _startTime = nextStart!;
        _endTime = nextEnd!;
      }
    });
  }

  _AutoTimes? _autoTimesForDay(
    int day,
    List<TimetableEntryModel> entries,
  ) {
    final dayEntries = entries
        .where((entry) => entry.dayOfWeek == day && entry.isActive)
        .toList()
      ..sort((a, b) => a.endMinutes.compareTo(b.endMinutes));
    if (dayEntries.isEmpty) {
      return null;
    }
    final lastEnd = dayEntries.last.endMinutes;
    final startMinutes = lastEnd.clamp(0, 24 * 60 - 1);
    var endMinutes = startMinutes + 60;
    if (endMinutes > 24 * 60 - 1) {
      endMinutes = 24 * 60 - 1;
    }
    return _AutoTimes(
      start: Duration(minutes: startMinutes),
      end: Duration(minutes: endMinutes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final subjectsAsync = ref.watch(subjectsStreamProvider);
    final entriesAsync = ref.watch(timetableEntriesStreamProvider);
    final allEntries = entriesAsync.value ?? const <TimetableEntryModel>[];
    final subjectSelector = subjectsAsync.when<Widget>(
      data: (subjects) {
        if (subjects.isEmpty) {
          return _EmptySubjectChip(
            onTap: () {
              Navigator.of(context).pop();
              context.go(RouteNames.addSubject);
            },
          );
        }
        return SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: subjects.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final subject = subjects[index];
              final isSelected = subject.uuid == _selectedSubjectId;
              return _SubjectChip(
                label: subject.name,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedSubjectId = subject.uuid;
                  });
                },
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 44,
        child: Center(child: LoadingIndicator()),
      ),
      error: (error, stackTrace) => SizedBox(
        height: 72,
        child: ErrorStateWidget(
          message: friendlyErrorMessage(error),
          onRetry: () => ref.invalidate(subjectsStreamProvider),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.base,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Subject',
                style: AppTextStyles.labelSmall(palette),
              ),
              const SizedBox(height: AppSpacing.sm),
              subjectSelector,
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Repeats on',
                style: AppTextStyles.labelSmall(palette),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: List.generate(_dayLabels.length, (index) {
                  final day = index + 1;
                  final isSelected = _selectedDays.contains(day);
                  return _DayChip(
                    label: _dayLabels[index],
                    isSelected: isSelected,
                    onTap: () {
                      _toggleDaySelection(day, allEntries);
                    },
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      label: 'From',
                      value: _formatDuration(_startTime),
                      onTap: () => _pickTime(
                        initial: _startTime,
                        onSelected: (value) {
                          setState(() {
                            _startTime = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _TimeField(
                      label: 'To',
                      value: _formatDuration(_endTime),
                      onTap: () => _pickTime(
                        initial: _endTime,
                        onSelected: (value) {
                          setState(() {
                            _endTime = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              if (!_isTimeValid)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    'End time must be after start time.',
                    style: AppTextStyles.caption(palette)
                        .copyWith(color: palette.danger),
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Save',
                isLoading: _isSaving,
                onPressed: _canSave ? _save : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  const _SubjectChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final borderColor = isSelected ? palette.textPrimary : palette.border;
    final textColor = isSelected ? palette.textPrimary : palette.textSecondary;
    final background =
        isSelected ? palette.surfaceElevated : palette.surface;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style:
                  AppTextStyles.labelMedium(palette).copyWith(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySubjectChip extends StatelessWidget {
  const _EmptySubjectChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.border),
        ),
        child: Text(
          'Add a subject first',
          style: AppTextStyles.labelMedium(palette),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final background =
        isSelected ? palette.surfaceElevated : palette.surface;
    final textColor = isSelected ? palette.textPrimary : palette.textTertiary;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.border),
        ),
        child: Text(
          label,
          style:
              AppTextStyles.labelMedium(palette).copyWith(color: textColor),
        ),
      ),
    );
  }
}

class _AutoTimes {
  const _AutoTimes({required this.start, required this.end});

  final Duration start;
  final Duration end;
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSmall(palette),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: AppTextStyles.labelLarge(palette),
            ),
          ],
        ),
      ),
    );
  }
}
