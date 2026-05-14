import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Result returned from [PaginatedNotifier.fetchPage].
class PageResult<T> {
  const PageResult({
    required this.items,
    required this.cursor,
    required this.hasMore,
  });

  final List<T> items;

  /// The last [DocumentSnapshot] in this page — pass as [cursor] to the next
  /// call to get the following page. `null` when there are no more pages.
  final DocumentSnapshot? cursor;
  final bool hasMore;
}

/// Immutable state held by [PaginatedNotifier].
class PaginatedState<T> {
  const PaginatedState({
    this.items = const [],
    this.isLoadingFirst = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<T> items;
  final bool isLoadingFirst;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  bool get isEmpty => items.isEmpty && !isLoadingFirst;

  PaginatedState<T> copyWith({
    List<T>? items,
    bool? isLoadingFirst,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) =>
      PaginatedState(
        items: items ?? this.items,
        isLoadingFirst: isLoadingFirst ?? this.isLoadingFirst,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Abstract base for cursor-paginated Firestore lists.
///
/// **Usage:**
///
/// ```dart
/// class ProductsNotifier extends PaginatedNotifier<Product> {
///   @override
///   Future<PageResult<Product>> fetchPage(DocumentSnapshot? cursor, int limit) async {
///     var q = FirebaseFirestore.instance
///         .collection('products')
///         .orderBy('name')
///         .limit(limit);
///     if (cursor != null) q = q.startAfterDocument(cursor);
///     final snap = await q.get();
///     return PageResult(
///       items: snap.docs.map(Product.fromFirestore).toList(),
///       cursor: snap.docs.lastOrNull,
///       hasMore: snap.docs.length == limit,
///     );
///   }
/// }
///
/// final productsProvider =
///     NotifierProvider<ProductsNotifier, PaginatedState<Product>>(ProductsNotifier.new);
/// ```
///
/// In your widget:
/// ```dart
/// final state = ref.watch(productsProvider);
/// PaginatedListView(
///   state: state,
///   onLoadMore: () => ref.read(productsProvider.notifier).loadMore(),
///   onRefresh: () => ref.read(productsProvider.notifier).refresh(),
///   itemBuilder: (ctx, product, _) => ProductTile(product: product),
/// )
/// ```
abstract class PaginatedNotifier<T> extends Notifier<PaginatedState<T>> {
  static const int defaultPageSize = 20;

  DocumentSnapshot? _cursor;

  @override
  PaginatedState<T> build() {
    Future.microtask(loadMore);
    return const PaginatedState();
  }

  Future<void> loadMore() async {
    if (!state.hasMore) return;
    if (state.isLoadingFirst || state.isLoadingMore) return;

    if (state.items.isEmpty) {
      state = state.copyWith(isLoadingFirst: true, clearError: true);
    } else {
      state = state.copyWith(isLoadingMore: true, clearError: true);
    }

    try {
      final result = await fetchPage(_cursor, defaultPageSize);
      _cursor = result.cursor;
      state = state.copyWith(
        items: [...state.items, ...result.items],
        isLoadingFirst: false,
        isLoadingMore: false,
        hasMore: result.hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingFirst: false,
        isLoadingMore: false,
        error: e,
      );
    }
  }

  Future<void> refresh() async {
    _cursor = null;
    state = const PaginatedState();
    await loadMore();
  }

  /// Fetch one page of results. Start after [cursor] if non-null.
  /// Return [PageResult.hasMore] = false when this is the last page.
  Future<PageResult<T>> fetchPage(DocumentSnapshot? cursor, int limit);
}
