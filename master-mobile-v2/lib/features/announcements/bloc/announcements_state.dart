part of 'announcements_bloc.dart';

class AnnouncementsState {
  const AnnouncementsState({
    this.loading = false,
    this.loadingMore = false,
    this.items = const [],
    this.error,
    this.categoryId,
    this.sort = 'recent',
    this.endReached = false,
  });

  final bool loading;
  final bool loadingMore;
  final List<OrderModel> items;
  final String? error;
  final int? categoryId;
  final String sort;
  final bool endReached;

  AnnouncementsState copyWith({
    bool? loading,
    bool? loadingMore,
    List<OrderModel>? items,
    String? error,
    int? categoryId,
    String? sort,
    bool? endReached,
    bool clearError = false,
    bool clearCategory = false,
  }) =>
      AnnouncementsState(
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        items: items ?? this.items,
        error: clearError ? null : (error ?? this.error),
        categoryId:
            clearCategory ? null : (categoryId ?? this.categoryId),
        sort: sort ?? this.sort,
        endReached: endReached ?? this.endReached,
      );
}
