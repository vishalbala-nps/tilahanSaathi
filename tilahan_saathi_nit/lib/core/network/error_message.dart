import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Turns an error thrown by a repository (Firebase or the backend API) into
/// copy that's safe to show directly in the UI.
String friendlyErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }
  if (error is DioException) {
    return 'Could not reach the server. Please try again.';
  }
  return 'Something went wrong. Please try again.';
}
