import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'package:bunk_alert/core/router/route_names.dart';
import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/data/models/attendance_record_model.dart';
import 'package:bunk_alert/data/models/subject_model.dart';
import 'package:bunk_alert/data/repositories/attendance_repository.dart';
import 'package:bunk_alert/data/repositories/settings_repository.dart';
import 'package:bunk_alert/data/repositories/subject_repository.dart';
import 'package:bunk_alert/data/repositories/timetable_repository.dart';
import 'package:bunk_alert/domain/entities/attendance_stats_entity.dart';
import 'package:bunk_alert/domain/usecases/calculate_stats_usecase.dart';
import 'package:bunk_alert/features/dashboard/widgets/overall_stat_header.dart';
import 'package:bunk_alert/features/dashboard/widgets/today_class_card.dart';
import 'package:bunk_alert/shared/auth/app_auth.dart';
import 'package:bunk_alert/shared/widgets/app_scaffold.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SubjectRepository _subjectRepository = SubjectRepository();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();
  final TimetableRepository _timetableRepository = TimetableRepository();
  final CalculateStatsUsecase _statsUsecase = const CalculateStatsUsecase();

  List<SubjectModel> _subjects = const [];
  List<TodayClass> _todayClasses = const [];
  List<AttendanceStatsEntity> _subjectStats = const [];
  double _overallPercentage = 0;
  double _overallTarget = 75;
  int _overallConducted = 0;
  String _firstName = 'there';
  int _atRiskCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final globalTarget =
        await SettingsRepository.instance.getGlobalTargetPercentage();
    final subjects = await _subjectRepository.getActiveSubjects();
    final records = await _attendanceRepository.getAllRecords();
    final pending = await _attendanceRepository.getPendingSyncRecords();
    final hasConnection =
        await InternetConnectionChecker.instance.hasConnection;
    final todayEntries =
        await _timetableRepository.getByDayOfWeek(DateTime.now().weekday);

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
    final atRiskCount = stats
        .where(
          (entry) =>
              entry.conducted > 0 &&
              entry.currentPercentage < entry.targetPercentage,
        )
        .length;

    final subjectMap = {
      for (final subject in subjects) subject.uuid: subject
    };
    final statsMap = {
      for (final stat in stats) stat.subjectUuid: stat,
    };

    final now = DateTime.now();
    final todayDate = AttendanceRecordModel.normalizeDate(now);
    final nowMinutes = now.hour * 60 + now.minute;
    final todayRecordMap = <String, String>{};
    for (final record in records) {
      final entryId = record.timetableEntryUuid;
      if (entryId != null && record.date == todayDate) {
        todayRecordMap[entryId] = record.status;
      }
    }

    final todayClasses = todayEntries.map((entry) {
      final subject = subjectMap[entry.subjectUuid];
      final stat = statsMap[entry.subjectUuid];
      final selectedStatus = todayRecordMap[entry.uuid];
      final isMarked = selectedStatus != null;
      final isPast = nowMinutes > entry.endMinutes;
      return TodayClass(
        subjectUuid: entry.subjectUuid,
        timetableEntryUuid: entry.uuid,
        subjectName: subject?.name ?? 'Subject',
        startMinutes: entry.startMinutes,
        endMinutes: entry.endMinutes,
        needsAttention: isPast && !isMarked,
        selectedStatus: selectedStatus,
        attended: stat?.attended ?? 0,
        conducted: stat?.conducted ?? 0,
        targetPercentage: stat?.targetPercentage ?? globalTarget,
      );
    }).toList();

    final overall = _calculateOverallSummary(records);
    final firstName = _extractFirstName(
      AppAuth.currentUser?.displayName,
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _subjects = subjects;
      _todayClasses = todayClasses;
      _subjectStats = stats;
      _overallPercentage = overall.percentage;
      _overallConducted = overall.conducted;
      _overallTarget = globalTarget;
      _firstName = firstName;
      _atRiskCount = atRiskCount;
      _isLoading = false;
    });
  }

  bool get _hasRisk => _atRiskCount > 0;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final todayLabel = _buildTodayLabel();

    return AppScaffold(
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                SliverToBoxAdapter(
                  child: OverallStatHeader(
                    overallPercentage: _overallPercentage,
                    targetPercentage: _overallTarget,
                    hasData: _overallConducted > 0,
                  firstName: _firstName,
                  isLoading: _isLoading,
                ),
              ),
              if (_hasRisk)
                SliverToBoxAdapter(
                  child: _RiskInlineIndicator(
                    count: _atRiskCount,
                    onTap: () => context.go(RouteNames.subjects),
                  ),
                ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SectionHeaderDelegate(
                  child: Container(
                    color: palette.background,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      todayLabel,
                      style: AppTextStyles.labelSmall(palette)
                          .copyWith(letterSpacing: 1.2),
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final classItem = _todayClasses[index];
                    return TodayClassCard(
                      classItem: classItem,
                      onMarked: _loadData,
                    );
                  },
                  childCount: _todayClasses.length,
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.section),
              ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildTodayLabel() {
    final now = DateTime.now();
    final formatted = DateFormat('EEE, MMM d').format(now).toUpperCase();
    return 'TODAY - $formatted';
  }

  _OverallSummary _calculateOverallSummary(
    List<AttendanceRecordModel> records,
  ) {
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
    if (conducted == 0) {
      return const _OverallSummary(percentage: 0, conducted: 0);
    }
    return _OverallSummary(
      percentage: (attended / conducted) * 100,
      conducted: conducted,
    );
  }

  String _extractFirstName(String? displayName) {
    final name = displayName?.trim();
    if (name == null || name.isEmpty) {
      return 'there';
    }
    return name.split(RegExp(r'\s+')).first;
  }

  Future<void> _refresh() async {
    try {
      await AppAuth.currentUser?.reload();
    } catch (_) {}
    await _loadData();
  }

}

class _OverallSummary {
  const _OverallSummary({
    required this.percentage,
    required this.conducted,
  });

  final double percentage;
  final int conducted;
}

class _RiskInlineIndicator extends StatelessWidget {
  const _RiskInlineIndicator({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final noun = count == 1 ? 'subject' : 'subjects';
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: palette.danger,
                width: 2,
              ),
            ),
          ),
          child: Text(
            '$count $noun at risk · tap to see recovery plans.',
            style: AppTextStyles.bodySmall(palette)
                .copyWith(color: palette.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SectionHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 48.0;

  @override
  double get maxExtent => 48.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(
      height: maxExtent,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _SectionHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
