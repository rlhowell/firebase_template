import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'bootstrap.dart';
import 'config/app_config.dart';
import 'firebase_options/firebase_options_staging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.setup(
    environment: AppEnvironment.staging,
    appName: 'MyApp Staging',
    bundleId: const String.fromEnvironment(
      'APP_BUNDLE_ID',
      defaultValue: 'com.yourcompany.app.staging',
    ),
    deepLinkHost: const String.fromEnvironment('DEEP_LINK_HOST'),
    customScheme: const String.fromEnvironment(
      'CUSTOM_SCHEME',
      defaultValue: 'yourapp',
    ),
    functionsRegion: const String.fromEnvironment(
      'FUNCTIONS_REGION',
      defaultValue: 'europe-west2',
    ),
    revenueCatKeyApple: const String.fromEnvironment('REVENUE_CAT_KEY_APPLE'),
    revenueCatKeyAndroid:
        const String.fromEnvironment('REVENUE_CAT_KEY_ANDROID'),
    appCheckRecaptchaKey:
        const String.fromEnvironment('APP_CHECK_RECAPTCHA_KEY'),
  );
  await bootstrap(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    appCheckAndroid: AndroidProvider.debug,
    appCheckApple: AppleProvider.debug,
    appCheckWebSiteKey: AppConfig.instance.appCheckRecaptchaKey,
    enableCrashlyticsCollection: true,
    remoteConfigFetchInterval: const Duration(minutes: 5),
  );
  runApp(const ProviderScope(child: App()));
}
