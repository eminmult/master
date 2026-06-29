import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itez_mobile/core/exceptions/app_exception.dart';
import 'package:itez_mobile/features/notifications/models/notification_model.dart';
import 'package:itez_mobile/features/notifications/repositories/notification_repository.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

/// Глобальный BLoC уведомлений. Используется как badge в bottom-nav,
/// а также страница со списком. Подписка на realtime (Reverb) добавляется
/// поверх — push новых уведомлений через `inject` функцию.
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc(this._repo) : super(const NotificationsState()) {
    on<NotificationsRequested>(_onRequested);
    on<NotificationRead>(_onRead);
    on<NotificationsAllRead>(_onAllRead);
    on<NotificationsUnreadRefreshed>(_onUnreadOnly);
  }

  final NotificationRepository _repo;

  Future<void> _onRequested(
    NotificationsRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final items = await _repo.list();
      final unread = items.where((n) => n.isUnread).length;
      emit(state.copyWith(loading: false, items: items, unreadCount: unread));
    } on AppException catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e.message ?? 'Не удалось загрузить уведомления',
      ));
    }
  }

  Future<void> _onRead(
    NotificationRead event,
    Emitter<NotificationsState> emit,
  ) async {
    // Оптимистично помечаем — даже если сервер вернёт ошибку, юзер видит
    // прогресс, обновим в фоне при следующем pull.
    final patched = state.items.map((n) {
      if (n.id != event.id) return n;
      return NotificationModel(
        id: n.id,
        type: n.type,
        data: n.data,
        readAt: DateTime.now(),
        createdAt: n.createdAt,
      );
    }).toList();
    final unread = patched.where((n) => n.isUnread).length;
    emit(state.copyWith(items: patched, unreadCount: unread));

    try {
      await _repo.markRead(event.id);
    } on AppException {/* tolerate: refresh later */}
  }

  Future<void> _onAllRead(
    NotificationsAllRead event,
    Emitter<NotificationsState> emit,
  ) async {
    final patched = state.items
        .map((n) => NotificationModel(
              id: n.id,
              type: n.type,
              data: n.data,
              readAt: n.readAt ?? DateTime.now(),
              createdAt: n.createdAt,
            ))
        .toList();
    emit(state.copyWith(items: patched, unreadCount: 0));
    try {
      await _repo.markAllRead();
    } on AppException {/* tolerate */}
  }

  Future<void> _onUnreadOnly(
    NotificationsUnreadRefreshed event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      final count = await _repo.unreadCount();
      emit(state.copyWith(unreadCount: count));
    } on AppException {/* silent */}
  }
}
