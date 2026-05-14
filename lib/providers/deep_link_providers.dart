import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/deep_link_service.dart';
import '../services/firebase_deep_link_service.dart';

final deepLinkServiceProvider = Provider<DeepLinkService>(
  (ref) => FirebaseDeepLinkService(),
);

/// Fires whenever the running app is opened via a deep link.
/// Watch this in your router or a top-level widget to handle incoming links.
///
/// Example:
/// ```dart
/// ref.listen(incomingDeepLinkProvider, (_, next) {
///   next.whenData((link) => context.go(link.path));
/// });
/// ```
final incomingDeepLinkProvider = StreamProvider<DeepLinkData>((ref) {
  return ref.watch(deepLinkServiceProvider).incomingLinks;
});

/// Checked once at startup: the link the app was opened from (cold start),
/// or a deferred link recorded before the app was installed.
/// Returns null when there is no link to handle.
///
/// Example:
/// ```dart
/// ref.listen(initialDeepLinkProvider, (_, next) {
///   next.whenData((link) { if (link != null) context.go(link.path); });
/// });
/// ```
final initialDeepLinkProvider = FutureProvider<DeepLinkData?>((ref) async {
  final service = ref.read(deepLinkServiceProvider);
  final initial = await service.getInitialLink();
  if (initial != null) return initial;
  return service.claimDeferredLink();
});
