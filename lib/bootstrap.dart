import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'config/app_config.dart';
import 'config/remote_config_defaults.dart';

@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  // Add background processing here, e.g. update a local database or badge count.
  // Avoid heavy work — this isolate can be killed by the OS at any time.
}

Future<void> bootstrap({
  required FirebaseOptions firebaseOptions,
  required AndroidProvider appCheckAndroid,
  required AppleProvider appCheckApple,
  required bool enableCrashlyticsCollection,
  required Duration remoteConfigFetchInterval,
  required String appCheckWebSiteKey,
}) async {
  await Firebase.initializeApp(options: firebaseOptions);
  _setupFirestore();
  await _setupAppCheck(appCheckAndroid, appCheckApple, appCheckWebSiteKey);
  await _setupCrashlytics(enableCrashlyticsCollection);
  await _setupRemoteConfig(remoteConfigFetchInterval);
  await _setupMessaging();
  await _setupRevenueCat();
}

void _setupFirestore() {
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
}

/// On web, App Check needs a reCAPTCHA Enterprise site key registered in the
/// Firebase console. Activating without one throws, so it is skipped while
/// [webSiteKey] is empty.
Future<void> _setupAppCheck(
  AndroidProvider android,
  AppleProvider apple,
  String webSiteKey,
) async {
  if (kIsWeb) {
    if (webSiteKey.isEmpty) return;
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaEnterpriseProvider(webSiteKey),
    );
    return;
  }
  await FirebaseAppCheck.instance.activate(
    androidProvider: android,
    appleProvider: apple,
  );
}

Future<void> _setupCrashlytics(bool enableCollection) async {
  // firebase_crashlytics has no web implementation — Flutter's default error
  // handling applies there instead.
  if (kIsWeb) return;
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(enableCollection);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

Future<void> _setupRemoteConfig(Duration fetchInterval) async {
  final rc = FirebaseRemoteConfig.instance;
  await rc.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(seconds: 10),
    minimumFetchInterval: fetchInterval,
  ));
  await rc.setDefaults(remoteConfigDefaults);
  try {
    await rc.fetchAndActivate();
  } catch (_) {
    // Network unavailable — defaults and cached values are used.
  }
}

Future<void> _setupMessaging() async {
  // Web FCM needs a service worker (web/firebase-messaging-sw.js) and a VAPID
  // key passed to getToken(); set those up before enabling this on web.
  if (kIsWeb) return;
  FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
}

Future<void> _setupRevenueCat() async {
  // purchases_flutter has no web implementation.
  if (kIsWeb) return;
  final config = AppConfig.instance;
  final apiKey = defaultTargetPlatform == TargetPlatform.iOS
      ? config.revenueCatKeyApple
      : config.revenueCatKeyAndroid;
  if (apiKey.isEmpty) return;
  await Purchases.configure(PurchasesConfiguration(apiKey));
}
