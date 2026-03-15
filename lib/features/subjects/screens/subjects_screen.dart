import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bunk_alert/core/router/route_names.dart';
import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/data/models/attendance_record_model.dart';
import 'package:bunk_alert/data/models/subject_model.dart';
import 'package:bunk_alert/data/repositories/attendance_repository.dart';
import 'package:bunk_alert/data/repositories/subject_repository.dart';
import 'package:bunk_alert/domain/entities/attendance_stats_entity.dart';
import 'package:bunk_alert/domain/usecases/calculate_stats_usecase.dart';
import 'package:bunk_alert/domain/usecases/mark_attendance_usecase.dart';
import 'package:bunk_alert/shared/providers/attendance_records_provider.dart';
import 'package:bunk_alert/shared/providers/settings_providers.dart';
import 'package:bunk_alert/shared/providers/subjects_stream_provider.dart';
import 'package:bunk_alert/shared/utils/error_message_mapper.dart';
import 'package:bunk_alert/shared/widgets/app_scaffold.dart';
import 'package:bunk_alert/shared/widgets/confirmation_dialog.dart';
import 'package:bunk_alert/shared/widgets/error_state_widget.dart';
import 'package:bunk_alert/shared/widgets/loading_indicator.dart';

class SubjectsScreen extends ConsumerStatefulWidget {
  const SubjectsScreen({super.key});

  @override
  ConsumerState<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends ConsumerState<SubjectsScreen> {
  final CalculateStatsUsecase _statsUsecase = const CalculateStatsUsecase();
  final MarkAttendanceUsecase _markAttendanceUsecase =
      MarkAttendanceUsecase();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();
  final SubjectRepository _subjectRepository = SubjectRepository();
  final ScrollController _scrollController = ScrollController();

  bool _isFabExpanded = true;
  bool _hasAnimated = false;
  final Set<String> _markingSubjects = <String>{};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final shouldExpand = _scrollController.offset <= 12;
    if (shouldExpand == _isFabExpanded) {
      return;
    }
    setState(() {
      _isFabExpanded = shouldExpand;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final subjectsAsync = ref.watch(subjectsStreamProvider);
    final recordsAsync = ref.watch(attendanceRecordsStreamProvider);
    final globalTargetAsync = ref.watch(globalTargetProvider);
    final isLoading = subjectsAsync.isLoading ||
        recordsAsync.isLoading ||
        globalTargetAsync.isLoading;
    final Object? error = subjectsAsync.error ??
        recordsAsync.error ??
        globalTargetAsync.error;
    final bool hasError = error != null;

    return AppScaffold(
      floatingActionButton: _AnimatedFab(
        isExpanded: _isFabExpanded,
        onPressed: () => context.go(RouteNames.addSubject),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            title: const Text('Subjects'),
            pinned: true,
            floating: false,
            backgroundColor: palette.background,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: Text(
                'Track attendance by subject and stay on target.',
                style: AppTextStyles.bodySmall(palette),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.lg),
          ),
          if (hasError)
            SliverFillRemaining(
              child: ErrorStateWidget(
                message: friendlyErrorMessage(error),
                onRetry: () {
                  ref.invalidate(subjectsStreamProvider);
                  ref.invalidate(attendanceRecordsStreamProvider);
                  ref.invalidate(globalTargetProvider);
                },
              ),
            )
          else if (isLoading)
            const SliverFillRemaining(
              child: Center(child: LoadingIndicator()),
            )
          else
            ..._buildSubjectSlivers(
              context: context,
              palette: palette,
              subjects: subjectsAsync.value ?? const <SubjectModel>[],
              records:
                  recordsAsync.value ?? const <AttendanceRecordModel>[],
              globalTarget: globalTargetAsync.value ?? 75,
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.section),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSubjectSlivers({
    required BuildContext context,
    required AppColorPalette palette,
    required List<SubjectModel> subjects,
    required List<AttendanceRecordModel> records,
    required double globalTarget,
  }) {
    final stats = subjects
        .map(
          (subject) => _statsUsecase.call(
            subject: subject,
            records: records,
            globalTargetPercentage: globalTarget,
            remainingClasses: 0,
          ),
        )
        .toList();
    final subjectMap = {
      for (final subject in subjects) subject.uuid: subject,
    };

    if (!_hasAnimated && stats.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _hasAnimated = true;
        });
      });
    }

    final playEntrance = !_hasAnimated;

    if (stats.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'No subjects yet.',
                  style: AppTextStyles.headingSmall(palette),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Add your first subject to start tracking attendance.',
                  style: AppTextStyles.bodySmall(palette),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go(RouteNames.addSubject),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Subject'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: AppSpacing.screenPadding,
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final entry = stats[index];
              final rawAbsent = entry.conducted - entry.attended;
              final absentCount = rawAbsent < 0 ? 0 : rawAbsent;
              final expectedTotal =
                  subjectMap[entry.subjectUuid]?.expectedTotalClasses;
              final subjectCard = Dismissible(
                key: ValueKey('subject-${entry.subjectUuid}'),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    context.push(
                      '${RouteNames.subjects}/${entry.subjectUuid}/edit',
                    );
                  }
                  return false;
                },
                background: const SizedBox.shrink(),
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.cardRadius),
                    border:
                        Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.edit_outlined,
                        color: Color(0xFFEDEDED),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Edit',
                        style: const TextStyle(
                          color: Color(0xFFEDEDED),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _SubjectCard(
                    stats: entry,
                    animateCharts: playEntrance,
                    isMarking:
                        _markingSubjects.contains(entry.subjectUuid),
                    presentCount: entry.attended,
                    absentCount: absentCount,
                    expectedTotalClasses: expectedTotal,
                    onIncPresent: () => _quickAdjust(
                      entry,
                      records,
                      status: 'present',
                      increment: true,
                    ),
                    onDecPresent: () => _quickAdjust(
                      entry,
                      records,
                      status: 'present',
                      increment: false,
                    ),
                    onIncAbsent: () => _quickAdjust(
                      entry,
                      records,
                      status: 'absent',
                      increment: true,
                    ),
                    onDecAbsent: () => _quickAdjust(
                      entry,
                      records,
                      status: 'absent',
                      increment: false,
                    ),
                    onOpenActions: () => _showSubjectActions(entry),
                    onTap: () => context.go(
                      '${RouteNames.subjects}/${entry.subjectUuid}',
                    ),
                  ),
                ),
              );
              if (!playEntrance) {
                return subjectCard;
              }
              final delay = Duration(milliseconds: 40 * index);
              return subjectCard
                  .animate(delay: delay)
                  .fadeIn(
                    duration: 300.ms,
                    curve: Curves.easeOut,
                  )
                  .slideY(
                    begin: 0.08,
                    end: 0,
                    duration: 300.ms,
                    curve: Curves.easeOutCubic,
                  );
            },
            childCount: stats.length,
          ),
        ),
      ),
    ];
  }

  Future<void> _quickAdjust(
    AttendanceStatsEntity stats,
    List<AttendanceRecordModel> records, {
    required String status,
    required bool increment,
  }) async {
    if (_markingSubjects.contains(stats.subjectUuid)) {
      return;
    }
    setState(() {
      _markingSubjects.add(stats.subjectUuid);
    });
    try {
      if (increment) {
        final date = _nextManualDate(stats.subjectUuid, records);
        await _markAttendanceUsecase.call(
          subjectUuid: stats.subjectUuid,
          status: status,
          date: date,
          note: 'manual_adjustment',
        );
      } else {
        final record = _latestManualRecord(
          stats.subjectUuid,
          records,
          status: status,
        );
        if (record == null) {
          _showSnack('No manual $status records to remove.');
          return;
        }
        await _attendanceRepository.deleteRecord(record);
      }
      if (!mounted) {
        return;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack(friendlyErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _markingSubjects.remove(stats.subjectUuid);
        });
      }
    }
  }

  DateTime _nextManualDate(
    String subjectUuid,
    List<AttendanceRecordModel> records,
  ) {
    final usedDates = records
        .where((record) => record.subjectUuid == subjectUuid)
        .map((record) => AttendanceRecordModel.normalizeDate(record.date))
        .toSet();
    final today = AttendanceRecordModel.normalizeDate(DateTime.now());
    for (var i = 0; i < 3650; i++) {
      final candidate = today.subtract(Duration(days: i));
      if (!usedDates.contains(candidate)) {
        return candidate;
      }
    }
    return today;
  }

  AttendanceRecordModel? _latestManualRecord(
    String subjectUuid,
    List<AttendanceRecordModel> records, {
    required String status,
  }) {
    final manual = records
        .where(
          (record) =>
              record.subjectUuid == subjectUuid &&
              record.status == status &&
              record.note == 'manual_adjustment',
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return manual.isEmpty ? null : manual.first;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showSubjectActions(AttendanceStatsEntity stats) async {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ActionTile(
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push(
                    '${RouteNames.subjects}/${stats.subjectUuid}/edit',
                  );
                },
              ),
              _ActionTile(
                icon: Icons.delete_outline,
                label: 'Delete',
                isDestructive: true,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _confirmDelete(stats);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(AttendanceStatsEntity stats) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (_) => const ConfirmationDialog(
            title: 'Delete subject?',
            message:
                'This will remove the subject, timetable entries, and attendance history.',
            confirmLabel: 'Delete',
            isDestructive: true,
          ),
        ) ??
        false;

    if (!shouldDelete) {
      return;
    }

    try {
      await _subjectRepository.deleteSubject(
        subjectId: stats.subjectUuid,
      );
      if (!mounted) {
        return;
      }
      _showSnack('${stats.subjectName} deleted.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack(friendlyErrorMessage(error));
    }
  }
}

class _AnimatedFab extends StatelessWidget {
  const _AnimatedFab({
    required this.isExpanded,
    required this.onPressed,
  });

  final bool isExpanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final label = Text(
      'Add Subject',
      style: Theme.of(context)
          .textTheme
          .labelLarge
          ?.copyWith(color: palette.background),
    );

    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: palette.chartLine,
      foregroundColor: palette.background,
      icon: const Icon(Icons.add),
      label: Animate(
        target: isExpanded ? 1 : 0,
        effects: [
          FadeEffect(
            duration: 240.ms,
            curve: Curves.easeOut,
            begin: 0,
            end: 1,
          ),
          ScaleEffect(
            duration: 240.ms,
            curve: Curves.easeOut,
            begin: const Offset(0.9, 1),
            end: const Offset(1, 1),
            alignment: Alignment.centerLeft,
          ),
          VisibilityEffect(
            maintain: false,
          ),
        ],
        child: label,
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.stats,
    required this.animateCharts,
    required this.onTap,
    required this.isMarking,
    required this.presentCount,
    required this.absentCount,
    required this.expectedTotalClasses,
    required this.onIncPresent,
    required this.onDecPresent,
    required this.onIncAbsent,
    required this.onDecAbsent,
    required this.onOpenActions,
  });

  final AttendanceStatsEntity stats;
  final bool animateCharts;
  final VoidCallback onTap;
  final bool isMarking;
  final int presentCount;
  final int absentCount;
  final int? expectedTotalClasses;
  final VoidCallback onIncPresent;
  final VoidCallback onDecPresent;
  final VoidCallback onIncAbsent;
  final VoidCallback onDecAbsent;
  final VoidCallback onOpenActions;

  @override
  Widget build(BuildContext context) {
    final percent = stats.currentPercentage.clamp(0, 100).toDouble();
    final total = (expectedTotalClasses ?? 0) > 0
        ? expectedTotalClasses!
        : stats.conducted;
    final hasData = stats.conducted > 0;
    final displayPercent = hasData ? percent : 0.0;
    final isAtRisk = hasData && stats.currentPercentage < stats.targetPercentage;
    const cardBackground = Color(0xFF111111);
    final borderColor =
        isAtRisk ? const Color(0xFF2A1818) : const Color(0xFF1E1E1E);
    const mutedText = Color(0xFF8A8A8A);
    const lightText = Color(0xFFEDEDED);
    final percentColor = hasData
        ? (isAtRisk ? const Color(0xFFD95555) : const Color(0xFF4CAF72))
        : const Color(0xFF8A8A8A);
    final badge = _BunkBadge.fromStats(stats);

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      onTap: onTap,
      onLongPress: onOpenActions,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stats.subjectName,
                        style: const TextStyle(
                          color: lightText,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Attended ${stats.attended} of $total',
                        style: const TextStyle(
                          color: mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${displayPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: percentColor,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _StatusPill(
                      label: badge.label,
                      textColor: badge.textColor,
                      background: badge.background,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SubjectProgressBar(
              percent: displayPercent,
              color: percentColor,
              animate: animateCharts,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _CounterGroup(
                    label: 'Present',
                    count: presentCount,
                    plusColor: const Color(0xFF4CAF72),
                    minusColor: const Color(0xFF8A8A8A),
                    isBusy: isMarking,
                    onIncrement: onIncPresent,
                    onDecrement: onDecPresent,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _CounterGroup(
                    label: 'Absent',
                    count: absentCount,
                    plusColor: const Color(0xFFD95555),
                    minusColor: const Color(0xFF8A8A8A),
                    isBusy: isMarking,
                    onIncrement: onIncAbsent,
                    onDecrement: onDecAbsent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectProgressBar extends StatelessWidget {
  const _SubjectProgressBar({
    required this.percent,
    required this.color,
    required this.animate,
  });

  final double percent;
  final Color color;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final base = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fillWidth = (percent / 100).clamp(0.0, 1.0) * width;
        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Container(
              height: 8,
              width: fillWidth,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        );
      },
    );
    if (!animate) {
      return base;
    }
    return Animate(
      effects: [
        CustomEffect(
          duration: 1000.ms,
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final fillWidth =
                    ((percent / 100).clamp(0.0, 1.0) * value) * width;
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Container(
                      height: 8,
                      width: fillWidth,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
      child: base,
    );
  }
}

class _CounterGroup extends StatelessWidget {
  const _CounterGroup({
    required this.label,
    required this.count,
    required this.plusColor,
    required this.minusColor,
    required this.isBusy,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String label;
  final int count;
  final Color plusColor;
  final Color minusColor;
  final bool isBusy;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: isBusy,
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8A8A8A),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          _StepperPill(
            count: count,
            plusColor: plusColor,
            minusColor: minusColor,
            onIncrement: isBusy ? null : onIncrement,
            onDecrement: isBusy ? null : onDecrement,
          ),
        ],
      ),
    );
  }
}

class _StepperPill extends StatelessWidget {
  const _StepperPill({
    required this.count,
    required this.plusColor,
    required this.minusColor,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int count;
  final Color plusColor;
  final Color minusColor;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove,
            color: minusColor,
            onPressed: onDecrement,
          ),
          SizedBox(
            width: 36,
            child: Center(
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Color(0xFFEDEDED),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            color: plusColor,
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatefulWidget {
  const _StepperButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  State<_StepperButton> createState() => _StepperButtonState();
}

class _StepperButtonState extends State<_StepperButton> {
  Timer? _repeatTimer;

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  void _startRepeating() {
    if (widget.onPressed == null) {
      return;
    }
    widget.onPressed?.call();
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(
      const Duration(milliseconds: 120),
      (_) => widget.onPressed?.call(),
    );
  }

  void _stopRepeating() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (_) => _startRepeating(),
      onLongPressEnd: (_) => _stopRepeating(),
      onLongPressCancel: _stopRepeating,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: widget.onPressed,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            widget.icon,
            size: 18,
            color: widget.onPressed == null
                ? widget.color.withOpacity(0.35)
                : widget.color,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.textColor,
    required this.background,
  });

  final String label;
  final Color textColor;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BunkBadge {
  const _BunkBadge({
    required this.label,
    required this.textColor,
    required this.background,
  });

  final String label;
  final Color textColor;
  final Color background;

  static _BunkBadge fromStats(AttendanceStatsEntity stats) {
    if (stats.conducted == 0) {
      return const _BunkBadge(
        label: 'No data yet',
        textColor: Color(0xFF8A8A8A),
        background: Color(0xFF1A1A1A),
      );
    }
    if (stats.classesNeededToReachTarget > 0) {
      return _BunkBadge(
        label: 'Attend ${stats.classesNeededToReachTarget} more',
        textColor: const Color(0xFFD95555),
        background: const Color(0xFF2A1818),
      );
    }
    final skips = stats.classesSafeToSkip < 0 ? 0 : stats.classesSafeToSkip;
    return _BunkBadge(
      label: 'Can skip $skips',
      textColor: const Color(0xFF4CAF72),
      background: const Color(0xFF132318),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final color = isDestructive ? palette.danger : palette.textPrimary;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: AppTextStyles.bodyLarge(palette)
            .copyWith(color: color, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }
}
