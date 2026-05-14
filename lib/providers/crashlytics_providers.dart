import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

/// Keeps the Crashlytics user identifier in sync with Firebase auth state so
/// crash reports are linked to the right user. Must be watched at the root of
/// the widget tree (App) to stay active.
final crashlyticsIdentitySyncProvider = Provider<void>((ref) {
  ref.listen(authStateProvider, (previous, next) {
    final user = next.valueOrNull;
    if (user != null) {
      FirebaseCrashlytics.instance.setUserIdentifier(user.uid);
    } else if (previous?.valueOrNull != null) {
      FirebaseCrashlytics.instance.setUserIdentifier('');
    }
  });
});
