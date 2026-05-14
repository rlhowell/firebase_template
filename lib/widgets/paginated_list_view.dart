import 'package:flutter/material.dart';

import '../providers/paginated_notifier.dart';
import 'async_value_widget.dart';

/// A scrollable list that calls [onLoadMore] when the user reaches the bottom,
/// and supports pull-to-refresh via [onRefresh].
///
/// Pair with [PaginatedNotifier] and pass its [PaginatedState] directly.
class PaginatedListView<T> extends StatefulWidget {
  const PaginatedListView({
    super.key,
    required this.state,
    required this.itemBuilder,
    required this.onLoadMore,
    this.onRefresh,
    this.loadMoreThreshold = 200,
    this.emptyWidget,
    this.padding,
    this.separatorBuilder,
  });

  final PaginatedState<T> state;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<void> Function() onLoadMore;
  final Future<void> Function()? onRefresh;

  /// How many pixels from the bottom to trigger [onLoadMore].
  final double loadMoreThreshold;

  /// Shown when [PaginatedState.isEmpty] is true.
  final Widget? emptyWidget;

  final EdgeInsetsGeometry? padding;
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - widget.loadMoreThreshold) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    // First-load spinner
    if (state.isLoadingFirst) {
      return const Center(child: CircularProgressIndicator());
    }

    // First-load error
    if (state.error != null && state.items.isEmpty) {
      return AsyncErrorWidget(
        error: state.error!,
        onRetry: widget.onLoadMore,
      );
    }

    // Empty state
    if (state.isEmpty) {
      return widget.emptyWidget ?? const SizedBox.shrink();
    }

    final itemCount = state.items.length + (state.isLoadingMore ? 1 : 0);

    final listView = widget.separatorBuilder != null
        ? ListView.separated(
            controller: _scrollController,
            padding: widget.padding,
            itemCount: itemCount,
            separatorBuilder: widget.separatorBuilder!,
            itemBuilder: _buildItem,
          )
        : ListView.builder(
            controller: _scrollController,
            padding: widget.padding,
            itemCount: itemCount,
            itemBuilder: _buildItem,
          );

    return widget.onRefresh != null
        ? RefreshIndicator(onRefresh: widget.onRefresh!, child: listView)
        : listView;
  }

  Widget _buildItem(BuildContext context, int index) {
    if (index >= widget.state.items.length) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return widget.itemBuilder(context, widget.state.items[index], index);
  }
}
