import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/analytics_service.dart';
import '../services/firebase_analytics_service.dart';
import '../utils/app_logger.dart';
import 'auth_providers.dart';

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => FirebaseAnalyticsService(),
);

/// Side-effect provider: syncs the Firebase Analytics user ID with auth state.
/// Must be watched at the root of the widget tree (App) to stay active.
final analyticsIdentitySyncProvider = Provider<void>((ref) {
  ref.listen(authStateProvider, (previous, next) async {
    final user = next.valueOrNull;
    try {
      await ref.read(analyticsServiceProvider).setUserId(user?.uid);
    } catch (e, s) {
      log.w('Analytics userId sync failed', error: e, stackTrace: s);
    }
  });
});
