part of 'chat_bloc.dart';

sealed class ChatEvent {
  const ChatEvent();
}

class ChatRequested extends ChatEvent {
  const ChatRequested(this.orderId);
  final int orderId;
}

class ChatSent extends ChatEvent {
  const ChatSent(this.text);
  final String text;
}

class ChatMessageReceived extends ChatEvent {
  const ChatMessageReceived(this.message);
  final ChatMessage message;
}
