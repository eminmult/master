part of 'my_orders_bloc.dart';

/// Тип секции на странице "Заказы".
enum SectionKind {
  /// Требуют действия (DİQQƏT / Внимание).
  attention,

  /// В работе, действий не требуется.
  active,

  /// Открытые отклики мастера.
  applications,

  /// Закрытые отклики (rejected/withdrawn) — только в History.
  applicationsClosed,

  /// Доступные мастеру публичные заказы.
  available,

  /// История (terminal).
  history,
}

/// Конкретная секция списка — либо orders, либо applications.
class MyOrdersSection {
  const MyOrdersSection.orders(this.kind, List<OrderModel> orders)
      : orders = orders,
        applications = const [];
  const MyOrdersSection.applications(
    this.kind,
    List<OrderApplication> applications,
  )   : orders = const [],
        applications = applications;

  final SectionKind kind;
  final List<OrderModel> orders;
  final List<OrderApplication> applications;

  bool get isEmpty => orders.isEmpty && applications.isEmpty;
  int get count => orders.length + applications.length;
}

class MyOrdersState {
  const MyOrdersState({
    this.loading = false,
    this.refreshing = false,
    this.showHistory = false,
    this.orders = const [],
    this.available = const [],
    this.applications = const [],
    this.error,
  });

  final bool loading;
  final bool refreshing;
  final bool showHistory;
  final List<OrderModel> orders;
  final List<OrderModel> available;
  final List<OrderApplication> applications;
  final String? error;

  MyOrdersState copyWith({
    bool? loading,
    bool? refreshing,
    bool? showHistory,
    List<OrderModel>? orders,
    List<OrderModel>? available,
    List<OrderApplication>? applications,
    String? error,
    bool clearError = false,
  }) =>
      MyOrdersState(
        loading: loading ?? this.loading,
        refreshing: refreshing ?? this.refreshing,
        showHistory: showHistory ?? this.showHistory,
        orders: orders ?? this.orders,
        available: available ?? this.available,
        applications: applications ?? this.applications,
        error: clearError ? null : (error ?? this.error),
      );
}
