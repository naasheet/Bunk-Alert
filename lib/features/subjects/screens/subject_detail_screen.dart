
import 'dart:io';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/core/utils/bunk_calculator.dart';
import 'package:bunk_alert/data/models/attendance_record_model.dart';
import 'package:bunk_alert/data/models/subject_model.dart';
import 'package:bunk_alert/data/repositories/attendance_repository.dart';
import 'package:bunk_alert/data/repositories/settings_repository.dart';
import 'package:bunk_alert/data/repositories/subject_repository.dart';
import 'package:bunk_alert/domain/entities/attendance_stats_entity.dart';
import 'package:bunk_alert/domain/usecases/calculate_stats_usecase.dart';
import 'package:bunk_alert/features/social/widgets/share_summary_card.dart';
import 'package:bunk_alert/shared/widgets/app_scaffold.dart';
import 'package:bunk_alert/shared/widgets/primary_button.dart';

class SubjectDetailScreen extends StatefulWidget {
  const SubjectDetailScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  final SubjectRepository _subjectRepository = SubjectRepository();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();
  final CalculateStatsUsecase _statsUsecase = const CalculateStatsUsecase();
  final GlobalKey _shareKey = GlobalKey();

  double? _globalTarget;
  SubjectModel? _subject;
  bool _isSharing = false;
  ShareCardAspect _shareAspect = ShareCardAspect.story;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final globalTarget =
        await SettingsRepository.instance.getGlobalTargetPercentage();
    final subject = await _subjectRepository.getSubjectById(widget.subjectId);
    if (!mounted) {
      return;
    }
    setState(() {
      _globalTarget = globalTarget;
      _subject = subject;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final subject = _subject;
    final globalTarget = _globalTarget;

    if (subject == null || globalTarget == null) {
      return const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppScaffold(
      body: StreamBuilder<List<AttendanceRecordModel>>(
        stream: _attendanceRepository.watchBySubjectUuid(widget.subjectId),
        builder: (context, snapshot) {
          final records = snapshot.data ?? const [];
          final stats = _statsUsecase.call(
            subject: subject,
            records: records,
            globalTargetPercentage: globalTarget,
            remainingClasses: 0,
          );

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 280,
                backgroundColor: palette.background,
                title: Text(subject.name),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: _isSharing ? null : _showShareFormatSheet,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _SubjectHeader(
                    subjectName: subject.name,
                    percent: stats.currentPercentage,
                    attended: stats.attended,
                    conducted: stats.conducted,
                    target: stats.targetPercentage,
                    expectedTotalClasses: subject.expectedTotalClasses,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.screenPadding,
                  child: Row(
                    children: [
                      Expanded(
                        child: _PrimaryStatChip(
                          needed: stats.classesNeededToReachTarget,
                          safeSkips: stats.classesSafeToSkip,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _ExamEligibilityChip(
                          eligibility: stats.examEligibility,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.base,
                    right: AppSpacing.base,
                    top: AppSpacing.md,
                  ),
                  child: _SkipImpactPreview(
                    attended: stats.attended,
                    conducted: stats.conducted,
                    targetPercent: stats.targetPercentage,
                  ),
                ),
              ),
              if (stats.classesNeededToReachTarget > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.base,
                      right: AppSpacing.base,
                      top: AppSpacing.md,
                    ),
                    child: _RecoveryPlanCard(
                      needed: stats.classesNeededToReachTarget,
                      predicted: stats.recoveryPlan.predictedPercentage,
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.base,
                    right: AppSpacing.base,
                    top: AppSpacing.lg,
                    bottom: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'History',
                        style: AppTextStyles.headingSmall(palette),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _showAddPastEntryBottomSheet(
                          context,
                          widget.subjectId,
                        ),
                        child: const Text('Add Manual Entry'),
                      ),
                    ],
                  ),
                ),
              ),
              ..._buildHistorySlivers(records),
              SliverToBoxAdapter(
                child: Offstage(
                  offstage: true,
                  child: RepaintBoundary(
                    key: _shareKey,
                    child: ShareSummaryCard(
                      data: _buildShareCardData(records),
                      aspect: _shareAspect,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.section),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildHistorySlivers(List<AttendanceRecordModel> records) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    if (records.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Text(
              'No entries yet.',
              style: AppTextStyles.bodySmall(palette),
            ),
          ),
        ),
      ];
    }

    final sorted = records.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final grouped = groupBy(
      sorted,
      (AttendanceRecordModel record) =>
          DateFormat('MMMM yyyy').format(record.date),
    );

    final items = <_HistoryListItem>[];
    for (final entry in grouped.entries) {
      items.add(_HistoryListItem.header(entry.key));
      for (final record in entry.value) {
        items.add(_HistoryListItem.record(record));
      }
    }

    return [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            if (item.isHeader) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  item.header ?? '',
                  style: AppTextStyles.labelSmall(palette)
                      .copyWith(letterSpacing: 1.1),
                ),
              );
            }
            final record = item.record!;
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.sm,
              ),
              child: _HistoryRow(record: record),
            );
          },
          childCount: items.length,
        ),
      ),
    ];
  }

  ShareSummaryCardData _buildShareCardData(
    List<AttendanceRecordModel> records,
  ) {
    final subjectName = _subject?.name ?? 'Subject';

    var attended = 0;
    var conducted = 0;
    for (final record in records) {
      switch (record.status) {
        case 'present':
          attended++;
          conducted++;
        case 'absent':
          conducted++;
        case 'cancelled':
          break;
      }
    }
    final currentPercentage =
        conducted == 0 ? 0.0 : (attended / conducted) * 100;

    return ShareSummaryCardData(
      appName: 'Bunk Alert',
      subjectName: subjectName,
      percentage: currentPercentage,
    );
  }

  Future<void> _showShareFormatSheet() async {
    if (_isSharing) {
      return;
    }
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    var selected = _shareAspect;

    final result = await showModalBottomSheet<ShareCardAspect>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                    'Share card',
                    style: AppTextStyles.headingSmall(palette),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Choose a format before sharing.',
                    style: AppTextStyles.bodySmall(palette),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _ShareFormatOption(
                          label: 'Story 9:16',
                          aspect: ShareCardAspect.story,
                          isSelected:
                              selected == ShareCardAspect.story,
                          onTap: () => setSheetState(
                            () => selected = ShareCardAspect.story,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _ShareFormatOption(
                          label: 'Post 1:1',
                          aspect: ShareCardAspect.square,
                          isSelected:
                              selected == ShareCardAspect.square,
                          onTap: () => setSheetState(
                            () => selected = ShareCardAspect.square,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: 'Share',
                    onPressed: () =>
                        Navigator.of(sheetContext).pop(selected),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }
    setState(() {
      _shareAspect = result;
    });
    await _shareAttendanceCard();
  }

  Future<void> _shareAttendanceCard() async {
    if (_isSharing) {
      return;
    }
    setState(() {
      _isSharing = true;
    });

    await Future.delayed(const Duration(milliseconds: 1100));
    final boundary = _shareKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      setState(() {
        _isSharing = false;
      });
      return;
    }
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      setState(() {
        _isSharing = false;
      });
      return;
    }
    final pngBytes = bytes.buffer.asUint8List();
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/attendance_${widget.subjectId}.png',
    );
    await file.writeAsBytes(pngBytes, flush: true);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Attendance summary',
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isSharing = false;
    });
  }
}

class _SubjectHeader extends StatelessWidget {
  const _SubjectHeader({
    required this.subjectName,
    required this.percent,
    required this.attended,
    required this.conducted,
    required this.target,
    required this.expectedTotalClasses,
  });

  final String subjectName;
  final double percent;
  final int attended;
  final int conducted;
  final double target;
  final int? expectedTotalClasses;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    return Container(
      padding: const EdgeInsets.only(
        left: AppSpacing.base,
        right: AppSpacing.base,
        bottom: AppSpacing.lg,
      ),
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AttendanceRing(
              percentage: percent,
              color: palette.chartLine,
              size: 120,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              subjectName,
              style: AppTextStyles.headingLarge(palette),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _buildAttendanceLine(),
              style: AppTextStyles.bodyMedium(palette).copyWith(
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Target ${target.toStringAsFixed(0)}%',
              style: AppTextStyles.caption(palette),
            ),
          ],
        ),
      ),
    );
  }

  String _buildAttendanceLine() {
    final total = (expectedTotalClasses ?? 0) > 0
        ? expectedTotalClasses!
        : conducted;
    if ((expectedTotalClasses ?? 0) > 0) {
      return '$attended attended / $total expected';
    }
    return '$attended attended / $total conducted';
  }
}

class AttendanceRing extends StatelessWidget {
  const AttendanceRing({
    super.key,
    required this.percentage,
    required this.color,
    this.size = 56,
  });

  final double percentage;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final percent = percentage.clamp(0, 100).toDouble();

    Widget buildRing(double progress) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: size >= 100 ? 10 : 6,
              backgroundColor: palette.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            Text(
              '${percent.round()}%',
              style: AppTextStyles.labelMedium(palette).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Animate(
      effects: [
        CustomEffect(
          duration: 1000.ms,
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return buildRing((percent / 100) * value);
          },
        ),
      ],
      child: buildRing(percent / 100),
    );
  }
}

class _PrimaryStatChip extends StatelessWidget {
  const _PrimaryStatChip({
    required this.needed,
    required this.safeSkips,
  });

  final int needed;
  final int safeSkips;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final isBelow = needed > 0;
    final label =
        isBelow ? 'Need $needed More' : 'Can Skip $safeSkips';
    final color = isBelow ? palette.danger : palette.safe;
    final background =
        isBelow ? palette.dangerSubtle : palette.safeSubtle;

    return _StatChip(
      label: label,
      color: color,
      background: background,
    );
  }
}

class _ExamEligibilityChip extends StatelessWidget {
  const _ExamEligibilityChip({required this.eligibility});

  final ExamEligibility eligibility;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final label = eligibility.isEligible
        ? 'Eligible'
        : 'Short ${eligibility.deficitClasses}';
    final color = eligibility.isEligible ? palette.safe : palette.danger;
    final background = eligibility.isEligible
        ? palette.safeSubtle
        : palette.dangerSubtle;

    return _StatChip(
      label: label,
      color: color,
      background: background,
      alignCenter: true,
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.color,
    required this.background,
    this.alignCenter = false,
  });

  final String label;
  final Color color;
  final Color background;
  final bool alignCenter;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      alignment: alignCenter ? Alignment.center : Alignment.centerLeft,
      child: Text(
        label,
        style: AppTextStyles.labelMedium(palette).copyWith(color: color),
      ),
    );
  }
}

class _SkipImpactPreview extends StatefulWidget {
  const _SkipImpactPreview({
    required this.attended,
    required this.conducted,
    required this.targetPercent,
  });

  final int attended;
  final int conducted;
  final double targetPercent;

  @override
  State<_SkipImpactPreview> createState() => _SkipImpactPreviewState();
}

class _SkipImpactPreviewState extends State<_SkipImpactPreview> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final predictions = List.generate(
      3,
      (index) => BunkCalculator.predictAfterSkipping(
        widget.attended,
        widget.conducted,
        index + 1,
        widget.targetPercent,
      ),
    );
    final first = predictions.first;

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodyMedium(palette)
                          .copyWith(color: palette.textPrimary),
                      children: [
                        const TextSpan(text: 'Skip 1 more -> '),
                        TextSpan(
                          text:
                              '${first.predictedPercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: first.isAboveTarget
                                ? palette.safe
                                : palette.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: palette.textTertiary,
                ),
              ],
            ),
            Animate(
              target: _isExpanded ? 1 : 0,
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
                  begin: const Offset(1, 0.9),
                  end: const Offset(1, 1),
                  alignment: Alignment.topCenter,
                ),
                VisibilityEffect(maintain: false),
              ],
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Column(
                  children: [
                    for (var i = 0; i < predictions.length; i++)
                      _SkipTableRow(
                        label: 'Skip ${i + 1}',
                        percent: predictions[i].predictedPercentage,
                        isAbove: predictions[i].isAboveTarget,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkipTableRow extends StatelessWidget {
  const _SkipTableRow({
    required this.label,
    required this.percent,
    required this.isAbove,
  });

  final String label;
  final double percent;
  final bool isAbove;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.caption(palette),
          ),
          const Spacer(),
          Text(
            '${percent.toStringAsFixed(1)}%',
            style: AppTextStyles.labelMedium(palette).copyWith(
              color: isAbove ? palette.safe : palette.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryPlanCard extends StatelessWidget {
  const _RecoveryPlanCard({
    required this.needed,
    required this.predicted,
  });

  final int needed;
  final double predicted;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: palette.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Attend next $needed classes -> reach '
              '${predicted.toStringAsFixed(1)}%',
              style: AppTextStyles.bodyMedium(palette),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.record});

  final AttendanceRecordModel record;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final dateFormat = DateFormat('MMM d, y');
    final statusLabel = _statusLabel(record.status);
    final statusColor = _statusColor(record.status, palette);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: AppTextStyles.labelMedium(palette)
                      .copyWith(color: palette.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  dateFormat.format(record.date),
                  style: AppTextStyles.caption(palette),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryListItem {
  const _HistoryListItem._({this.header, this.record});

  factory _HistoryListItem.header(String label) =>
      _HistoryListItem._(header: label);
  factory _HistoryListItem.record(AttendanceRecordModel record) =>
      _HistoryListItem._(record: record);

  final String? header;
  final AttendanceRecordModel? record;

  bool get isHeader => header != null;
}

Future<void> _showAddPastEntryBottomSheet(
  BuildContext context,
  String subjectId,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return _AddPastEntrySheet(subjectId: subjectId);
    },
  );
}

class _AddPastEntrySheet extends StatefulWidget {
  const _AddPastEntrySheet({required this.subjectId});

  final String subjectId;

  @override
  State<_AddPastEntrySheet> createState() => _AddPastEntrySheetState();
}

class _AddPastEntrySheetState extends State<_AddPastEntrySheet> {
  final AttendanceRepository _attendanceRepository = AttendanceRepository();

  DateTime _selectedDate = DateTime.now();
  String? _status;
  bool _isSaving = false;

  bool get _canSave => _status != null && !_isSaving;

  Future<void> _pickDate() async {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = ThemeData(
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: palette.chartLine,
        onPrimary: palette.background,
        secondary: palette.chartLine,
        onSecondary: palette.background,
        surface: palette.surface,
        onSurface: palette.textPrimary,
        error: palette.danger,
        onError: palette.background,
      ),
      dialogBackgroundColor: palette.surface,
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: palette.textPrimary),
      ),
    );

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: theme,
          child: child!,
        );
      },
    );

    if (picked == null) {
      return;
    }
    setState(() {
      _selectedDate = picked;
    });
  }

  Future<void> _save() async {
    final status = _status;
    if (status == null) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    await _attendanceRepository.markAttendance(
      subjectUuid: widget.subjectId,
      status: status,
      date: _selectedDate,
      timetableEntryUuid: null,
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final dateFormat = DateFormat('MMM d, y');

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
                'Pick a date',
                style: AppTextStyles.labelSmall(palette),
              ),
              const SizedBox(height: AppSpacing.sm),
              InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                onTap: _pickDate,
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
                  child: Text(
                    dateFormat.format(_selectedDate),
                    style: AppTextStyles.headingSmall(palette),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Status',
                style: AppTextStyles.labelSmall(palette),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _StatusChip(
                    label: 'Present',
                    isSelected: _status == 'present',
                    onTap: () => setState(() => _status = 'present'),
                  ),
                  _StatusChip(
                    label: 'Absent',
                    isSelected: _status == 'absent',
                    onTap: () => setState(() => _status = 'absent'),
                  ),
                  _StatusChip(
                    label: 'Cancelled',
                    isSelected: _status == 'cancelled',
                    onTap: () => setState(() => _status = 'cancelled'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Add Entry',
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({
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

String _statusLabel(String status) {
  switch (status) {
    case 'present':
      return 'Present';
    case 'absent':
      return 'Absent';
    case 'cancelled':
      return 'Cancelled';
    default:
      return status;
  }
}

Color _statusColor(String status, AppColorPalette palette) {
  switch (status) {
    case 'present':
      return palette.safe;
    case 'absent':
      return palette.danger;
    case 'cancelled':
      return palette.warning;
    default:
      return palette.textTertiary;
  }
}

class _ShareFormatOption extends StatelessWidget {
  const _ShareFormatOption({
    required this.label,
    required this.aspect,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final ShareCardAspect aspect;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final background =
        isSelected ? palette.surfaceElevated : palette.surface;
    final borderColor = isSelected ? palette.chartLine : palette.border;
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: aspect == ShareCardAspect.story ? 9 / 16 : 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      palette.surfaceElevated,
                      palette.safeSubtle,
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.labelMedium(palette),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
