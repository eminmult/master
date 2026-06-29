import 'package:itez_mobile/core/api_client/api_client.dart';
import 'package:itez_mobile/core/api_client/urls.dart';
import 'package:itez_mobile/features/notifications/models/notification_model.dart';

class NotificationRepository {
  NotificationRepository(this._client);
  final ApiClient _client;

  Future<List<NotificationModel>> list() async {
    final json = await _client.getJson(Urls.notifications, requireAuth: true);
    final raw = json['notifications'] ?? json['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();
  }

  Future<int> unreadCount() async {
    final json = await _client.getJson(
      Urls.notificationsUnreadCount,
      requireAuth: true,
    );
    return (json['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(String id) async {
    // ID — UUID; URL helper в Urls собран на int (orderId), для UUID
    // собираем путь явно.
    await _client.postJson(
      '${Urls.notifications}/$id/read',
      requireAuth: true,
    );
  }

  Future<void> markAllRead() async {
    await _client.postJson(Urls.notificationsReadAll, requireAuth: true);
  }
}
