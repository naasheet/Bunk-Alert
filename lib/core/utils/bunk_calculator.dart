import 'dart:math';

class SkipPrediction {
  const SkipPrediction({
    required this.predictedPercentage,
    required this.isAboveTarget,
    required this.remainingSkips,
  });

  final double predictedPercentage;
  final bool isAboveTarget;
  final int remainingSkips;
}

class RecoveryPlan {
  const RecoveryPlan({
    required this.classesNeeded,
    required this.predictedPercentage,
    required this.message,
  });

  final int classesNeeded;
  final double predictedPercentage;
  final String message;
}

class ExamEligibility {
  const ExamEligibility({
    required this.isEligible,
    required this.deficitClasses,
  });

  final bool isEligible;
  final int deficitClasses;
}

class BunkCalculator {
  const BunkCalculator._();

  static double calculateCurrentPercentage(int attended, int conducted) {
    _validate(attended: attended, conducted: conducted);
    if (conducted == 0) {
      return 0;
    }
    return (attended / conducted) * 100;
  }

  static int classesSafeToSkip(
    int attended,
    int conducted,
    double targetPercent,
  ) {
    _validate(attended: attended, conducted: conducted);
    if (conducted == 0 || targetPercent <= 0) {
      return 0;
    }

    final raw = (attended * 100 / targetPercent) - conducted;
    final result = max(0, raw.floor());
    return min(50, result);
  }

  static int classesNeededToReachTarget(
    int attended,
    int conducted,
    double targetPercent,
  ) {
    _validate(attended: attended, conducted: conducted);
    if (conducted == 0) {
      return 0;
    }

    final currentPercentage =
        calculateCurrentPercentage(attended, conducted);
    if (currentPercentage >= targetPercent) {
      return 0;
    }

    if (targetPercent >= 100) {
      return -1;
    }

    final numerator = (targetPercent * conducted) - (100 * attended);
    final denominator = 100 - targetPercent;
    return max(0, (numerator / denominator).ceil());
  }

  static SkipPrediction predictAfterSkipping(
    int attended,
    int conducted,
    int classesToSkip,
    double targetPercent,
  ) {
    _validate(attended: attended, conducted: conducted);
    if (classesToSkip < 0) {
      throw ArgumentError('classesToSkip cannot be negative');
    }

    final newConducted = conducted + classesToSkip;
    final predictedPercentage = newConducted == 0
        ? 0.0
        : (attended / newConducted) * 100;
    final remainingSkips = classesSafeToSkip(
      attended,
      newConducted,
      targetPercent,
    );

    return SkipPrediction(
      predictedPercentage: predictedPercentage,
      isAboveTarget: predictedPercentage >= targetPercent,
      remainingSkips: remainingSkips,
    );
  }

  static RecoveryPlan buildRecoveryPlan(
    int attended,
    int conducted,
    double targetPercent,
  ) {
    _validate(attended: attended, conducted: conducted);
    final needed = classesNeededToReachTarget(
      attended,
      conducted,
      targetPercent,
    );

    if (needed == 0) {
      final currentPercentage =
          calculateCurrentPercentage(attended, conducted);
      return RecoveryPlan(
        classesNeeded: 0,
        predictedPercentage: currentPercentage,
        message: "You're on track. You can relax.",
      );
    }

    if (needed == -1) {
      return const RecoveryPlan(
        classesNeeded: -1,
        predictedPercentage: 0,
        message: 'Target requires perfect attendance from now on.',
      );
    }

    final predictedPercentage =
        ((attended + needed) / (conducted + needed)) * 100;
    return RecoveryPlan(
      classesNeeded: needed,
      predictedPercentage: predictedPercentage,
      message: 'Attend the next $needed classes to reach '
          '${targetPercent.toStringAsFixed(0)}%.',
    );
  }

  static ExamEligibility calculateExamEligibility(
    int attended,
    int conducted,
    int remainingClasses,
    double requiredPercent,
  ) {
    _validate(attended: attended, conducted: conducted);
    if (remainingClasses < 0) {
      throw ArgumentError('remainingClasses cannot be negative');
    }

    final finalConducted = conducted + remainingClasses;
    if (finalConducted == 0) {
      return const ExamEligibility(isEligible: false, deficitClasses: 0);
    }

    final maxPercentage =
        ((attended + remainingClasses) / finalConducted) * 100;
    if (maxPercentage >= requiredPercent) {
      return const ExamEligibility(isEligible: true, deficitClasses: 0);
    }

    final requiredAttended =
        ((requiredPercent / 100) * finalConducted).ceil();
    final deficit =
        max(0, requiredAttended - (attended + remainingClasses));
    return ExamEligibility(isEligible: false, deficitClasses: deficit);
  }

  static void _validate({
    required int attended,
    required int conducted,
  }) {
    if (attended < 0 || conducted < 0) {
      throw ArgumentError('attended and conducted must be non-negative');
    }
    if (attended > conducted) {
      throw ArgumentError('attended cannot exceed conducted');
    }
  }
}
