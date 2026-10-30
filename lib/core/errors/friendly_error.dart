import 'dart:async';

import 'package:firebase_core/firebase_core.dart';

String friendlyError(Object error) {
  if (error is TimeoutException) {
    return 'The connection is taking a little longer. Your draft is safe. Check your history before retrying.';
  }
  if (error is FormatException ||
      error is StateError ||
      error is ArgumentError) {
    return error.toString().replaceFirst(
      RegExp(r'^(Bad state: |FormatException: |Invalid argument\(s\): )'),
      '',
    );
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'invalid-email' => 'That email doesn’t look quite right.',
      'invalid-credential' || 'wrong-password' || 'user-not-found' =>
        'The email or password doesn’t match. Please try again.',
      'email-already-in-use' =>
        'There’s already an account with this email. Try signing in.',
      'weak-password' => 'Choose a password with at least 8 characters.',
      'too-many-requests' =>
        'Let’s pause for a moment. Please try again later.',
      'network-request-failed' || 'unavailable' => 'We can’t reach our world right now. Check your connection and try again.',
      'permission-denied' => 'This private world is reserved for its two approved accounts. Check your membership and pairing.',
      'resource-exhausted' => 'Our world has reached its free daily allowance. Please try again after the quota resets.',
      'requires-recent-login' =>
        'Please sign in again before making this change.',
      'failed-precondition' => 'This action needs a live connection and the latest setup. Reconnect and try again.',
      _ => 'Something interrupted this moment. Please try again.',
    };
  }
  return 'Something interrupted this moment. Please try again.';
}
