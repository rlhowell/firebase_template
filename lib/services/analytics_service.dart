abstract class AnalyticsService {
  // ── Auth events ────────────────────────────────────────────────────────────

  /// Call after a successful sign-in. [method] should be one of:
  /// `'email'`, `'google'`, `'apple'`, `'phone'`.
  Future<void> logSignIn(String method);

  /// Call after a successful account creation.
  Future<void> logSignUp(String method);

  /// Call after the user signs out.
  Future<void> logSignOut();

  // ── Identity ───────────────────────────────────────────────────────────────

  /// Set the analytics user ID. Pass `null` to clear it on sign-out.
  Future<void> setUserId(String? uid);

  // ── Generic ────────────────────────────────────────────────────────────────

  /// Log any custom event. Keep [name] under 40 characters, snake_case.
  Future<void> logEvent(String name, {Map<String, Object>? parameters});
}
