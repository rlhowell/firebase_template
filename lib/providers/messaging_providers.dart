import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/messaging_service.dart';

final messagingServiceProvider =
    Provider<MessagingService>((ref) => MessagingService());

/// The current FCM registration token. Re-fetch after calling requestPermission().
final fcmTokenProvider = FutureProvider<String?>((ref) {
  return ref.watch(messagingServiceProvider).getToken();
});

/// Stream of messages received while the app is foregrounded.
/// Listen here to show an in-app banner or update local state.
final foregroundMessageProvider = StreamProvider<RemoteMessage>((ref) {
  return ref.watch(messagingServiceProvider).foregroundMessages;
});

/// Emits when the user taps a background notification to open the app.
/// Use this to navigate to the relevant screen.
final notificationOpenedProvider = StreamProvider<RemoteMessage>((ref) {
  return ref.watch(messagingServiceProvider).notificationOpens;
});

/// The notification that cold-launched the app, or null for a normal launch.
/// Watch this early in the widget tree and navigate once the value is ready.
final initialMessageProvider = FutureProvider<RemoteMessage?>((ref) {
  return ref.watch(messagingServiceProvider).getInitialMessage();
});
