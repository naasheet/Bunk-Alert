import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:bunk_alert/core/router/app_router.dart';
import 'package:bunk_alert/data/firebase/firestore_service.dart';
import 'package:bunk_alert/data/models/timetable_entry_model.dart';
import 'package:bunk_alert/data/repositories/subject_repository.dart';
import 'package:bunk_alert/data/repositories/timetable_repository.dart';
import 'package:bunk_alert/shared/auth/app_auth.dart';

class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final SubjectRepository _subjectRepository = SubjectRepository();
  final TimetableRepository _timetableRepository = TimetableRepository();

  bool _initialized = false;
  bool _promptShown = false;
  bool _tokenListenerAttached = false;
  SharedPreferences? _prefs;

  static const String _promptKey = 'notification_permission_prompted';

  static const String _classChannelId = 'class_reminders';
  static const String _classChannelName = 'Class Reminders';

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      debugPrint('fcm: init notifications');
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
      debugPrint('fcm: create channel');
      await _createNotificationChannel();
      debugPrint('fcm: configure timezone');
      await _configureTimeZone();
      debugPrint('fcm: configure listeners');
      await _configureFcmListeners();
      debugPrint('fcm: done');
      _initialized = true;
    } catch (error, stackTrace) {
      debugPrint('fcm: init error $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> requestPermissionsIfReady(BuildContext context) async {
    if (AppAuthOverrides.isTest) {
      return;
    }
    await initialize();
    if (!await _shouldPrompt()) {
      return;
    }
    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Want reminders before your classes?'),
          content: const Text(
            'We can send a quick reminder 10 minutes before your classes '
            'and important alerts about your attendance.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Maybe Later'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sure'),
            ),
          ],
        );
      },
    );

    await _markPromptShown();
    if (shouldRequest == true) {
      await _requestLocalPermissions();
      await _requestFcmPermissions();
      await _attachTokenListener();
      await _refreshToken();
    }
  }

  Future<void> scheduleClassReminders({
    required List<TimetableEntryModel> entries,
    String? subjectName,
    Duration reminderOffset = const Duration(minutes: 10),
  }) async {
    for (final entry in entries) {
      await scheduleClassReminder(
        entry: entry,
        subjectName: subjectName,
        reminderOffset: reminderOffset,
      );
    }
  }

  Future<void> scheduleClassReminder({
    required TimetableEntryModel entry,
    String? subjectName,
    Duration reminderOffset = const Duration(minutes: 10),
  }) async {
    final schedule = _nextReminderForEntry(entry, reminderOffset);
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
    final title = subjectName?.isNotEmpty == true
        ? '$subjectName starts soon'
        : 'Class starts soon';
    final body = 'Reminder: class begins in ${reminderOffset.inMinutes} min';
    await _localNotifications.zonedSchedule(
      id: _notificationIdFromUuid(entry.uuid),
      title: title,
      body: body,
      scheduledDate: schedule,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _classChannelId,
        _classChannelName,
        channelDescription: 'Alerts and reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
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

  Future<void> _requestLocalPermissions() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _requestFcmPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _configureFcmListeners() async {
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null &&
          (notification.title?.isNotEmpty ?? false)) {
        final subjectId = message.data['subjectId'] as String?;
        unawaited(
          showLocalNotification(
            title: notification.title ?? 'Alert',
            body: notification.body ?? '',
            payload: subjectId == null ? null : 'subject:$subjectId',
          ),
        );
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final subjectId = message.data['subjectId'] as String?;
      if (subjectId != null && subjectId.isNotEmpty) {
        AppRouter.handleNotificationPayload('subject:$subjectId');
      }
    });
  }

  Future<void> _refreshToken() async {
    if (!await _hasNotificationPermission()) {
      return;
    }
    final token = await _messaging.getToken();
    await _saveToken(token);
  }

  Future<void> _saveToken(String? token) async {
    final userId = AppAuth.currentUser?.uid;
    if (token == null || userId == null) {
      return;
    }
    await _firestoreService.upsertFcmToken(
      userId: userId,
      token: token,
      platform: Platform.operatingSystem,
    );
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

  Future<void> _attachTokenListener() async {
    if (_tokenListenerAttached) {
      return;
    }
    _tokenListenerAttached = true;
    _messaging.onTokenRefresh.listen(_saveToken);
    AppAuth.authStateChanges().listen((user) async {
      if (user == null) {
        return;
      }
      await _refreshToken();
    });
  }

  Future<bool> _hasNotificationPermission() async {
    if (!Platform.isIOS) {
      return true;
    }
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<bool> _shouldPrompt() async {
    if (_promptShown) {
      return false;
    }
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    if (prefs.getBool(_promptKey) == true) {
      return false;
    }
    final subjectCount = await _subjectRepository.getActiveSubjectCount();
    final timetableCount = await _timetableRepository.getActiveEntryCount();
    if (subjectCount < 1 || timetableCount < 1) {
      return false;
    }
    return true;
  }

  Future<void> _markPromptShown() async {
    _promptShown = true;
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setBool(_promptKey, true);
  }

  tz.TZDateTime _nextReminderForEntry(
    TimetableEntryModel entry,
    Duration reminderOffset,
  ) {
    final reminderMinutes = reminderOffset.inMinutes;
    var dayOfWeek = entry.dayOfWeek;
    var minutes = entry.startMinutes - reminderMinutes;
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

  int _notificationIdFromUuid(String uuid) {
    final sanitized = uuid.replaceAll('-', '');
    final slice = sanitized.length >= 8 ? sanitized.substring(0, 8) : sanitized;
    return int.parse(slice, radix: 16);
  }
}
