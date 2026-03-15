import 'package:bunk_alert/domain/entities/attendance_stats_entity.dart';

enum RiskLevel {
  safe,
  warning,
  danger,
  critical,
  noData,
}

class OverallRiskScore {
  const OverallRiskScore({
    required this.safeCount,
    required this.warningCount,
    required this.dangerCount,
    required this.criticalCount,
    required this.noDataCount,
    required this.score,
    required this.atRiskSubjects,
  });

  final int safeCount;
  final int warningCount;
  final int dangerCount;
  final int criticalCount;
  final int noDataCount;
  final int score;
  final List<AttendanceStatsEntity> atRiskSubjects;
}

class RiskCalculator {
  const RiskCalculator._();

  static RiskLevel calculateRiskLevel(
    double currentPercentage,
    double targetPercentage,
  ) {
    if (currentPercentage.isNaN) {
      return RiskLevel.noData;
    }

    if (currentPercentage >= targetPercentage + 5) {
      return RiskLevel.safe;
    }
    if (currentPercentage >= targetPercentage) {
      return RiskLevel.warning;
    }
    if (currentPercentage >= targetPercentage - 10) {
      return RiskLevel.danger;
    }
    return RiskLevel.critical;
  }

  static OverallRiskScore calculateOverallRiskScore(
    List<AttendanceStatsEntity> allSubjectStats,
  ) {
    var safeCount = 0;
    var warningCount = 0;
    var dangerCount = 0;
    var criticalCount = 0;
    var noDataCount = 0;
    var totalScore = 0;

    final atRiskSubjects = <AttendanceStatsEntity>[];

    for (final stats in allSubjectStats) {
      final level = calculateRiskLevel(
        stats.conducted == 0 ? double.nan : stats.currentPercentage,
        stats.targetPercentage,
      );
      switch (level) {
        case RiskLevel.safe:
          safeCount++;
          totalScore += 100;
        case RiskLevel.warning:
          warningCount++;
          totalScore += 70;
        case RiskLevel.danger:
          dangerCount++;
          totalScore += 40;
          atRiskSubjects.add(stats);
        case RiskLevel.critical:
          criticalCount++;
          totalScore += 0;
          atRiskSubjects.add(stats);
        case RiskLevel.noData:
          noDataCount++;
          totalScore += 0;
      }
    }

    final denominator = allSubjectStats.isEmpty
        ? 1
        : allSubjectStats.length * 100;
    final compositeScore = ((totalScore / denominator) * 100).round();

    return OverallRiskScore(
      safeCount: safeCount,
      warningCount: warningCount,
      dangerCount: dangerCount,
      criticalCount: criticalCount,
      noDataCount: noDataCount,
      score: compositeScore,
      atRiskSubjects: atRiskSubjects,
    );
  }
}
