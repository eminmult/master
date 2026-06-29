import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itez_mobile/core/exceptions/app_exception.dart';
import 'package:itez_mobile/features/chat/models/chat_message.dart';
import 'package:itez_mobile/features/chat/repositories/chat_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';

/// Чат по конкретному заказу. Realtime новые сообщения добавляются через
/// `ChatMessageReceived` (источник — Reverb-канал `private-order.{id}`).
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc(this._repo) : super(const ChatState()) {
    on<ChatRequested>(_onRequested);
    on<ChatSent>(_onSent);
    on<ChatMessageReceived>(_onReceived);
  }

  final ChatRepository _repo;
  int? _orderId;

  Future<void> _onRequested(
    ChatRequested event,
    Emitter<ChatState> emit,
  ) async {
    _orderId = event.orderId;
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final messages = await _repo.history(event.orderId);
      emit(state.copyWith(loading: false, messages: messages));
    } on AppException catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e.message ?? 'Не удалось загрузить чат',
      ));
    }
  }

  Future<void> _onSent(ChatSent event, Emitter<ChatState> emit) async {
    final orderId = _orderId;
    if (orderId == null || event.text.trim().isEmpty) return;
    emit(state.copyWith(sending: true, clearError: true));
    try {
      final msg = await _repo.send(orderId, event.text.trim());
      emit(state.copyWith(
        sending: false,
        messages: [...state.messages, msg],
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        sending: false,
        error: e.message ?? 'Не удалось отправить',
      ));
    }
  }

  Future<void> _onReceived(
    ChatMessageReceived event,
    Emitter<ChatState> emit,
  ) async {
    // Дубликат игнорируем — Reverb может прийти раньше POST-ответа.
    if (state.messages.any((m) => m.id == event.message.id)) return;
    emit(state.copyWith(messages: [...state.messages, event.message]));
  }
}
