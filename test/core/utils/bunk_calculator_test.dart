import 'package:flutter_test/flutter_test.dart';

import 'package:bunk_alert/core/utils/bunk_calculator.dart';

void main() {
  group('BunkCalculator', () {
    test('returns 0 when no classes are conducted', () {
      expect(BunkCalculator.calculateCurrentPercentage(0, 0), 0);
      expect(BunkCalculator.classesSafeToSkip(0, 0, 75), 0);
      expect(BunkCalculator.classesNeededToReachTarget(0, 0, 75), 0);
    });

    test('exactly at target returns zero needed and zero safe skips', () {
      expect(BunkCalculator.classesNeededToReachTarget(7, 10, 70), 0);
      expect(BunkCalculator.classesSafeToSkip(7, 10, 70), 0);
    });

    test('one class above target yields one safe skip', () {
      expect(BunkCalculator.classesSafeToSkip(8, 10, 70), 1);
      expect(BunkCalculator.classesNeededToReachTarget(8, 10, 70), 0);
    });

    test('one class below target returns one class needed', () {
      expect(BunkCalculator.classesNeededToReachTarget(7, 9, 80), 1);
    });

    test('calculates 50% attendance', () {
      expect(BunkCalculator.calculateCurrentPercentage(5, 10), 50);
    });

    test('calculates 100% attendance', () {
      expect(BunkCalculator.calculateCurrentPercentage(10, 10), 100);
    });

    test('target of 100% requires perfect attendance', () {
      expect(BunkCalculator.classesNeededToReachTarget(9, 10, 100), -1);
    });

    test('target of 50% yields zero needed at 50%', () {
      expect(BunkCalculator.classesNeededToReachTarget(5, 10, 50), 0);
    });

    test('attending 30 out of 30 yields expected safe skips', () {
      expect(BunkCalculator.calculateCurrentPercentage(30, 30), 100);
      expect(BunkCalculator.classesSafeToSkip(30, 30, 75), 10);
    });

    test('skipping from 80% predicts drop below target', () {
      final prediction =
          BunkCalculator.predictAfterSkipping(8, 10, 1, 75);
      expect(prediction.predictedPercentage, closeTo(72.73, 0.01));
      expect(prediction.isAboveTarget, false);
    });
  });
}
