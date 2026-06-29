import 'package:itez_mobile/core/utils/json_parse.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  final int id;
  final int senderId;
  final String? senderName;
  final String text;
  final DateTime? createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    return ChatMessage(
      id: parseInt(json['id']),
      senderId: parseInt(
        json['sender_id'] ?? (sender is Map ? sender['id'] : null),
      ),
      senderName: sender is Map
          ? (sender['first_name'] ?? sender['full_name'])?.toString()
          : null,
      text: (json['text'] ?? json['message'] ?? '').toString(),
      createdAt: parseDate(json['created_at']),
    );
  }
}
