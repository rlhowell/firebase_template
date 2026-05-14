abstract class OfflineSyncService {
  /// Opens listeners on all configured collections, populating the Firestore
  /// disk cache. [uid] is used for user-scoped collections.
  Future<void> startSync(String uid);

  /// Cancels all active listeners.
  Future<void> stopSync();
}
