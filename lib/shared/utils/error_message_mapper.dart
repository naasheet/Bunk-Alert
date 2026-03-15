import 'package:firebase_core/firebase_core.dart';

String friendlyErrorMessage(Object? error) {
  if (error is FirebaseException) {
    return _firebaseMessage(error.code);
  }
  if (error is FormatException) {
    return 'Invalid data. Please check and try again.';
  }
  return 'Something went wrong. Please try again.';
}

String _firebaseMessage(String code) {
  switch (code) {
    case 'network-request-failed':
    case 'unavailable':
    case 'deadline-exceeded':
      return 'Network error. Check your connection and try again.';
    case 'permission-denied':
      return 'You do not have permission to do that.';
    case 'not-found':
      return 'The requested data could not be found.';
    case 'unauthenticated':
      return 'Please sign in again to continue.';
    case 'already-exists':
      return 'That item already exists.';
    case 'resource-exhausted':
      return 'Service is busy. Please try again shortly.';
    case 'cancelled':
      return 'The request was cancelled. Please try again.';
    case 'internal':
      return 'Something went wrong on our side. Please try again.';
    case 'invalid-argument':
      return 'Invalid data. Please check and try again.';
    case 'failed-precondition':
      return 'Action not allowed right now. Please try again.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'user-not-found':
      return 'We could not find that account.';
    case 'wrong-password':
      return 'Incorrect password. Please try again.';
    case 'email-already-in-use':
      return 'That email is already in use.';
    case 'account-exists-with-different-credential':
      return 'Account exists with a different sign-in method.';
    case 'too-many-requests':
      return 'Too many attempts. Please try again later.';
    default:
      return 'Something went wrong. Please try again.';
  }
}
