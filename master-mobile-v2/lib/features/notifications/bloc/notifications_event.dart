part of 'notifications_bloc.dart';

sealed class NotificationsEvent {
  const NotificationsEvent();
}

class NotificationsRequested extends NotificationsEvent {
  const NotificationsRequested();
}

class NotificationRead extends NotificationsEvent {
  const NotificationRead(this.id);
  final String id;
}

class NotificationsAllRead extends NotificationsEvent {
  const NotificationsAllRead();
}

class NotificationsUnreadRefreshed extends NotificationsEvent {
  const NotificationsUnreadRefreshed();
}
