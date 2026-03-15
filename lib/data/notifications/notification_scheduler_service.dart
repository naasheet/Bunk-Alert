import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:bunk_alert/core/router/app_router.dart';
import 'package:bunk_alert/core/utils/risk_calculator.dart';
import 'package:bunk_alert/data/models/timetable_entry_model.dart';
import 'package:bunk_alert/data/repositories/attendance_repository.dart';
import 'package:bunk_alert/data/repositories/settings_repository.dart';
import 'package:bunk_alert/data/repositories/subject_repository.dart';
import 'package:bunk_alert/data/repositories/timetable_repository.dart';
import 'package:bunk_alert/domain/usecases/calculate_stats_usecase.dart';

class NotificationSchedulerService {
  NotificationSchedulerService._();

  static final NotificationSchedulerService instance =
      NotificationSchedulerService._();

  static const String _classChannelId = 'class_reminders';
  static const String _classChannelName = 'Class Reminders';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();
  final TimetableRepository _timetableRepository = TimetableRepository();
  final SubjectRepository _subjectRepository = SubjectRepository();
  final SettingsRepository _settingsRepository = SettingsRepository.instance;
  final CalculateStatsUsecase _statsUsecase = const CalculateStatsUsecase();
  SharedPreferences? _prefs;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      debugPrint('scheduler: init notifications');
      const androidInit =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const iosInit = DarwinInitializationSettings();
      await _localNotifications.initialize(
        settings: const InitializationSettings(
          android: androidInit,
          iOS: iosInit,
        ),
        onDidReceiveNotificationResponse: (response) {
          AppRouter.handleNotificationPayload(response.payload);
        },
      );
      debugPrint('scheduler: channel');
      await _createNotificationChannel();
      debugPrint('scheduler: timezone');
      await _configureTimeZone();
      debugPrint('scheduler: prefs');
      await _loadPrefs();
      _initialized = true;
      debugPrint('scheduler: done');
    } catch (error, stackTrace) {
      debugPrint('scheduler: init error $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> scheduleClassReminder(
    TimetableEntryModel entry,
  ) async {
    await initialize();
    final enabled = await _settingsRepository.getClassRemindersEnabled();
    if (!enabled) {
      return;
    }
    final leadTime =
        await _settingsRepository.getReminderLeadTimeMinutes();
    final subject = await _subjectRepository.getSubjectById(entry.subjectUuid);
    final subjectName = subject?.name ?? 'Class';
    final schedule = _nextReminderForEntry(entry, leadTime);
    final startTime = _formatMinutes(entry.startMinutes);
    final endTime = _formatMinutes(entry.endMinutes);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _classChannelId,
        _classChannelName,
        channelDescription: 'Reminders before class starts',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _localNotifications.zonedSchedule(
      id: _notificationIdFromUuid(entry.uuid),
      title: '$subjectName starts in $leadTime minutes.',
      body: '$startTime - $endTime.',
      scheduledDate: schedule,
      notificationDetails: details,
      payload: _subjectPayload(entry.subjectUuid),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> checkAndScheduleRiskAlerts() async {
    await initialize();
    final enabled = await _settingsRepository.getRiskAlertsEnabled();
    if (!enabled) {
      await cancelRiskAlerts();
      return;
    }
    final subjects = await _subjectRepository.getActiveSubjects();
    final records = await _attendanceRepository.getAllRecords();
    final globalTarget =
        await SettingsRepository.instance.getGlobalTargetPercentage();

    final stats = subjects
        .map(
          (subject) => _statsUsecase.call(
            subject: subject,
            records: records,
            globalTargetPercentage: globalTarget,
            remainingClasses: subject.expectedTotalClasses ?? 0,
          ),
        )
        .toList();

    for (final entry in stats) {
      if (entry.riskLevel != RiskLevel.warning &&
          entry.riskLevel != RiskLevel.danger) {
        await _clearRiskAlertSent(entry.subjectUuid);
        continue;
      }
      if (await _isRiskAlertSentToday(entry.subjectUuid)) {
        continue;
      }
      final needed = entry.recoveryPlan.classesNeeded;
      final classesText = needed <= 0
          ? 'Attend the next classes to stay safe.'
          : 'Attend the next $needed classes to stay safe.';

      await _localNotifications.show(
        id: _notificationIdFromUuid(entry.subjectUuid),
        title: 'Warning: ${entry.subjectName} attendance is at '
            '${entry.currentPercentage.round()}%.',
        body: classesText,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _classChannelId,
            _classChannelName,
            channelDescription: 'Attendance risk alerts',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: _subjectPayload(entry.subjectUuid),
      );
      await _markRiskAlertSent(entry.subjectUuid);
    }
  }

  Future<void> _configureTimeZone() async {
    tz.initializeTimeZones();
    final timeZone = await FlutterTimezone.getLocalTimezone();
    final identifier = timeZone.identifier;
    tz.Location location;
    try {
      location = tz.getLocation(identifier);
    } catch (_) {
      if (identifier == 'Asia/Calcutta') {
        location = tz.getLocation('Asia/Kolkata');
      } else {
        location = tz.getLocation('UTC');
      }
    }
    tz.setLocalLocation(location);
  }

  Future<void> rescheduleClassReminders() async {
    await initialize();
    await cancelClassReminders();
    final entries = await _timetableRepository.getAllActiveEntries();
    for (final entry in entries) {
      await scheduleClassReminder(entry);
    }
  }

  Future<void> cancelClassReminders() async {
    await initialize();
    final entries = await _timetableRepository.getAllActiveEntries();
    await Future.wait(
      entries.map(
        (entry) => _localNotifications.cancel(
          id: _notificationIdFromUuid(entry.uuid),
        ),
      ),
    );
  }

  Future<void> cancelClassReminder(String entryUuid) async {
    await initialize();
    await _localNotifications.cancel(id: _notificationIdFromUuid(entryUuid));
  }

  Future<void> cancelRiskAlerts() async {
    await initialize();
    final subjects = await _subjectRepository.getActiveSubjects();
    await Future.wait(
      subjects.map(
        (subject) => _localNotifications.cancel(
          id: _notificationIdFromUuid(subject.uuid),
        ),
      ),
    );
    await Future.wait(
      subjects.map((subject) => _clearRiskAlertSent(subject.uuid)),
    );
  }

  Future<void> _loadPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _createNotificationChannel() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) {
      return;
    }
    const channel = AndroidNotificationChannel(
      _classChannelId,
      _classChannelName,
      description: 'Reminders before class starts',
      importance: Importance.high,
    );
    await androidPlugin.createNotificationChannel(channel);
  }

  tz.TZDateTime _nextReminderForEntry(
    TimetableEntryModel entry,
    int reminderOffset,
  ) {
    var dayOfWeek = entry.dayOfWeek;
    var minutes = entry.startMinutes - reminderOffset;
    if (minutes < 0) {
      minutes += 24 * 60;
      dayOfWeek = dayOfWeek == DateTime.monday
          ? DateTime.sunday
          : dayOfWeek - 1;
    }
    return _nextInstanceOfWeekdayAndTime(
      dayOfWeek,
      minutes,
    );
  }

  tz.TZDateTime _nextInstanceOfWeekdayAndTime(
    int weekday,
    int minutesFromMidnight,
  ) {
    final now = tz.TZDateTime.now(tz.local);
    final hour = minutesFromMidnight ~/ 60;
    final minute = minutesFromMidnight % 60;
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    var daysUntil = (weekday - scheduled.weekday) % 7;
    if (daysUntil < 0) {
      daysUntil += 7;
    }
    scheduled = scheduled.add(Duration(days: daysUntil));
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }
    return scheduled;
  }

  String _formatMinutes(int minutes) {
    final time = DateTime(0, 1, 1, minutes ~/ 60, minutes % 60);
    return DateFormat('h:mm a').format(time);
  }

  int _notificationIdFromUuid(String uuid) {
    final sanitized = uuid.replaceAll('-', '');
    final slice = sanitized.length >= 8 ? sanitized.substring(0, 8) : sanitized;
    final value = int.parse(slice, radix: 16);
    return value & 0x7FFFFFFF;
  }

  String _subjectPayload(String subjectUuid) {
    return 'subject:$subjectUuid';
  }

  Future<bool> _isRiskAlertSentToday(String subjectUuid) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final key = _riskAlertKey(subjectUuid);
    final stored = prefs.getString(key);
    final today = _todayKey();
    return stored == today;
  }

  Future<void> _markRiskAlertSent(String subjectUuid) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_riskAlertKey(subjectUuid), _todayKey());
  }

  Future<void> _clearRiskAlertSent(String subjectUuid) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.remove(_riskAlertKey(subjectUuid));
  }

  String _riskAlertKey(String subjectUuid) {
    return 'risk_alert_sent_$subjectUuid';
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
