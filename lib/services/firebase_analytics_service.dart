import 'package:firebase_analytics/firebase_analytics.dart';

import 'analytics_service.dart';

class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  /// Use this observer in GoRouter's `observers` list to log screen views.
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  @override
  Future<void> logSignIn(String method) =>
      _analytics.logLogin(loginMethod: method);

  @override
  Future<void> logSignUp(String method) =>
      _analytics.logSignUp(signUpMethod: method);

  @override
  Future<void> logSignOut() => _analytics.logEvent(name: 'sign_out');

  @override
  Future<void> setUserId(String? uid) => _analytics.setUserId(id: uid);

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) =>
      _analytics.logEvent(name: name, parameters: parameters);
}
