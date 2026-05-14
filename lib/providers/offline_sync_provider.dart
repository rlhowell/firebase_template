import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firestore_offline_sync_service.dart';
import '../services/offline_sync_service.dart';
import '../utils/app_logger.dart';
import 'auth_providers.dart';

final offlineSyncServiceProvider = Provider<OfflineSyncService>(
  (ref) => FirestoreOfflineSyncService(),
);

/// Side-effect provider: starts collection listeners on sign-in and cancels
/// them on sign-out, keeping configured collections in the Firestore disk
/// cache. Must be watched at the root of the widget tree (App) to stay active.
final offlineSyncProvider = Provider<void>((ref) {
  final service = ref.watch(offlineSyncServiceProvider);

  ref.listen(authStateProvider, (previous, next) async {
    final user = next.valueOrNull;
    if (user != null) {
      try {
        await service.startSync(user.uid);
      } catch (e, s) {
        log.e('Failed to start offline sync', error: e, stackTrace: s);
      }
    } else {
      try {
        await service.stopSync();
      } catch (e, s) {
        log.e('Failed to stop offline sync', error: e, stackTrace: s);
      }
    }
  });

  ref.onDispose(() => service.stopSync());
});
