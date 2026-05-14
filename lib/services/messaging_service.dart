import 'package:firebase_messaging/firebase_messaging.dart';

class MessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Call this at the right moment in your UX (e.g. post-onboarding, not on
  /// cold launch) so the system permission dialog appears contextually.
  Future<NotificationSettings> requestPermission() =>
      _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

  /// Returns the FCM registration token for this device. Null if permission
  /// has not been granted on iOS, or if the token is not yet available.
  Future<String?> getToken() => _messaging.getToken();

  /// Emits a new token whenever FCM rotates it. Send each new value to your
  /// backend to keep the stored token current.
  Stream<String> get tokenRefresh => _messaging.onTokenRefresh;

  /// Messages received while the app is in the foreground.
  Stream<RemoteMessage> get foregroundMessages => FirebaseMessaging.onMessage;

  /// Emits when the user taps a notification that brings the app to the
  /// foreground from the background (not from terminated).
  Stream<RemoteMessage> get notificationOpens =>
      FirebaseMessaging.onMessageOpenedApp;

  /// The notification that launched the app from a terminated state, or null
  /// if the app was opened normally. Check this once on startup.
  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();
}
