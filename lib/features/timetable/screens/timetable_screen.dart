import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/data/database/local_database_service.dart';
import 'package:bunk_alert/data/models/subject_model.dart';
import 'package:bunk_alert/data/models/timetable_entry_model.dart';
import 'package:bunk_alert/data/repositories/subject_repository.dart';
import 'package:bunk_alert/data/repositories/timetable_repository.dart';
import 'package:bunk_alert/features/timetable/widgets/add_entry_bottom_sheet.dart';
import 'package:bunk_alert/features/timetable/widgets/day_selector_row.dart';
import 'package:bunk_alert/features/timetable/widgets/empty_timetable_state.dart';
import 'package:bunk_alert/features/timetable/widgets/timetable_entry_card.dart';
import 'package:bunk_alert/shared/providers/subjects_stream_provider.dart';
import 'package:bunk_alert/shared/providers/timetable_stream_provider.dart';
import 'package:bunk_alert/shared/utils/error_message_mapper.dart';
import 'package:bunk_alert/shared/widgets/app_scaffold.dart';
import 'package:bunk_alert/shared/widgets/confirmation_dialog.dart';
import 'package:bunk_alert/shared/widgets/error_state_widget.dart';
import 'package:bunk_alert/shared/widgets/loading_indicator.dart';

class TimetableScreen extends ConsumerWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final selectedDay = ref.watch(selectedTimetableDayProvider);
    final entriesAsync = ref.watch(timetableEntriesStreamProvider);
    final subjectsAsync = ref.watch(subjectsStreamProvider);
    final dayName = _dayName(selectedDay);
    final error = entriesAsync.error ?? subjectsAsync.error;
    final isLoading = entriesAsync.isLoading || subjectsAsync.isLoading;
    final entriesSliver = () {
      if (error != null) {
        return SliverFillRemaining(
          child: ErrorStateWidget(
            message: friendlyErrorMessage(error),
            onRetry: () {
              ref.invalidate(timetableEntriesStreamProvider);
              ref.invalidate(subjectsStreamProvider);
            },
          ),
        );
      }
      if (isLoading) {
        return const SliverFillRemaining(
          child: Center(child: LoadingIndicator()),
        );
      }

      final entries = entriesAsync.value ?? const [];
      final subjects = subjectsAsync.value ?? const [];
      final subjectNames = {
        for (final subject in subjects) subject.uuid: subject.name,
      };
      final dayEntries = entries
          .where((entry) => entry.dayOfWeek == selectedDay)
          .toList()
        ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
      if (dayEntries.isEmpty) {
        return SliverFillRemaining(
          child: EmptyTimetableState(dayName: dayName),
        );
      }
        return SliverList.separated(
          itemBuilder: (context, index) {
            final entry = dayEntries[index];
            final subjectName =
                subjectNames[entry.subjectUuid] ?? 'Unknown subject';
            return _TimetableEntryTile(
              entry: entry,
              subjectName: subjectName,
            );
          },
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.sm),
        itemCount: dayEntries.length,
      );
    }();

    return AppScaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: palette.background,
            title: Text(
              'Timetable',
              style: AppTextStyles.headingSmall(palette),
            ),
            actions: [
              PopupMenuButton<_TimetableAction>(
                icon: const Icon(Icons.more_horiz),
                onSelected: (action) => _handleTimetableAction(
                  context,
                  action,
                ),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _TimetableAction.share,
                    child: Text('Share timetable'),
                  ),
                  PopupMenuItem(
                    value: _TimetableAction.import,
                    child: Text('Import timetable'),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.base),
                child: GestureDetector(
                  onTap: () {
                    showAddEntryBottomSheet(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surfaceElevated,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                    child: Row(
                      children: [
                        PhosphorIcon(
                          PhosphorIconsRegular.plus,
                          size: 16,
                          color: palette.textPrimary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Add Class',
                          style: AppTextStyles.labelMedium(palette),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const DaySelectorRow(),
          entriesSliver,
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.section),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTimetableAction(
    BuildContext context,
    _TimetableAction action,
  ) async {
    switch (action) {
      case _TimetableAction.share:
        await _shareTimetable(context);
      case _TimetableAction.import:
        await _showImportSheet(context);
    }
  }

  Future<void> _shareTimetable(BuildContext context) async {
    final subjects = await SubjectRepository().getActiveSubjects();
    final entries = await TimetableRepository().getAllActiveEntries();
    final subjectMap = {
      for (final subject in subjects) subject.uuid: subject.name,
    };
    final payload = {
      'version': 1,
      'generatedAt': DateTime.now().toIso8601String(),
      'subjects': subjects.map((subject) => {'name': subject.name}).toList(),
      'entries': entries
          .map(
            (entry) => {
              'subjectName':
                  subjectMap[entry.subjectUuid] ?? 'Subject',
              'dayOfWeek': entry.dayOfWeek,
              'startMinutes': entry.startMinutes,
              'endMinutes': entry.endMinutes,
            },
          )
          .toList(),
    };
    final text = 'BUNK_ALERT_TIMETABLE:${jsonEncode(payload)}';
    await Share.share(text);
  }

  Future<void> _showImportSheet(BuildContext context) async {
    final controller = TextEditingController();
    bool isImporting = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        final palette = Theme.of(sheetContext).brightness == Brightness.dark
            ? AppColors.dark
            : AppColors.light;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.base,
                right: AppSpacing.base,
                top: AppSpacing.base,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
                    AppSpacing.base,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Import timetable',
                    style: AppTextStyles.headingSmall(palette),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Paste the shared timetable code.',
                    style: AppTextStyles.bodySmall(palette)
                        .copyWith(color: palette.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: controller,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'BUNK_ALERT_TIMETABLE:...',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.cardRadius),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isImporting
                          ? null
                          : () async {
                              final text = controller.text.trim();
                              if (text.isEmpty) {
                                return;
                              }
                              setSheetState(() {
                                isImporting = true;
                              });
                              final result =
                                  await _importTimetablePayload(text);
                              if (sheetContext.mounted) {
                                setSheetState(() {
                                  isImporting = false;
                                });
                                if (result != null) {
                                  Navigator.of(sheetContext).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Imported ${result.subjectsAdded} subjects and ${result.entriesAdded} classes.',
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Invalid timetable code.'),
                                    ),
                                  );
                                }
                              }
                            },
                      child: isImporting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Import'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    controller.dispose();
  }

  Future<_ImportResult?> _importTimetablePayload(String raw) async {
    final text = raw.startsWith('BUNK_ALERT_TIMETABLE:')
        ? raw.substring('BUNK_ALERT_TIMETABLE:'.length)
        : raw;
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final entriesRaw = decoded['entries'];
    if (entriesRaw is! List) {
      return null;
    }

    final allSubjects =
        await LocalDatabaseService.instance.subjects.where().findAll();
    final subjectByName = <String, SubjectModel>{
      for (final subject in allSubjects)
        subject.name.trim().toLowerCase(): subject,
    };
    final createdSubjects = <SubjectModel>[];

    final subjectRepository = SubjectRepository();
    final timetableRepository = TimetableRepository();
    final existingEntries = await timetableRepository.getAllActiveEntries();
    final existingKeys = existingEntries
        .map(
          (entry) =>
              '${entry.subjectUuid}-${entry.dayOfWeek}-${entry.startMinutes}-${entry.endMinutes}',
        )
        .toSet();

    final uuid = const Uuid();
    final now = DateTime.now();
    final entriesToAdd = <TimetableEntryModel>[];

    for (final rawEntry in entriesRaw) {
      if (rawEntry is! Map) {
        continue;
      }
      final subjectName = (rawEntry['subjectName'] as String?)
              ?.trim()
              .replaceAll(RegExp(r'\s+'), ' ') ??
          '';
      if (subjectName.isEmpty) {
        continue;
      }
      final day = (rawEntry['dayOfWeek'] as num?)?.toInt() ?? 0;
      final startMinutes =
          (rawEntry['startMinutes'] as num?)?.toInt() ?? -1;
      final endMinutes =
          (rawEntry['endMinutes'] as num?)?.toInt() ?? -1;
      if (day < 1 ||
          day > 7 ||
          startMinutes < 0 ||
          endMinutes <= startMinutes) {
        continue;
      }

      final key = subjectName.toLowerCase();
      var subject = subjectByName[key];
      if (subject == null) {
        subject = SubjectModel(
          uuid: uuid.v4(),
          name: subjectName,
          colorTagIndex: 0,
          targetPercentage: null,
          expectedTotalClasses: null,
          isArchived: false,
          syncStatus: 'pending',
          createdAt: now,
          updatedAt: now,
        );
        subjectByName[key] = subject;
        createdSubjects.add(subject);
      }

      final entryKey =
          '${subject.uuid}-$day-$startMinutes-$endMinutes';
      if (existingKeys.contains(entryKey)) {
        continue;
      }
      entriesToAdd.add(
        TimetableEntryModel(
          uuid: uuid.v4(),
          subjectUuid: subject.uuid,
          dayOfWeek: day,
          startMinutes: startMinutes,
          endMinutes: endMinutes,
          createdAt: now,
        ),
      );
      existingKeys.add(entryKey);
    }

    if (createdSubjects.isNotEmpty) {
      for (final subject in createdSubjects) {
        await subjectRepository.upsertSubject(subject);
      }
    }
    if (entriesToAdd.isNotEmpty) {
      await timetableRepository.addEntries(entriesToAdd);
    }

    return _ImportResult(
      subjectsAdded: createdSubjects.length,
      entriesAdded: entriesToAdd.length,
    );
  }

  String _dayName(int day) {
    switch (day) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Today';
    }
  }
}

enum _TimetableAction { share, import }

class _ImportResult {
  const _ImportResult({
    required this.subjectsAdded,
    required this.entriesAdded,
  });

  final int subjectsAdded;
  final int entriesAdded;
}

class _TimetableEntryTile extends StatelessWidget {
  const _TimetableEntryTile({
    required this.entry,
    required this.subjectName,
  });

  final TimetableEntryModel entry;
  final String subjectName;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    return Dismissible(
      key: ValueKey('timetable-${entry.uuid}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => const ConfirmationDialog(
            title: 'Delete class?',
            message: 'This will remove the class from your timetable.',
            confirmLabel: 'Delete',
            isDestructive: true,
          ),
        );
        if (confirmed != true) {
          return false;
        }
        await TimetableRepository().deactivateEntry(entry);
        return true;
      },
      background: const SizedBox.shrink(),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: palette.dangerSubtle,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: palette.danger),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Delete',
              style: AppTextStyles.labelMedium(palette)
                  .copyWith(color: palette.danger),
            ),
          ],
        ),
      ),
      child: TimetableEntryCard(
        entry: entry,
        subjectName: subjectName,
      ),
    );
  }
}
