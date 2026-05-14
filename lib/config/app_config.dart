enum AppEnvironment { dev, staging, prod }

class AppConfig {
  static late final AppConfig instance;

  final AppEnvironment environment;
  final String appName;
  final String bundleId;
  final String deepLinkHost;
  final String customScheme;
  final String functionsRegion;
  final String revenueCatKeyApple;
  final String revenueCatKeyAndroid;

  AppConfig._({
    required this.environment,
    required this.appName,
    required this.bundleId,
    required this.deepLinkHost,
    required this.customScheme,
    required this.functionsRegion,
    required this.revenueCatKeyApple,
    required this.revenueCatKeyAndroid,
  });

  static AppConfig setup({
    required AppEnvironment environment,
    required String appName,
    required String bundleId,
    required String deepLinkHost,
    required String customScheme,
    required String functionsRegion,
    required String revenueCatKeyApple,
    required String revenueCatKeyAndroid,
  }) {
    instance = AppConfig._(
      environment: environment,
      appName: appName,
      bundleId: bundleId,
      deepLinkHost: deepLinkHost,
      customScheme: customScheme,
      functionsRegion: functionsRegion,
      revenueCatKeyApple: revenueCatKeyApple,
      revenueCatKeyAndroid: revenueCatKeyAndroid,
    );
    return instance;
  }

  bool get isDev => environment == AppEnvironment.dev;
  bool get isStaging => environment == AppEnvironment.staging;
  bool get isProd => environment == AppEnvironment.prod;

  String get environmentLabel => switch (environment) {
        AppEnvironment.dev => 'DEV',
        AppEnvironment.staging => 'STAGING',
        AppEnvironment.prod => '',
      };
}
