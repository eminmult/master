part of 'order_detail_bloc.dart';

class OrderDetailState {
  const OrderDetailState({
    this.loading = false,
    this.order,
    this.error,
    this.mutating = false,
    this.mutationError,
    this.lastActionSucceeded = false,
    this.messages = const [],
    this.sendingMessage = false,
    this.applications = const [],
    this.applicationsLoading = false,
    this.gpsActive = false,
  });

  final bool loading;
  final OrderModel? order;
  final String? error;
  final bool mutating;
  final String? mutationError;
  final bool lastActionSucceeded;

  /// Inline-чат заказа. Каждое сообщение — `{id, sender_id, text, image_url,
  /// created_at, sender:{first_name, avatar_url}}`. Парсим лениво на уровне UI.
  final List<Map<String, dynamic>> messages;
  final bool sendingMessage;

  /// Отклики мастеров (для клиента в `searching_master`).
  final List<OrderApplication> applications;
  final bool applicationsLoading;

  /// Активирован GPS-поток мастера (для on_the_way/arrived).
  final bool gpsActive;

  OrderDetailState copyWith({
    bool? loading,
    OrderModel? order,
    String? error,
    bool? mutating,
    String? mutationError,
    bool? lastActionSucceeded,
    List<Map<String, dynamic>>? messages,
    bool? sendingMessage,
    List<OrderApplication>? applications,
    bool? applicationsLoading,
    bool? gpsActive,
    bool clearError = false,
    bool clearMutationError = false,
  }) =>
      OrderDetailState(
        loading: loading ?? this.loading,
        order: order ?? this.order,
        error: clearError ? null : (error ?? this.error),
        mutating: mutating ?? this.mutating,
        mutationError:
            clearMutationError ? null : (mutationError ?? this.mutationError),
        lastActionSucceeded: lastActionSucceeded ?? this.lastActionSucceeded,
        messages: messages ?? this.messages,
        sendingMessage: sendingMessage ?? this.sendingMessage,
        applications: applications ?? this.applications,
        applicationsLoading: applicationsLoading ?? this.applicationsLoading,
        gpsActive: gpsActive ?? this.gpsActive,
      );
}
