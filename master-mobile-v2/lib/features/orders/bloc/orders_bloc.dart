import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itez_mobile/core/exceptions/app_exception.dart';
import 'package:itez_mobile/features/orders/models/order_model.dart';
import 'package:itez_mobile/features/orders/repositories/order_repository.dart';

part 'orders_event.dart';
part 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  OrdersBloc(this._repo) : super(const OrdersInitial()) {
    on<OrdersRequested>(_onRequested);
    on<OrdersRefreshed>(_onRefreshed);
  }

  final OrderRepository _repo;
  OrdersScope _scope = OrdersScope.my;

  Future<void> _onRequested(
    OrdersRequested event,
    Emitter<OrdersState> emit,
  ) async {
    _scope = event.scope;
    emit(OrdersLoading(_scope));
    await _fetch(emit);
  }

  Future<void> _onRefreshed(
    OrdersRefreshed event,
    Emitter<OrdersState> emit,
  ) async {
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<OrdersState> emit) async {
    try {
      final items = switch (_scope) {
        OrdersScope.my => await _repo.my(),
        OrdersScope.available => await _repo.availableForMaster(),
        OrdersScope.publicFeed => await _repo.publicFeed(),
      };
      emit(OrdersLoaded(scope: _scope, items: items));
    } on AppException catch (e) {
      emit(OrdersFailed(
        scope: _scope,
        message: e.message ?? 'Не удалось загрузить заказы',
      ));
    }
  }
}
