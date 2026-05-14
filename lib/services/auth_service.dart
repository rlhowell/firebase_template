import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthService {
  Stream<User?> get authStateChanges;
  User? get currentUser;

  Future<void> signInWithEmail(String email, String password);
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  });
  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) verificationCompleted,
    required void Function(FirebaseAuthException) verificationFailed,
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(String verificationId) codeAutoRetrievalTimeout,
  });
  Future<void> signInWithPhoneCredential(String verificationId, String smsCode);
  Future<void> signInWithCredential(AuthCredential credential);
  Future<void> signOut();
}
