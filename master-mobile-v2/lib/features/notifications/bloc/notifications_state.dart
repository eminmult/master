part of 'notifications_bloc.dart';

class NotificationsState {
  const NotificationsState({
    this.loading = false,
    this.items = const [],
    this.unreadCount = 0,
    this.error,
  });

  final bool loading;
  final List<NotificationModel> items;
  final int unreadCount;
  final String? error;

  NotificationsState copyWith({
    bool? loading,
    List<NotificationModel>? items,
    int? unreadCount,
    String? error,
    bool clearError = false,
  }) =>
      NotificationsState(
        loading: loading ?? this.loading,
        items: items ?? this.items,
        unreadCount: unreadCount ?? this.unreadCount,
        error: clearError ? null : (error ?? this.error),
      );
}
