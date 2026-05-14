/// Describes one Firestore collection to keep warm in the local offline cache.
///
/// Listed collections are pinned by maintaining an active listener while the
/// user is signed in, so Firestore's disk cache always has fresh data for them
/// — even before the user navigates to a screen that displays them.
class OfflineCollection {
  /// Firestore collection path (e.g. `'products'` or `'users'`).
  final String collection;

  /// When true, the listener is filtered: `.where(uidField, isEqualTo: uid)`.
  /// Use for per-user data so you only cache documents belonging to the
  /// signed-in user.
  final bool userScoped;

  /// Document field that holds the user's UID. Ignored when [userScoped] is
  /// false. Defaults to `'uid'`; change to e.g. `'userId'` if your schema
  /// uses a different field name.
  final String uidField;

  const OfflineCollection(
    this.collection, {
    this.userScoped = false,
    this.uidField = 'uid',
  });
}

/// Collections kept in the local Firestore disk cache while the user is
/// signed in.
///
/// - **Global collection** (all documents):
///   `OfflineCollection('products')`
///
/// - **Per-user collection** (filtered by uid field):
///   `OfflineCollection('orders', userScoped: true, uidField: 'userId')`
///
/// Add or remove entries here to control what the app can read offline.
const List<OfflineCollection> offlineCollections = [
  // Current user's profile document — always keep this.
  OfflineCollection('users', userScoped: true),

  // ── Add your own collections below ─────────────────────────────────────
  // OfflineCollection('products'),
  // OfflineCollection('categories'),
  // OfflineCollection('orders', userScoped: true, uidField: 'userId'),
];
