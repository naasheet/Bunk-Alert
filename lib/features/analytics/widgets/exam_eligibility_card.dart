import 'package:flutter/material.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/core/utils/bunk_calculator.dart';
import 'package:bunk_alert/data/models/subject_model.dart';
import 'package:bunk_alert/data/repositories/subject_repository.dart';
import 'package:bunk_alert/domain/entities/attendance_stats_entity.dart';

class ExamEligibilityCard extends StatefulWidget {
  const ExamEligibilityCard({
    super.key,
    required this.subjects,
    required this.stats,
  });

  final List<SubjectModel> subjects;
  final List<AttendanceStatsEntity> stats;

  @override
  State<ExamEligibilityCard> createState() => _ExamEligibilityCardState();
}

class _ExamEligibilityCardState extends State<ExamEligibilityCard> {
  final SubjectRepository _subjectRepository = SubjectRepository();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, int?> _overrides = {};
  bool _isExpanded = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final statsMap = {
      for (final stat in widget.stats) stat.subjectUuid: stat,
    };

    var eligibleCount = 0;
    var riskCount = 0;

    for (final subject in widget.subjects) {
      final stat = statsMap[subject.uuid];
      if (stat == null) {
        continue;
      }
      final remaining = _overrides[subject.uuid] ??
          subject.expectedTotalClasses ??
          0;
      final eligibility = BunkCalculator.calculateExamEligibility(
        stat.attended,
        stat.conducted,
        remaining,
        stat.targetPercentage,
      );
      if (eligibility.isEligible) {
        eligibleCount++;
      } else {
        riskCount++;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        child: Container(
          width: double.infinity,
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
                    child: Text(
                      'Exam Eligibility',
                      style: AppTextStyles.labelLarge(palette),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: palette.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '$eligibleCount subjects — Exam Eligible ✓',
                style: AppTextStyles.bodyMedium(palette)
                    .copyWith(color: palette.safe),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '$riskCount subjects — At Risk of Ineligibility ⚠',
                style: AppTextStyles.bodyMedium(palette)
                    .copyWith(color: palette.danger),
              ),
              if (_isExpanded) ...[
                const SizedBox(height: AppSpacing.lg),
                Column(
                  children: widget.subjects.map((subject) {
                    final stat = statsMap[subject.uuid];
                    if (stat == null) {
                      return const SizedBox.shrink();
                    }
                    final controller =
                        _controllers.putIfAbsent(subject.uuid, () {
                      return TextEditingController(
                        text: subject.expectedTotalClasses?.toString() ?? '',
                      );
                    });
                    final remaining = _overrides[subject.uuid] ??
                        subject.expectedTotalClasses ??
                        0;
                    final eligibility = BunkCalculator.calculateExamEligibility(
                      stat.attended,
                      stat.conducted,
                      remaining,
                      stat.targetPercentage,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _SubjectEligibilityRow(
                        subject: subject,
                        remainingClasses: remaining,
                        isEligible: eligibility.isEligible,
                        controller: controller,
                        palette: palette,
                        onChanged: (value) =>
                            _handleRemainingChanged(subject.uuid, value),
                        onSubmitted: (value) =>
                            _saveRemaining(subject.uuid, value),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleRemainingChanged(String subjectId, String value) {
    final parsed = int.tryParse(value);
    setState(() {
      _overrides[subjectId] = parsed;
    });
  }

  Future<void> _saveRemaining(String subjectId, String value) async {
    final parsed = int.tryParse(value);
    await _subjectRepository.updateExpectedTotalClasses(
      subjectId: subjectId,
      expectedTotalClasses: parsed,
    );
  }
}

class _SubjectEligibilityRow extends StatelessWidget {
  const _SubjectEligibilityRow({
    required this.subject,
    required this.remainingClasses,
    required this.isEligible,
    required this.controller,
    required this.palette,
    required this.onChanged,
    required this.onSubmitted,
  });

  final SubjectModel subject;
  final int remainingClasses;
  final bool isEligible;
  final TextEditingController controller;
  final AppColorPalette palette;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final eligibilityText = isEligible ? 'Eligible' : 'At Risk';
    final eligibilityColor =
        isEligible ? palette.safe : palette.danger;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subject.name,
          style: AppTextStyles.labelLarge(palette),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Remaining classes',
                  hintText: remainingClasses == 0 ? 'Enter' : null,
                  isDense: true,
                ),
                onChanged: onChanged,
                onSubmitted: onSubmitted,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              eligibilityText,
              style: AppTextStyles.labelMedium(palette)
                  .copyWith(color: eligibilityColor),
            ),
          ],
        ),
      ],
    );
  }
}
