import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bunk_alert/core/router/route_names.dart';
import 'package:bunk_alert/features/analytics/screens/analytics_screen.dart';
import 'package:bunk_alert/features/auth/screens/login_screen.dart';
import 'package:bunk_alert/features/auth/screens/sign_up_screen.dart';
import 'package:bunk_alert/features/dashboard/screens/dashboard_screen.dart';
import 'package:bunk_alert/features/settings/screens/settings_screen.dart';
import 'package:bunk_alert/features/social/screens/social_screen.dart';
import 'package:bunk_alert/features/social/screens/leaderboard_screen.dart';
import 'package:bunk_alert/features/subjects/screens/add_edit_subject_screen.dart';
import 'package:bunk_alert/features/subjects/screens/subject_detail_screen.dart';
import 'package:bunk_alert/features/subjects/screens/subjects_screen.dart';
import 'package:bunk_alert/features/timetable/screens/timetable_screen.dart';
import 'package:bunk_alert/shared/auth/app_auth.dart';
import 'package:bunk_alert/shared/widgets/app_bottom_nav_bar.dart';
import 'package:bunk_alert/shared/widgets/app_scaffold.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.home,
    refreshListenable: GoRouterRefreshStream(
      AppAuth.authStateChanges(),
    ),
    redirect: (context, state) async {
      final isLoggedIn = AppAuth.currentUser != null;
      final location = state.matchedLocation;
      final isAuthRoute =
          location == RouteNames.login || location == RouteNames.signup;

      if (!isLoggedIn && !isAuthRoute) {
        return RouteNames.login;
      }

      if (isLoggedIn && isAuthRoute) {
        return RouteNames.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.signup,
        builder: (context, state) => const SignUpScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          final index = _tabIndexForLocation(state.matchedLocation);
          return AppScaffold(
            body: child,
            bottomNavigationBar: AppBottomNavBar(
              currentIndex: index,
              onTap: (tabIndex) {
                final location = _locationForTab(tabIndex);
                if (location != null) {
                  context.go(location);
                }
              },
            ),
          );
        },
        routes: [
          GoRoute(
            path: RouteNames.home,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: RouteNames.subjects,
            builder: (context, state) => const SubjectsScreen(),
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => const MaterialPage<void>(
                  fullscreenDialog: true,
                  child: AddEditSubjectScreen(),
                ),
              ),
              GoRoute(
                path: ':subjectId',
                builder: (context, state) => SubjectDetailScreen(
                  subjectId: state.pathParameters['subjectId'] ?? '',
                ),
              ),
              GoRoute(
                path: ':subjectId/edit',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => MaterialPage<void>(
                  fullscreenDialog: true,
                  child: AddEditSubjectScreen(
                    subjectId: state.pathParameters['subjectId'],
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.timetable,
            builder: (context, state) => const TimetableScreen(),
          ),
          GoRoute(
            path: RouteNames.analytics,
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: RouteNames.social,
            builder: (context, state) => const SocialScreen(),
            routes: [
              GoRoute(
                path: ':groupId',
                builder: (context, state) => LeaderboardScreen(
                  groupId: state.pathParameters['groupId'] ?? '',
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.settings,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage<void>(
          fullscreenDialog: true,
          child: SettingsScreen(),
        ),
      ),
    ],
  );

  static void handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return;
    }
    if (payload.startsWith('subject:')) {
      final subjectId = payload.substring('subject:'.length);
      if (subjectId.isEmpty) {
        return;
      }
      router.go('${RouteNames.subjects}/$subjectId');
    }
  }

  static int _tabIndexForLocation(String location) {
    if (location.startsWith(RouteNames.subjects)) {
      return 1;
    }
    if (location.startsWith(RouteNames.timetable)) {
      return 2;
    }
    if (location.startsWith(RouteNames.analytics)) {
      return 3;
    }
    if (location.startsWith(RouteNames.social)) {
      return 4;
    }
    return 0;
  }

  static String? _locationForTab(int index) {
    switch (index) {
      case 0:
        return RouteNames.home;
      case 1:
        return RouteNames.subjects;
      case 3:
        return RouteNames.analytics;
      case 4:
        return RouteNames.social;
      case 2:
        return RouteNames.timetable;
      default:
        return null;
    }
  }

  const AppRouter._();
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
