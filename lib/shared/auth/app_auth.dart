import 'package:firebase_auth/firebase_auth.dart';

class AppAuthOverrides {
  static bool isTest = false;
  static User? currentUser;
  static Stream<User?>? authStateChanges;

  static void enableTestUser(User user) {
    isTest = true;
    currentUser = user;
    authStateChanges = Stream<User?>.value(user);
  }

  static void reset() {
    isTest = false;
    currentUser = null;
    authStateChanges = null;
  }
}

class AppAuth {
  static User? get currentUser =>
      AppAuthOverrides.currentUser ?? FirebaseAuth.instance.currentUser;

  static Stream<User?> authStateChanges() =>
      AppAuthOverrides.authStateChanges ??
      FirebaseAuth.instance.authStateChanges();
}
