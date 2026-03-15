import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bunk_alert/core/router/app_router.dart';
import 'package:bunk_alert/core/theme/app_theme.dart';
import 'package:bunk_alert/data/database/local_database_service.dart';
import 'package:bunk_alert/data/firebase/firestore_service.dart';
import 'package:bunk_alert/data/notifications/fcm_service.dart';
import 'package:bunk_alert/data/notifications/notification_scheduler_service.dart';
import 'package:bunk_alert/data/repositories/settings_repository.dart';
import 'package:bunk_alert/data/sync/offline_sync_service.dart';
import 'package:bunk_alert/firebase_options.dart';
import 'package:bunk_alert/shared/auth/app_auth.dart';
import 'package:bunk_alert/shared/utils/error_message_mapper.dart';
import 'package:bunk_alert/shared/widgets/error_state_widget.dart';
import 'package:bunk_alert/shared/widgets/loading_indicator.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error');
    debugPrintStack(stackTrace: stack);
    return true;
  };
  runApp(const ProviderScope(child: BootstrapGate()));
}

class BootstrapGate extends StatefulWidget {
  const BootstrapGate({super.key});

  @override
  State<BootstrapGate> createState() => _BootstrapGateState();
}

class _BootstrapGateState extends State<BootstrapGate> {
  late Future<void> _bootstrapFuture = _bootstrap();

  Future<void> _bootstrap() async {
    try {
      debugPrint('bootstrap: firebase');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('bootstrap: messaging');
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      debugPrint('bootstrap: local db');
      final userId = AppAuth.currentUser?.uid;
      await LocalDatabaseService.instance.initializeForUser(userId);
      await LocalDatabaseService.instance.bindToUserIdStream(
        AppAuth.authStateChanges().map((user) => user?.uid),
      );
      debugPrint('bootstrap: offline sync');
      await OfflineSyncService.instance.start();
      debugPrint('bootstrap: fcm service');
      await FcmService.instance.initialize();
      debugPrint('bootstrap: scheduler');
      await NotificationSchedulerService.instance.initialize();
      debugPrint('bootstrap: settings');
      await SettingsRepository.instance.initializeThemeMode();
      debugPrint('bootstrap: profile');
      await _syncUserProfile();
      debugPrint('bootstrap: done');
    } catch (error, stackTrace) {
      debugPrint('bootstrap: error $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _BootstrapScaffold(
            child: const LoadingIndicator(),
          );
        }
        if (snapshot.hasError) {
          return _BootstrapScaffold(
            child: ErrorStateWidget(
              message: friendlyErrorMessage(snapshot.error),
              onRetry: () {
                setState(() {
                  _bootstrapFuture = _bootstrap();
                });
              },
            ),
          );
        }
        return const MyApp();
      },
    );
  }
}

Future<void> _syncUserProfile() async {
  final user = AppAuth.currentUser;
  if (user == null) {
    return;
  }
  try {
    final name = user.displayName?.trim();
    final email = user.email?.trim();
    final displayName = name?.isNotEmpty == true
        ? name!
        : email?.isNotEmpty == true
            ? email!
            : 'Student';
    final target =
        await SettingsRepository.instance.getGlobalTargetPercentage();
    await FirestoreService().upsertUserProfile(
      userId: user.uid,
      name: displayName,
      email: email ?? '',
      targetPercentage: target.round(),
      setCreatedAt: false,
    );
  } catch (_) {
    // Ignore profile sync failures.
  }
}

class _BootstrapScaffold extends StatelessWidget {
  const _BootstrapScaffold({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bunk Alert',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsRepository = SettingsRepository.instance;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: settingsRepository.themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp.router(
          title: 'Bunk Alert',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
