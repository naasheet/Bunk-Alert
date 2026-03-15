import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';

import 'package:bunk_alert/data/database/local_database_service.dart';
import 'package:bunk_alert/data/models/attendance_record_model.dart';
import 'package:bunk_alert/data/models/subject_model.dart';
import 'package:bunk_alert/data/models/timetable_entry_model.dart';
import 'package:bunk_alert/features/subjects/screens/subject_detail_screen.dart';

import 'test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await setUpTestHarness();
  });

  tearDown(() async {
    await tearDownTestHarness();
  });

  testWidgets('mark attendance flow', (tester) async {
    await _seedSubjectForToday();

    await pumpTestApp(tester);

    await tester.pumpAndSettle();

    await tester.tap(find.text('Absent').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Subjects'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mathematics'));
    await tester.pumpAndSettle();

    final ring = tester.widget<AttendanceRing>(find.byType(AttendanceRing));
    expect(ring.percentage, closeTo(50, 0.01));

    final todayLabel = DateFormat('MMM d, y').format(DateTime.now());
    expect(find.text('Absent'), findsWidgets);
    expect(find.text(todayLabel), findsOneWidget);
  });
}

Future<void> _seedSubjectForToday() async {
  final now = DateTime.now();
  final subject = SubjectModel(
    uuid: 'subject-math',
    name: 'Mathematics',
    colorTagIndex: 0,
    targetPercentage: null,
    expectedTotalClasses: null,
    isArchived: false,
    syncStatus: 'pending',
    createdAt: now,
    updatedAt: now,
  );
  final entry = TimetableEntryModel(
    uuid: 'entry-math-today',
    subjectUuid: subject.uuid,
    dayOfWeek: now.weekday,
    startMinutes: 9 * 60,
    endMinutes: 10 * 60,
    isActive: true,
    syncStatus: 'pending',
    createdAt: now,
  );
  final yesterday = now.subtract(const Duration(days: 1));
  final record = AttendanceRecordModel(
    uuid: 'rec-present',
    subjectUuid: subject.uuid,
    timetableEntryUuid: null,
    date: AttendanceRecordModel.normalizeDate(yesterday),
    status: 'present',
    syncStatus: 'pending',
    createdAt: now,
    updatedAt: now,
  );

  final isar = LocalDatabaseService.instance.isar;
  await isar.writeTxn(() async {
    await isar.subjectModels.put(subject);
    await isar.timetableEntryModels.put(entry);
    await isar.attendanceRecordModels.put(record);
  });
}
