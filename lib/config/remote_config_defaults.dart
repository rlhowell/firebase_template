/// Remote Config key constants. Add a constant here for every key you define
/// in the Firebase Console so there's a single source of truth.
abstract final class RemoteConfigKeys {
  /// Minimum build number allowed to run the app. Set to 0 to disable.
  /// When the running build number is below this value, ForceUpdateScreen
  /// is shown and all navigation is blocked.
  static const String minimumBuildNumber = 'minimum_build_number';

  // static const String showNewFeature = 'show_new_feature';
}

/// Default values used when the device is offline or before the first fetch.
/// Every key defined in RemoteConfigKeys must have a default here.
const Map<String, dynamic> remoteConfigDefaults = {
  RemoteConfigKeys.minimumBuildNumber: 0,

  // RemoteConfigKeys.showNewFeature: false,
};
