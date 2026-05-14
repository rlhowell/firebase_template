import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_template/providers/auth_providers.dart';
import 'package:firebase_template/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake — no Firebase SDK, no mocking library required
// ---------------------------------------------------------------------------

class FakeAuthService implements AuthService {
  Exception? signInError;
  Exception? registerError;
  bool signedOut = false;

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    if (signInError != null) throw signInError!;
  }

  @override
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (registerError != null) throw registerError!;
  }

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) verificationCompleted,
    required void Function(FirebaseAuthException) verificationFailed,
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(String verificationId) codeAutoRetrievalTimeout,
  }) async {}

  @override
  Future<void> signInWithPhoneCredential(
          String verificationId, String smsCode) async {}

  @override
  Future<void> signInWithCredential(AuthCredential credential) async {}

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ProviderContainer _makeContainer(FakeAuthService fake) => ProviderContainer(
      overrides: [authServiceProvider.overrideWithValue(fake)],
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AuthNotifier — signInWithEmail', () {
    late FakeAuthService fake;
    late ProviderContainer container;

    setUp(() {
      fake = FakeAuthService();
      container = _makeContainer(fake);
    });

    tearDown(() => container.dispose());

    test('success: returns true, clears loading, no error', () async {
      final result = await container
          .read(authNotifierProvider.notifier)
          .signInWithEmail('user@example.com', 'password123');

      expect(result, isTrue);
      final state = container.read(authNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('wrong-password: returns false, maps to human message', () async {
      fake.signInError = FirebaseAuthException(code: 'wrong-password');

      final result = await container
          .read(authNotifierProvider.notifier)
          .signInWithEmail('user@example.com', 'bad');

      expect(result, isFalse);
      final state = container.read(authNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, 'Incorrect email or password.');
    });

    test('invalid-credential maps to same message as wrong-password', () async {
      fake.signInError = FirebaseAuthException(code: 'invalid-credential');

      final result = await container
          .read(authNotifierProvider.notifier)
          .signInWithEmail('user@example.com', 'bad');

      expect(result, isFalse);
      expect(
        container.read(authNotifierProvider).error,
        'Incorrect email or password.',
      );
    });

    test('user-not-found: maps to account-not-found message', () async {
      fake.signInError = FirebaseAuthException(code: 'user-not-found');

      final result = await container
          .read(authNotifierProvider.notifier)
          .signInWithEmail('nobody@example.com', 'pass');

      expect(result, isFalse);
      expect(
        container.read(authNotifierProvider).error,
        'No account found with this email.',
      );
    });

    test('too-many-requests: maps to rate-limit message', () async {
      fake.signInError = FirebaseAuthException(code: 'too-many-requests');

      final result = await container
          .read(authNotifierProvider.notifier)
          .signInWithEmail('user@example.com', 'pass');

      expect(result, isFalse);
      expect(
        container.read(authNotifierProvider).error,
        'Too many attempts. Please try again later.',
      );
    });

    test('unknown code: falls back to generic message', () async {
      fake.signInError = FirebaseAuthException(code: 'some-unknown-code');

      final result = await container
          .read(authNotifierProvider.notifier)
          .signInWithEmail('user@example.com', 'pass');

      expect(result, isFalse);
      expect(
        container.read(authNotifierProvider).error,
        'Authentication failed. Please try again.',
      );
    });

    test('clearError resets state', () async {
      fake.signInError = FirebaseAuthException(code: 'wrong-password');
      await container
          .read(authNotifierProvider.notifier)
          .signInWithEmail('user@example.com', 'bad');

      container.read(authNotifierProvider.notifier).clearError();

      final state = container.read(authNotifierProvider);
      expect(state.error, isNull);
      expect(state.isLoading, isFalse);
    });
  });

  group('AuthNotifier — signOut', () {
    test('delegates to service', () async {
      final fake = FakeAuthService();
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.notifier).signOut();

      expect(fake.signedOut, isTrue);
    });
  });

  group('AuthNotifier — registerWithEmail', () {
    test('success: returns true, clears loading', () async {
      final fake = FakeAuthService();
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      final result = await container
          .read(authNotifierProvider.notifier)
          .registerWithEmail(
            email: 'new@example.com',
            password: 'password123',
            displayName: 'Alice',
          );

      expect(result, isTrue);
      expect(container.read(authNotifierProvider).isLoading, isFalse);
      expect(container.read(authNotifierProvider).error, isNull);
    });

    test('email-already-in-use: maps to correct message', () async {
      final fake = FakeAuthService()
        ..registerError =
            FirebaseAuthException(code: 'email-already-in-use');
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      final result = await container
          .read(authNotifierProvider.notifier)
          .registerWithEmail(
            email: 'taken@example.com',
            password: 'password123',
            displayName: 'Bob',
          );

      expect(result, isFalse);
      expect(
        container.read(authNotifierProvider).error,
        'An account already exists with this email.',
      );
    });
  });
}
