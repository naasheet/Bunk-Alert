import 'package:flutter_test/flutter_test.dart';

import 'package:bunk_alert/core/utils/risk_calculator.dart';

void main() {
  group('RiskCalculator', () {
    const target = 75.0;

    test('returns noData when current percentage is NaN', () {
      expect(
        RiskCalculator.calculateRiskLevel(double.nan, target),
        RiskLevel.noData,
      );
    });

    test('safe at target + 5 boundary', () {
      expect(
        RiskCalculator.calculateRiskLevel(80.0, target),
        RiskLevel.safe,
      );
    });

    test('warning at exact target boundary', () {
      expect(
        RiskCalculator.calculateRiskLevel(75.0, target),
        RiskLevel.warning,
      );
    });

    test('danger at target - 10 boundary', () {
      expect(
        RiskCalculator.calculateRiskLevel(65.0, target),
        RiskLevel.danger,
      );
    });

    test('critical below target - 10 boundary', () {
      expect(
        RiskCalculator.calculateRiskLevel(64.9, target),
        RiskLevel.critical,
      );
    });
  });
}
