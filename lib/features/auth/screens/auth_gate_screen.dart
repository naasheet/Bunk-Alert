import 'package:flutter/material.dart';

import 'package:bunk_alert/features/auth/screens/login_screen.dart';
import 'package:bunk_alert/features/dashboard/screens/dashboard_screen.dart';
import 'package:bunk_alert/shared/auth/app_auth.dart';

class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AppAuth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const DashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
