import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itez_mobile/core/exceptions/app_exception.dart';
import 'package:itez_mobile/core/utils/json_parse.dart';
import 'package:itez_mobile/features/applications/models/order_application.dart';
import 'package:itez_mobile/features/applications/repositories/application_repository.dart';
import 'package:itez_mobile/features/orders/models/order_model.dart';
import 'package:itez_mobile/features/orders/repositories/order_repository.dart';

part 'order_detail_event.dart';
part 'order_detail_state.dart';

/// BLoC одной деталки заказа.
///
/// Обработка:
///  - `OrderDetailRequested` / `OrderDetailRefreshed` — загрузка заказа.
///  - Action events (`OrderCancelRequested`, `OrderAccepted`, …) — мутирующие
///    POST-ы, после успешного — авто-refetch заказа.
///  - Chat (`OrderMessagesRequested`, `OrderMessageSent`,
///    `OrderMessageReceived`) — инкрементальный чат `/orders/{id}/messages`.
///  - Applications inbox (`OrderApplicationsRequested`) — для клиента в
///    `searching_master`.
class OrderDetailBloc extends Bloc<OrderDetailEvent, OrderDetailState> {
  OrderDetailBloc({
    required OrderRepository orders,
    required ApplicationRepository applications,
  })  : _repo = orders,
        _apps = applications,
        super(const OrderDetailState()) {
    on<OrderDetailRequested>(_onRequested);
    on<OrderDetailRefreshed>((_, emit) async {
      if (_id != null) await _fetchOrder(_id!, emit);
    });
    on<OrderCancelRequested>(_onCancel);
    on<OrderConfirmRequested>(_onConfirm);
    on<OrderStatusUpdated>(_onStatus);
    on<OrderAccepted>(_onAccepted);
    on<OrderDeclined>(_onDeclined);
    on<OrderConfirmWork>(_onConfirmWork);
    on<OrderRejectProposal>(_onRejectProposal);
    on<OrderMessagesRequested>(_onMessagesRequested);
    on<OrderMessagesRefreshed>(_onMessagesRequested);
    on<OrderMessageSent>(_onMessageSent);
    on<OrderMessageReceived>(_onMessageReceived);
    on<OrderApplicationsRequested>(_onApplicationsRequested);
    on<OrderReviewSubmitted>(_onReviewSubmitted);
  }

  final OrderRepository _repo;
  final ApplicationRepository _apps;
  int? _id;

  Future<void> _onRequested(
    OrderDetailRequested event,
    Emitter<OrderDetailState> emit,
  ) async {
    _id = event.id;
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final order = await _repo.show(event.id);
      emit(state.copyWith(loading: false, order: order));
    } on ForbiddenException catch (e) {
      if (event.publicFallback) {
        await _tryPublic(event.id, emit);
      } else {
        emit(state.copyWith(loading: false, error: e.message));
      }
    } on UnauthorizedException {
      if (event.publicFallback) {
        await _tryPublic(event.id, emit);
      } else {
        emit(state.copyWith(loading: false, error: 'Требуется авторизация'));
      }
    } on AppException catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e.message ?? 'Не удалось загрузить заказ',
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: 'Не удалось обработать данные заказа: $e',
      ));
    }
  }

  Future<void> _tryPublic(int id, Emitter<OrderDetailState> emit) async {
    try {
      final order = await _repo.publicShow(id);
      emit(state.copyWith(loading: false, order: order));
    } on AppException catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e.message ?? 'Заказ недоступен',
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: 'Не удалось обработать данные: $e',
      ));
    }
  }

  Future<void> _fetchOrder(int id, Emitter<OrderDetailState> emit) async {
    try {
      final order = await _repo.show(id);
      emit(state.copyWith(order: order));
    } on AppException {/* keep last good */}
  }

  Future<void> _mutate(
    Future<void> Function() action,
    Emitter<OrderDetailState> emit,
  ) async {
    final id = _id;
    if (id == null) return;
    emit(state.copyWith(
      mutating: true,
      clearMutationError: true,
      lastActionSucceeded: false,
    ));
    try {
      await action();
      await _fetchOrder(id, emit);
      emit(state.copyWith(mutating: false, lastActionSucceeded: true));
    } on AppException catch (e) {
      emit(state.copyWith(
        mutating: false,
        mutationError: e.message ?? 'Не удалось обновить заказ',
      ));
    } catch (e) {
      emit(state.copyWith(
        mutating: false,
        mutationError: 'Не удалось выполнить действие: $e',
      ));
    }
  }

  Future<void> _onCancel(
    OrderCancelRequested event,
    Emitter<OrderDetailState> emit,
  ) =>
      _mutate(() => _repo.cancel(_id!, reason: event.reason), emit);

  Future<void> _onConfirm(
    OrderConfirmRequested event,
    Emitter<OrderDetailState> emit,
  ) =>
      _mutate(() => _repo.confirm(_id!), emit);

  Future<void> _onStatus(
    OrderStatusUpdated event,
    Emitter<OrderDetailState> emit,
  ) =>
      _mutate(() => _repo.updateStatus(_id!, event.status), emit);

  Future<void> _onAccepted(
    OrderAccepted event,
    Emitter<OrderDetailState> emit,
  ) =>
      _mutate(() => _repo.accept(_id!), emit);

  Future<void> _onDeclined(
    OrderDeclined event,
    Emitter<OrderDetailState> emit,
  ) =>
      _mutate(() => _repo.decline(_id!), emit);

  Future<void> _onConfirmWork(
    OrderConfirmWork event,
    Emitter<OrderDetailState> emit,
  ) =>
      _mutate(
        () => _repo.confirmWork(
          _id!,
          price: event.price,
          completedAt: event.completedAt,
          note: event.note,
        ),
        emit,
      );

  Future<void> _onRejectProposal(
    OrderRejectProposal event,
    Emitter<OrderDetailState> emit,
  ) =>
      _mutate(() => _repo.rejectProposal(_id!), emit);

  // ───────── chat ─────────
  Future<void> _onMessagesRequested(
    OrderDetailEvent event,
    Emitter<OrderDetailState> emit,
  ) async {
    final id = _id;
    if (id == null) return;
    try {
      final lastId = state.messages.isEmpty
          ? null
          : state.messages
              .map((m) => parseInt(m['id']))
              .fold<int>(0, (a, b) => a > b ? a : b);
      final fresh = await _repo.messages(id, since: lastId);
      if (fresh.isEmpty) return;
      final seen = state.messages.map((m) => parseInt(m['id'])).toSet();
      final merged = [
        ...state.messages,
        ...fresh.where((m) => !seen.contains(parseInt(m['id']))),
      ];
      emit(state.copyWith(messages: merged));
    } on AppException {/* keep last good */}
  }

  Future<void> _onMessageSent(
    OrderMessageSent event,
    Emitter<OrderDetailState> emit,
  ) async {
    final id = _id;
    final text = event.text.trim();
    final hasPhoto =
        event.imageDataUri != null && event.imageDataUri!.isNotEmpty;
    if (id == null || (text.isEmpty && !hasPhoto)) return;
    emit(state.copyWith(sendingMessage: true));
    try {
      final msg = await _repo.sendMessage(
        id,
        text: text.isEmpty ? null : text,
        imageDataUri: event.imageDataUri,
      );
      emit(state.copyWith(
        sendingMessage: false,
        messages: [...state.messages, msg],
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        sendingMessage: false,
        mutationError: e.message ?? 'Не удалось отправить',
      ));
    } catch (e) {
      emit(state.copyWith(sendingMessage: false));
    }
  }

  Future<void> _onMessageReceived(
    OrderMessageReceived event,
    Emitter<OrderDetailState> emit,
  ) async {
    final mid = parseInt(event.message['id']);
    if (state.messages.any((m) => parseInt(m['id']) == mid)) return;
    emit(state.copyWith(messages: [...state.messages, event.message]));
  }

  // ───────── applications inbox ─────────
  Future<void> _onApplicationsRequested(
    OrderApplicationsRequested event,
    Emitter<OrderDetailState> emit,
  ) async {
    final id = _id;
    if (id == null) return;
    emit(state.copyWith(applicationsLoading: true));
    try {
      final items = await _apps.forOrder(id);
      emit(state.copyWith(applications: items, applicationsLoading: false));
    } on AppException {
      emit(state.copyWith(applicationsLoading: false));
    }
  }

  // ───────── review ─────────
  Future<void> _onReviewSubmitted(
    OrderReviewSubmitted event,
    Emitter<OrderDetailState> emit,
  ) =>
      _mutate(
        () => _repo.postReview(
          _id!,
          rating: event.rating,
          comment: event.comment,
        ),
        emit,
      );
}
