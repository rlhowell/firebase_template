import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Uniform state for any write operation: idle → loading → success/failure.
class MutationState {
  final bool isLoading;
  final String? error;

  const MutationState({this.isLoading = false, this.error});

  bool get hasError => error != null;
}

/// Base class for Riverpod [Notifier]s that perform one-shot write operations
/// (form submissions, sign-in, purchases, etc.).
///
/// Subclasses call [run] instead of manually managing loading/error state:
///
/// ```dart
/// Future<bool> save(String value) => run(
///   () => ref.read(myServiceProvider).save(value),
///   mapError: (e) => 'Save failed: ${e}',
/// );
/// ```
abstract class MutationNotifier extends Notifier<MutationState> {
  @override
  MutationState build() => const MutationState();

  /// Executes [action] and manages loading/error state automatically.
  ///
  /// Returns `true` on success, `false` on error or cancellation.
  ///
  /// - [mapError] converts the thrown object to a user-facing string. Defaults
  ///   to `'Something went wrong. Please try again.'`.
  /// - [ignoreError] suppresses the error and returns `false` cleanly (use for
  ///   user-initiated cancellations like dismissed sign-in sheets).
  Future<bool> run(
    Future<void> Function() action, {
    String Function(Object e)? mapError,
    bool Function(Object e)? ignoreError,
  }) async {
    state = const MutationState(isLoading: true);
    try {
      await action();
      state = const MutationState();
      return true;
    } catch (e) {
      if (ignoreError?.call(e) == true) {
        state = const MutationState();
        return false;
      }
      state = MutationState(
        error: mapError?.call(e) ?? 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  void clearError() => state = const MutationState();
}
