part of 'chat_bloc.dart';

class ChatState {
  const ChatState({
    this.loading = false,
    this.sending = false,
    this.messages = const [],
    this.error,
  });

  final bool loading;
  final bool sending;
  final List<ChatMessage> messages;
  final String? error;

  ChatState copyWith({
    bool? loading,
    bool? sending,
    List<ChatMessage>? messages,
    String? error,
    bool clearError = false,
  }) =>
      ChatState(
        loading: loading ?? this.loading,
        sending: sending ?? this.sending,
        messages: messages ?? this.messages,
        error: clearError ? null : (error ?? this.error),
      );
}
