import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/remote_config_defaults.dart';

/// Exposes the already-initialised FirebaseRemoteConfig instance.
/// Initialisation (defaults, fetch, activate) happens in bootstrap() before
/// runApp, so this provider is always synchronously ready.
final remoteConfigProvider = Provider<FirebaseRemoteConfig>(
  (ref) => FirebaseRemoteConfig.instance,
);

/// Typed value accessors. Add a getter here for every RemoteConfigKey.
///
/// Usage in a widget:
///   final rc = ref.watch(remoteConfigProvider);
///   if (rc.showNewFeature) { ... }
extension RemoteConfigValues on FirebaseRemoteConfig {
  int get minimumBuildNumber => getInt(RemoteConfigKeys.minimumBuildNumber);

  // bool get showNewFeature => getBool(RemoteConfigKeys.showNewFeature);
}

/// True when the running build is below the Remote Config minimum.
/// Checked in App to gate all navigation behind ForceUpdateScreen.
final versionCheckProvider = FutureProvider<bool>((ref) async {
  final info = await PackageInfo.fromPlatform();
  final minimum = ref.read(remoteConfigProvider).minimumBuildNumber;
  final current = int.tryParse(info.buildNumber) ?? 0;
  return minimum > 0 && current < minimum;
});
