import 'package:bunk_alert/core/utils/bunk_calculator.dart';
import 'package:bunk_alert/core/utils/risk_calculator.dart';

class AttendanceStatsEntity {
  AttendanceStatsEntity({
    required this.subjectUuid,
    required this.subjectName,
    required this.colorTagIndex,
    required this.conducted,
    required this.attended,
    required this.cancelled,
    required this.targetPercentage,
    required this.remainingClasses,
  })  : currentPercentage = BunkCalculator.calculateCurrentPercentage(
          attended,
          conducted,
        ),
        classesSafeToSkip = BunkCalculator.classesSafeToSkip(
          attended,
          conducted,
          targetPercentage,
        ),
        classesNeededToReachTarget = BunkCalculator.classesNeededToReachTarget(
          attended,
          conducted,
          targetPercentage,
        ),
        skipPrediction = BunkCalculator.predictAfterSkipping(
          attended,
          conducted,
          1,
          targetPercentage,
        ),
        recoveryPlan = BunkCalculator.buildRecoveryPlan(
          attended,
          conducted,
          targetPercentage,
        ),
        riskLevel = RiskCalculator.calculateRiskLevel(
          conducted == 0
              ? double.nan
              : BunkCalculator.calculateCurrentPercentage(
                  attended,
                  conducted,
                ),
          targetPercentage,
        ),
        examEligibility = BunkCalculator.calculateExamEligibility(
          attended,
          conducted,
          remainingClasses,
          targetPercentage,
        );

  final String subjectUuid;
  final String subjectName;
  final int colorTagIndex;
  final int conducted;
  final int attended;
  final int cancelled;
  final double targetPercentage;
  final int remainingClasses;

  final double currentPercentage;
  final int classesSafeToSkip;
  final int classesNeededToReachTarget;
  final SkipPrediction skipPrediction;
  final RecoveryPlan recoveryPlan;
  final RiskLevel riskLevel;
  final ExamEligibility examEligibility;
}
