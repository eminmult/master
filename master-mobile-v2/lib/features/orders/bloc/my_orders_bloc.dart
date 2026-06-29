import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itez_mobile/core/exceptions/app_exception.dart';
import 'package:itez_mobile/features/applications/models/order_application.dart';
import 'package:itez_mobile/features/applications/repositories/application_repository.dart';
import 'package:itez_mobile/features/orders/models/order_model.dart';
import 'package:itez_mobile/features/orders/models/order_status.dart';
import 'package:itez_mobile/features/orders/repositories/order_repository.dart';

part 'my_orders_event.dart';
part 'my_orders_state.dart';

/// BLoC страницы "Заказы".
///
/// Объединяет три источника:
///   1. `/orders/my` — все мои заказы (клиент или мастер).
///   2. `/orders/available` — публичный pool для мастера (skip для клиента).
///   3. `/master/applications` — отклики мастера (skip для клиента).
///
/// Категоризует их по role + tab(active/history) — см. `categorise()`.
class MyOrdersBloc extends Bloc<MyOrdersEvent, MyOrdersState> {
  MyOrdersBloc({
    required OrderRepository orders,
    required ApplicationRepository applications,
  })  : _orders = orders,
        _applications = applications,
        super(const MyOrdersState()) {
    on<MyOrdersRequested>(_onRequested);
    on<MyOrdersRefreshed>(_onRefreshed);
    on<MyOrdersTabChanged>(_onTabChanged);
    on<MyOrdersInvalidated>(_onInvalidated);
  }

  final OrderRepository _orders;
  final ApplicationRepository _applications;

  Future<void> _onRequested(
    MyOrdersRequested event,
    Emitter<MyOrdersState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true));
    await _fetch(emit, isMaster: event.isMaster);
  }

  Future<void> _onRefreshed(
    MyOrdersRefreshed event,
    Emitter<MyOrdersState> emit,
  ) async {
    emit(state.copyWith(refreshing: true, clearError: true));
    await _fetch(emit, isMaster: event.isMaster);
  }

  Future<void> _onInvalidated(
    MyOrdersInvalidated event,
    Emitter<MyOrdersState> emit,
  ) =>
      _fetch(emit, isMaster: event.isMaster);

  Future<void> _onTabChanged(
    MyOrdersTabChanged event,
    Emitter<MyOrdersState> emit,
  ) async {
    if (state.showHistory == event.showHistory) return;
    emit(state.copyWith(showHistory: event.showHistory));
  }

  Future<void> _fetch(
    Emitter<MyOrdersState> emit, {
    required bool isMaster,
  }) async {
    try {
      // Получаем все три источника параллельно. Опциональные (мастеровые)
      // подменяем на готовый пустой Future с правильным типом —
      // `Future.value(const [])` без явного типа даёт `Future<List<dynamic>>`,
      // что роняет `results[i] as List<...>` cast'ом.
      final my = _orders.my();
      final available = isMaster
          ? _orders.availableForMaster()
          : Future<List<OrderModel>>.value(const []);
      final apps = isMaster
          ? _applications.mine()
          : Future<List<OrderApplication>>.value(const []);
      final results = await Future.wait([my, available, apps]);
      emit(state.copyWith(
        loading: false,
        refreshing: false,
        orders: results[0] as List<OrderModel>,
        available: results[1] as List<OrderModel>,
        applications: results[2] as List<OrderApplication>,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        loading: false,
        refreshing: false,
        error: e.message ?? 'Не удалось загрузить заказы',
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        refreshing: false,
        error: 'Не удалось загрузить: $e',
      ));
    }
  }

  /// Категоризация. Чистая функция от текущего state'а + role — UI вызывает её,
  /// чтобы получить готовый список секций для рендера.
  List<MyOrdersSection> categorise({required bool isMaster}) {
    final orders = state.orders;
    final available = state.available;
    final applications = state.applications;

    if (state.showHistory) {
      final history = orders.where((o) => _isTerminal(o.status)).toList()
        ..sort((a, b) {
          final da = a.createdAt ?? DateTime(0);
          final db = b.createdAt ?? DateTime(0);
          return db.compareTo(da);
        });
      final closedApps =
          applications.where((a) => a.status.isClosed).toList();
      return [
        MyOrdersSection.orders(SectionKind.history, history),
        if (isMaster && closedApps.isNotEmpty)
          MyOrdersSection.applications(
              SectionKind.applicationsClosed, closedApps),
      ];
    }

    if (isMaster) {
      const attentionSet = {
        OrderStatus.accepted,
        OrderStatus.arrived,
        OrderStatus.inProgress,
      };
      const activeSet = {
        OrderStatus.confirmed,
        OrderStatus.onTheWay,
        OrderStatus.awaitingCompletion,
        OrderStatus.awaitingReview,
        OrderStatus.discussion,
        OrderStatus.pendingClient,
      };
      final attention =
          orders.where((o) => attentionSet.contains(o.status)).toList();
      final active = orders.where((o) => activeSet.contains(o.status)).toList();
      final openApps = applications.where((a) => a.status.isOpen).toList();

      return [
        MyOrdersSection.orders(SectionKind.attention, attention),
        MyOrdersSection.orders(SectionKind.active, active),
        MyOrdersSection.applications(SectionKind.applications, openApps),
        MyOrdersSection.orders(
            SectionKind.available, available.take(10).toList()),
      ];
    }

    // Client
    const attentionSet = {
      OrderStatus.pendingClient,
      OrderStatus.awaitingCompletion,
    };
    const activeSet = {
      OrderStatus.newOrder,
      OrderStatus.searching,
      OrderStatus.pendingMaster,
      OrderStatus.discussion,
      OrderStatus.confirmed,
      OrderStatus.accepted,
      OrderStatus.onTheWay,
      OrderStatus.arrived,
      OrderStatus.inProgress,
      OrderStatus.awaitingReview,
    };
    final attention =
        orders.where((o) => attentionSet.contains(o.status)).toList();
    final active = orders.where((o) => activeSet.contains(o.status)).toList();

    return [
      MyOrdersSection.orders(SectionKind.attention, attention),
      MyOrdersSection.orders(SectionKind.active, active),
    ];
  }

  bool _isTerminal(OrderStatus s) =>
      s.isFinished || s.isCanceled || s == OrderStatus.disputed;
}
