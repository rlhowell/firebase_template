import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/store_config.dart';

/// Shown when the running build number is below the Remote Config
/// `minimum_build_number` threshold. Cannot be dismissed — the user must
/// update the app to proceed.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  Future<void> _openStore() async {
    final uri = defaultTargetPlatform == TargetPlatform.iOS
        ? Uri.parse(
            'https://apps.apple.com/app/id${StoreConfig.appStoreId}',
          )
        : Uri.parse(
            'https://play.google.com/store/apps/details?id=${StoreConfig.playStorePackage}',
          );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.system_update_outlined,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Update Required',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'A new version of the app is required to continue. '
                'Please update from the store.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: _openStore,
                child: const Text('Update Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
