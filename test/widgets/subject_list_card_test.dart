import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bunk_alert/domain/entities/attendance_stats_entity.dart';
import 'package:bunk_alert/features/subjects/widgets/subject_list_card.dart';

void main() {
  testWidgets('SubjectListCard shows ring, badge, and chip data',
      (tester) async {
    final stats = AttendanceStatsEntity(
      subjectUuid: 'subject-1',
      subjectName: 'Mathematics',
      colorTagIndex: 0,
      conducted: 10,
      attended: 9,
      cancelled: 0,
      targetPercentage: 75,
      remainingClasses: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubjectListCard(
            stats: stats,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 1500));

    expect(find.text('90%'), findsOneWidget);
    expect(find.text('Safe'), findsOneWidget);
    expect(find.text('Skip 2'), findsOneWidget);
  });
}
