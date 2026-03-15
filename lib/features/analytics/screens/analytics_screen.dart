import 'package:flutter/material.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/data/models/attendance_record_model.dart';
import 'package:bunk_alert/data/models/subject_model.dart';
import 'package:bunk_alert/data/repositories/attendance_repository.dart';
import 'package:bunk_alert/data/repositories/settings_repository.dart';
import 'package:bunk_alert/data/repositories/subject_repository.dart';
import 'package:bunk_alert/domain/entities/attendance_stats_entity.dart';
import 'package:bunk_alert/domain/usecases/calculate_stats_usecase.dart';
import 'package:bunk_alert/features/analytics/widgets/exam_eligibility_card.dart';
import 'package:bunk_alert/features/analytics/widgets/monthly_heatmap.dart';
import 'package:bunk_alert/features/analytics/widgets/risk_subjects_list.dart';
import 'package:bunk_alert/features/analytics/widgets/subject_breakdown_chart.dart';
import 'package:bunk_alert/features/analytics/widgets/total_stats_row.dart';
import 'package:bunk_alert/features/analytics/widgets/weekly_trend_chart.dart';
import 'package:bunk_alert/shared/widgets/app_scaffold.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AttendanceRepository _attendanceRepository = AttendanceRepository();
  final SubjectRepository _subjectRepository = SubjectRepository();
  final CalculateStatsUsecase _statsUsecase = const CalculateStatsUsecase();

  List<SubjectModel> _subjects = const [];
  double? _globalTarget;

  @override
  void initState() {
    super.initState();
    _loadSubjectsAndTarget();
  }

  Future<void> _loadSubjectsAndTarget() async {
    final subjects = await _subjectRepository.getActiveSubjects();
    final globalTarget =
        await SettingsRepository.instance.getGlobalTargetPercentage();
    if (!mounted) {
      return;
    }
    setState(() {
      _subjects = subjects;
      _globalTarget = globalTarget;
    });
  }

  _Totals _calculateTotals(List<AttendanceRecordModel> records) {
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
    final percentage =
        conducted == 0 ? 0 : ((attended / conducted) * 100).round();
    return _Totals(
      attended: attended,
      conducted: conducted,
      percentage: percentage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final globalTarget = _globalTarget ?? 75;

    return AppScaffold(
      body: SafeArea(
        child: StreamBuilder<List<AttendanceRecordModel>>(
          stream: _attendanceRepository.watchAllRecords(),
          builder: (context, snapshot) {
            final records = snapshot.data ?? const [];
            final totals = _calculateTotals(records);
            final stats = _subjects
                .map(
                  (subject) => _statsUsecase.call(
                    subject: subject,
                    records: records,
                    globalTargetPercentage: globalTarget,
                    remainingClasses: subject.expectedTotalClasses ?? 0,
                  ),
                )
                .toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Overview',
                    palette: palette,
                  ),
                ),
                SliverToBoxAdapter(
                  child: TotalStatsRow(
                    totalAttended: totals.attended,
                    totalConducted: totals.conducted,
                    overallPercentage: totals.percentage,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Attendance by Subject',
                    palette: palette,
                  ),
                ),
                SliverToBoxAdapter(
                  child: SubjectBreakdownChart(
                    stats: stats,
                    targetPercentage: globalTarget,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Weekly Trend',
                    palette: palette,
                  ),
                ),
                SliverToBoxAdapter(
                  child: WeeklyTrendChart(
                    records: records,
                    targetPercentage: globalTarget,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Monthly Activity',
                    palette: palette,
                  ),
                ),
                SliverToBoxAdapter(
                  child: MonthlyHeatmap(records: records),
                ),
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'At Risk',
                    palette: palette,
                  ),
                ),
                SliverToBoxAdapter(
                  child: RiskSubjectsList(stats: stats),
                ),
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Exam Eligibility',
                    palette: palette,
                  ),
                ),
                SliverToBoxAdapter(
                  child: ExamEligibilityCard(
                    subjects: _subjects,
                    stats: stats,
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.section),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.palette,
  });

  final String title;
  final AppColorPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.xxl,
        AppSpacing.base,
        AppSpacing.sm,
      ),
      child: Text(
        title,
        style: AppTextStyles.headingSmall(palette),
      ),
    );
  }
}

class _Totals {
  const _Totals({
    required this.attended,
    required this.conducted,
    required this.percentage,
  });

  final int attended;
  final int conducted;
  final int percentage;
}
