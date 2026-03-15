import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:bunk_alert/core/config/google_sign_in_config.dart';

class FirebaseAuthService {
  FirebaseAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  bool _googleInitialized = false;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();
      final googleUser = await _googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      return _auth.signInWithCredential(credential);
    } catch (error, stackTrace) {
      debugPrint('google sign-in error: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) {
      return;
    }
    final serverClientId = await GoogleSignInConfig.getServerClientId();
    if (serverClientId == null) {
      throw StateError(
        'Missing default_web_client_id. Re-download google-services.json after '
        'enabling Google sign-in and adding SHA-1 in Firebase.',
      );
    }
    await _googleSignIn.initialize(serverClientId: serverClientId);
    _googleInitialized = true;
  }
}
