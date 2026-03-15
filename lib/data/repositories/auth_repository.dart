import 'package:firebase_auth/firebase_auth.dart';

import 'package:bunk_alert/data/database/local_database_service.dart';
import 'package:bunk_alert/data/firebase/firebase_auth_service.dart';
import 'package:bunk_alert/data/firebase/firestore_service.dart';
import 'package:bunk_alert/data/sync/cloud_sync_service.dart';
import 'package:bunk_alert/data/repositories/settings_repository.dart';

class AuthFailure implements Exception {
  AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository({
    LocalDatabaseService? localDatabaseService,
    FirestoreService? firestoreService,
    FirebaseAuthService? authService,
  })  : _localDatabaseService =
            localDatabaseService ?? LocalDatabaseService.instance,
        _firestoreService = firestoreService ?? FirestoreService(),
        _authService = authService ?? FirebaseAuthService();

  final LocalDatabaseService _localDatabaseService;
  final FirestoreService _firestoreService;
  final FirebaseAuthService _authService;
  final SettingsRepository _settingsRepository = SettingsRepository.instance;

  User? get currentUser => _authService.currentUser;

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  Future<UserCredential> signInWithGoogle() async {
    try {
      final credential = await _authService.signInWithGoogle();
      final userId = credential.user?.uid;
      if (userId != null) {
        await _localDatabaseService.initializeForUser(userId);
        CloudSyncService.instance.syncAllInBackground(userId: userId);
        await _syncUserProfile(credential.user!);
      }
      return credential;
    } catch (error) {
      throw AuthFailure(_mapError(error));
    }
  }

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential =
          await _authService.signInWithEmailAndPassword(email, password);
      final userId = credential.user?.uid;
      if (userId != null) {
        await _localDatabaseService.initializeForUser(userId);
        CloudSyncService.instance.syncAllInBackground(userId: userId);
        await _syncUserProfile(credential.user!);
      }
      return credential;
    } catch (error) {
      throw AuthFailure(_mapError(error));
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _authService.createUserWithEmailAndPassword(
        email,
        password,
      );
      final userId = credential.user?.uid;
      if (userId != null) {
        await _localDatabaseService.initializeForUser(userId);
        CloudSyncService.instance.syncAllInBackground(userId: userId);
        await _syncUserProfile(credential.user!, setCreatedAt: true);
      }
      return credential;
    } catch (error) {
      throw AuthFailure(_mapError(error));
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      await _localDatabaseService.close();
    } catch (error) {
      throw AuthFailure(_mapError(error));
    }
  }

  Future<void> _syncUserProfile(
    User user, {
    bool setCreatedAt = false,
  }) async {
    try {
      final name = user.displayName?.trim();
      final email = user.email?.trim();
      final displayName = name?.isNotEmpty == true
          ? name!
          : email?.isNotEmpty == true
              ? email!
              : 'Student';
      final target =
          await _settingsRepository.getGlobalTargetPercentage();
      await _firestoreService.upsertUserProfile(
        userId: user.uid,
        name: displayName,
        email: email ?? '',
        targetPercentage: target.round(),
        setCreatedAt: setCreatedAt,
      );
    } catch (_) {
      // Non-blocking profile sync.
    }
  }

  String _mapError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-credential':
          return 'Invalid credentials. Please try again.';
        case 'user-disabled':
          return 'This account has been disabled. Contact support.';
        case 'user-not-found':
          return 'No account found for that email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-email':
          return 'That email address is invalid.';
        case 'email-already-in-use':
          return 'That email is already registered. Try logging in.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with a different sign-in method.';
        case 'network-request-failed':
          return 'Network error. Check your connection and try again.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait and try again.';
        case 'requires-recent-login':
          return 'Please log in again to continue.';
        default:
          return error.message?.trim().isNotEmpty == true
              ? error.message!.trim()
              : 'Something went wrong. Please try again.';
      }
    }

    if (error is StateError &&
        error.message == 'Google sign-in aborted by user.') {
      return 'Google sign-in was cancelled.';
    }

    return 'Something went wrong. Please try again.';
  }
}
