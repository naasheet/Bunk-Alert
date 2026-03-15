import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/data/models/attendance_record_model.dart';
import 'package:bunk_alert/domain/usecases/mark_attendance_usecase.dart';
import 'package:bunk_alert/features/dashboard/widgets/attendance_action_row.dart';

class MockMarkAttendanceUsecase extends Mock
    implements MarkAttendanceUsecase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(DateTime(2024));
  });

  testWidgets('tapping Present selects chip and calls usecase',
      (tester) async {
    final mockUsecase = MockMarkAttendanceUsecase();
    when(
      () => mockUsecase.call(
        subjectUuid: any(named: 'subjectUuid'),
        status: any(named: 'status'),
        date: any(named: 'date'),
        timetableEntryUuid: any(named: 'timetableEntryUuid'),
        note: any(named: 'note'),
      ),
    ).thenAnswer(
      (_) async => AttendanceRecordModel(
        uuid: 'rec-1',
        subjectUuid: 'subject-1',
        date: DateTime.now(),
        status: 'present',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttendanceActionRow(
            subjectUuid: 'subject-1',
            timetableEntryUuid: 'entry-1',
            initialStatus: null,
            markAttendanceUsecase: mockUsecase,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Present'));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    verify(
      () => mockUsecase.call(
        subjectUuid: 'subject-1',
        status: 'present',
        date: any(named: 'date'),
        timetableEntryUuid: 'entry-1',
        note: any(named: 'note'),
      ),
    ).called(1);

    final presentChip = find.ancestor(
      of: find.text('Present'),
      matching: find.byType(GestureDetector),
    );
    final coloredContainer = find.descendant(
      of: presentChip.first,
      matching: find.byWidgetPredicate((widget) {
        if (widget is Container) {
          final decoration = widget.decoration;
          return decoration is BoxDecoration &&
              decoration.color == AppColors.light.safeSubtle;
        }
        return false;
      }),
    );
    expect(coloredContainer, findsOneWidget);
  });
}
