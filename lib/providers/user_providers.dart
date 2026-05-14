import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../services/firebase_user_service.dart';
import '../services/user_service.dart';
import '../utils/app_logger.dart';
import 'auth_providers.dart';

final userServiceProvider = Provider<UserService>(
  (ref) => FirebaseUserService(),
);

/// Streams the signed-in user's Firestore profile document.
/// Emits null when signed out or before the document is created.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(userServiceProvider).streamProfile(user.uid);
});

/// Side-effect provider: creates the Firestore user document on first sign-in
/// for any auth method (email, Google, Apple, phone). Must be watched at the
/// root of the widget tree (App) to stay active.
final userProfileSyncProvider = Provider<void>((ref) {
  ref.listen(authStateProvider, (previous, next) async {
    final user = next.valueOrNull;
    if (user == null) return;
    try {
      await ref.read(userServiceProvider).createProfileIfAbsent(user);
    } catch (e, s) {
      log.e('Failed to create user profile', error: e, stackTrace: s);
    }
  });
});
