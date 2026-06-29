import 'package:itez_mobile/core/api_client/api_client.dart';
import 'package:itez_mobile/core/api_client/urls.dart';
import 'package:itez_mobile/features/chat/models/chat_message.dart';

class ChatRepository {
  ChatRepository(this._client);
  final ApiClient _client;

  Future<List<ChatMessage>> history(int orderId) async {
    final json =
        await _client.getJson(Urls.chatMessages(orderId), requireAuth: true);
    final raw = json['messages'] ?? json['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ChatMessage.fromJson)
        .toList();
  }

  Future<ChatMessage> send(int orderId, String text) async {
    final json = await _client.postJson(
      Urls.chatMessages(orderId),
      body: {'text': text},
      requireAuth: true,
    );
    final raw = json['message'] ?? json;
    if (raw is! Map<String, dynamic>) {
      throw StateError('POST chat message returned no `message`');
    }
    return ChatMessage.fromJson(raw);
  }

  Future<int> unread() async {
    final json = await _client.getJson(Urls.chatUnread, requireAuth: true);
    return (json['count'] as num?)?.toInt() ?? 0;
  }
}
