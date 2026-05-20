import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required int id,
    @JsonKey(name: 'order_id') required int orderId,
    @JsonKey(name: 'application_id') int? applicationId,
    @JsonKey(name: 'sender_id') required int senderId,
    required String text,
    @JsonKey(name: 'read_at') DateTime? readAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
}
