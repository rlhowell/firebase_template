import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/phone_verification_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';

/// Bridges Riverpod's authStateProvider to GoRouter's refreshListenable.
class _RouterNotifier extends AsyncNotifier<void> implements Listenable {
  VoidCallback? _listener;

  @override
  Future<void> build() async {
    ref.listen(authStateProvider, (_, __) => _listener?.call());
  }

  @override
  void addListener(VoidCallback listener) => _listener = listener;

  @override
  void removeListener(VoidCallback listener) => _listener = null;

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = ref.read(authStateProvider);
    if (auth.isLoading) return null;
    final isAuthed = auth.valueOrNull != null;
    final loc = state.matchedLocation;
    final onPublicPage = loc.startsWith('/auth') || loc == '/onboarding';
    if (isAuthed && onPublicPage) return '/home';
    if (!isAuthed && !onPublicPage) return '/onboarding';
    return null;
  }
}

final _routerNotifierProvider =
    AsyncNotifierProvider<_RouterNotifier, void>(_RouterNotifier.new);

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider.notifier);
  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    observers: [
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
    ],
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/phone',
        builder: (context, state) => PhoneVerificationScreen(
          phoneNumber: state.extra as String? ?? '',
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
});
