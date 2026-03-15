import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bunk_alert/data/database/local_database_service.dart';
import 'package:bunk_alert/data/firebase/firestore_service.dart';

class SettingsRepository {
  SettingsRepository({
    LocalDatabaseService? localDatabaseService,
    FirestoreService? firestoreService,
  })  : _localDatabaseService =
            localDatabaseService ?? LocalDatabaseService.instance,
        _firestoreService = firestoreService ?? FirestoreService();

  static final SettingsRepository instance = SettingsRepository();

  static const String _onboardingKey = 'onboarding_complete';
  static const String _targetPercentKey = 'global_target_percentage';
  static const String _classRemindersKey = 'class_reminders_enabled';
  static const String _riskAlertsKey = 'risk_alerts_enabled';
  static const String _reminderLeadTimeKey = 'reminder_lead_time_minutes';
  static const String _themeModeKey = 'theme_mode';
  static const double _defaultTarget = 75;
  static const int _defaultLeadTime = 10;

  SharedPreferences? _prefs;
  final LocalDatabaseService _localDatabaseService;
  final FirestoreService _firestoreService;
  final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<bool> isOnboardingComplete() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingComplete(bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_onboardingKey, value);
  }

  Future<double> getGlobalTargetPercentage() async {
    final prefs = await _getPrefs();
    return prefs.getDouble(_targetPercentKey) ?? _defaultTarget;
  }

  Future<void> setGlobalTargetPercentage(double value) async {
    final prefs = await _getPrefs();
    await prefs.setDouble(_targetPercentKey, value);
  }

  Future<bool> getClassRemindersEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_classRemindersKey) ?? true;
  }

  Future<void> setClassRemindersEnabled(bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_classRemindersKey, value);
  }

  Future<bool> getRiskAlertsEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_riskAlertsKey) ?? true;
  }

  Future<void> setRiskAlertsEnabled(bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_riskAlertsKey, value);
  }

  Future<int> getReminderLeadTimeMinutes() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_reminderLeadTimeKey) ?? _defaultLeadTime;
  }

  Future<void> setReminderLeadTimeMinutes(int value) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_reminderLeadTimeKey, value);
  }

  Future<ThemeMode> getThemeMode() async {
    final prefs = await _getPrefs();
    final value = prefs.getString(_themeModeKey);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await _getPrefs();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_themeModeKey, value);
    themeModeNotifier.value = mode;
  }

  Future<void> initializeThemeMode() async {
    themeModeNotifier.value = await getThemeMode();
  }

  Future<void> resetAll() async {
    final prefs = await _getPrefs();
    await prefs.remove(_onboardingKey);
    await prefs.remove(_targetPercentKey);
    await prefs.remove(_classRemindersKey);
    await prefs.remove(_riskAlertsKey);
    await prefs.remove(_reminderLeadTimeKey);
    await prefs.remove(_themeModeKey);
    themeModeNotifier.value = ThemeMode.system;
  }
}
