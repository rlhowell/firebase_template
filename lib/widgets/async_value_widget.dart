import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders any [AsyncValue] with consistent loading/error/data states.
///
/// ```dart
/// AsyncValueWidget(
///   value: ref.watch(productsProvider),
///   onRetry: () => ref.invalidate(productsProvider),
///   data: (products) => ProductList(products: products),
/// )
/// ```
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.skipLoadingOnReload = true,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;

  /// Called when the user taps "Try again". Typically `ref.invalidate(provider)`
  /// or a notifier method. Omit to hide the retry button.
  final VoidCallback? onRetry;

  /// When true (default), shows existing data while the provider is reloading
  /// instead of replacing it with a spinner.
  final bool skipLoadingOnReload;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnReload: skipLoadingOnReload,
      data: data,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AsyncErrorWidget(error: e, onRetry: onRetry),
    );
  }
}

/// Standard error state widget — an icon, a message, and an optional retry button.
///
/// Used automatically by [AsyncValueWidget], but can also be used stand-alone:
///
/// ```dart
/// if (state.hasError)
///   AsyncErrorWidget(error: state.error!, onRetry: () => ref.invalidate(p))
/// ```
class AsyncErrorWidget extends StatelessWidget {
  const AsyncErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.message,
  });

  final Object error;
  final VoidCallback? onRetry;

  /// Override the displayed message. Defaults to `'Something went wrong.'`.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message ?? 'Something went wrong.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
