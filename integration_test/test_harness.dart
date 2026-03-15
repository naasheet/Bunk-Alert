import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bunk_alert/data/database/local_database_service.dart';
import 'package:bunk_alert/data/models/attendance_record_model.dart';
import 'package:bunk_alert/data/models/subject_model.dart';
import 'package:bunk_alert/data/models/timetable_entry_model.dart';
import 'package:bunk_alert/data/repositories/settings_repository.dart';
import 'package:bunk_alert/main.dart';
import 'package:bunk_alert/shared/auth/app_auth.dart';
import 'package:bunk_alert/shared/providers/connectivity_provider.dart';

class MockUser extends Mock implements User {}

const MethodChannel _pathProviderChannel =
    MethodChannel('plugins.flutter.io/path_provider');

Directory? _testDirectory;
bool _isInitialized = false;

Future<void> ensureTestHarnessInitialized() async {
  if (_isInitialized) {
    return;
  }
  TestWidgetsFlutterBinding.ensureInitialized();
  _testDirectory =
      await Directory.systemTemp.createTemp('bunk_alert_test_');
  _pathProviderChannel.setMockMethodCallHandler((call) async {
    final path = _testDirectory!.path;
    switch (call.method) {
      case 'getApplicationDocumentsDirectory':
      case 'getTemporaryDirectory':
      case 'getApplicationSupportDirectory':
      case 'getApplicationCacheDirectory':
      case 'getExternalStorageDirectory':
        return path;
      case 'getExternalStorageDirectories':
      case 'getExternalCacheDirectories':
        return <String>[];
      default:
        return path;
    }
  });
  _isInitialized = true;
}

Future<void> setUpTestHarness() async {
  await ensureTestHarnessInitialized();
  SharedPreferences.setMockInitialValues({});
  await LocalDatabaseService.instance.initialize();
  await clearLocalData();
  await SettingsRepository.instance.setOnboardingComplete(true);
  final user = MockUser();
  when(() => user.uid).thenReturn('test-user');
  when(() => user.displayName).thenReturn('Test User');
  when(() => user.email).thenReturn('test@example.com');
  AppAuthOverrides.enableTestUser(user);
}

Future<void> tearDownTestHarness() async {
  AppAuthOverrides.reset();
  await LocalDatabaseService.instance.close();
}

Future<void> clearLocalData() async {
  final isar = LocalDatabaseService.instance.isar;
  await isar.writeTxn(() async {
    await isar.subjectModels.clear();
    await isar.timetableEntryModels.clear();
    await isar.attendanceRecordModels.clear();
  });
}

Future<void> pumpTestApp(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        connectivityProvider.overrideWith(
          (ref) => Stream<bool>.value(false),
        ),
      ],
      child: const MyApp(),
    ),
  );
  await tester.pumpAndSettle();
}
