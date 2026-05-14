import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../services/auth_service.dart';
import '../services/firebase_auth_service.dart';
import '../utils/mutation_notifier.dart';

final authServiceProvider = Provider<AuthService>(
  (ref) => FirebaseAuthService(),
);

/// Streams the current Firebase auth user — null when signed out.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class AuthNotifier extends MutationNotifier {
  AuthService get _service => ref.read(authServiceProvider);

  Future<bool> signInWithEmail(String email, String password) => run(
        () => _service.signInWithEmail(email, password),
        mapError: _mapError,
      );

  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) =>
      run(
        () => _service.registerWithEmail(
          email: email,
          password: password,
          displayName: displayName,
        ),
        mapError: _mapError,
      );

  Future<bool> signInWithGoogle() => run(
        () => _service.signInWithGoogle(),
        ignoreError: (e) => e.toString().contains('sign_in_cancelled'),
        mapError: (_) => 'Google sign-in failed. Please try again.',
      );

  Future<bool> signInWithApple() => run(
        () => _service.signInWithApple(),
        ignoreError: (e) =>
            e is SignInWithAppleAuthorizationException &&
            e.code == AuthorizationErrorCode.canceled,
        mapError: (_) => 'Apple sign-in failed. Please try again.',
      );

  Future<bool> signInWithPhone(String verificationId, String smsCode) => run(
        () => _service.signInWithPhoneCredential(verificationId, smsCode),
        mapError: _mapError,
      );

  Future<void> signOut() => _service.signOut();

  String _mapError(Object e) => e is FirebaseAuthException
      ? _mapAuthError(e.code)
      : 'Authentication failed. Please try again.';

  String _mapAuthError(String code) => switch (code) {
        'user-not-found' => 'No account found with this email.',
        'wrong-password' || 'invalid-credential' =>
          'Incorrect email or password.',
        'email-already-in-use' =>
          'An account already exists with this email.',
        'invalid-email' => 'Please enter a valid email address.',
        'weak-password' => 'Password must be at least 6 characters.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'invalid-verification-code' => 'Incorrect verification code.',
        'session-expired' =>
          'Verification code expired. Please request a new one.',
        _ => 'Authentication failed. Please try again.',
      };
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, MutationState>(AuthNotifier.new);
