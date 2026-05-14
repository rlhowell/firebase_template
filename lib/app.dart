import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_config.dart';
import 'providers/analytics_provider.dart';
import 'providers/deep_link_providers.dart';
import 'providers/crashlytics_providers.dart';
import 'providers/offline_sync_provider.dart';
import 'providers/purchases_provider.dart';
import 'providers/remote_config_provider.dart';
import 'providers/user_providers.dart';
import 'router/app_router.dart';
import 'screens/force_update_screen.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Side-effect providers — must be watched here to stay alive.
    ref.watch(initialDeepLinkProvider);
    ref.watch(crashlyticsIdentitySyncProvider);
    ref.watch(userProfileSyncProvider);
    ref.watch(offlineSyncProvider);
    ref.watch(analyticsIdentitySyncProvider);
    ref.watch(purchasesIdentitySyncProvider);

    // Block navigation if a forced update is required.
    // While the check is still loading we proceed normally (avoids a flash).
    if (ref.watch(versionCheckProvider).valueOrNull == true) {
      return const MaterialApp(home: ForceUpdateScreen());
    }

    final router = ref.watch(routerProvider);
    final config = AppConfig.instance;

    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: !config.isProd,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}
