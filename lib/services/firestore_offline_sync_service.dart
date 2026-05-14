import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/offline_config.dart';
import '../utils/app_logger.dart';
import 'offline_sync_service.dart';

class FirestoreOfflineSyncService implements OfflineSyncService {
  FirestoreOfflineSyncService({
    FirebaseFirestore? firestore,
    List<OfflineCollection>? collections,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _collections = collections ?? offlineCollections;

  final FirebaseFirestore _db;
  final List<OfflineCollection> _collections;
  final List<StreamSubscription<dynamic>> _subs = [];

  @override
  Future<void> startSync(String uid) async {
    await stopSync();
    for (final col in _collections) {
      Query<Map<String, dynamic>> query = _db.collection(col.collection);
      if (col.userScoped) {
        query = query.where(col.uidField, isEqualTo: uid);
      }
      _subs.add(
        query.snapshots().listen(
          (_) {},
          onError: (Object e) =>
              log.w('Offline sync error [${col.collection}]', error: e),
        ),
      );
    }
    log.d('Offline sync started (${_collections.length} collection(s))');
  }

  @override
  Future<void> stopSync() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
    if (_subs.isEmpty) log.d('Offline sync stopped');
  }
}
