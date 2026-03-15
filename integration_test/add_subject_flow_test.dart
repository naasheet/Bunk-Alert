import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await setUpTestHarness();
  });

  tearDown(() async {
    await tearDownTestHarness();
  });

  testWidgets('add subject flow', (tester) async {
    await pumpTestApp(tester);

    await tester.tap(find.text('Subjects'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    final nameField = find.byType(TextField).first;
    await tester.enterText(nameField, 'Physics');
    await tester.pump();

    final slider = find.byType(Slider);
    final sliderRect = tester.getRect(slider);
    await tester.tapAt(
      Offset(sliderRect.left + sliderRect.width * 0.6, sliderRect.center.dy),
    );
    await tester.pump();

    final sliderValue = tester.widget<Slider>(slider).value;
    expect(sliderValue, closeTo(80, 5));

    final swatches = find.byType(InkWell);
    await tester.tap(swatches.at(2));
    await tester.pump();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Physics'), findsOneWidget);

    final subjectTile = find.ancestor(
      of: find.text('Physics'),
      matching: find.byType(InkWell),
    );
    final expectedColor = const Color(0xFFD4924B);
    final colorDot = find.descendant(
      of: subjectTile.first,
      matching: find.byWidgetPredicate((widget) {
        if (widget is Container) {
          final decoration = widget.decoration;
          final constraints = widget.constraints;
          return constraints?.minWidth == 10 &&
              constraints?.minHeight == 10 &&
              decoration is BoxDecoration &&
              decoration.color == expectedColor;
        }
        return false;
      }),
    );
    expect(colorDot, findsOneWidget);
  });
}
