part of 'orders_bloc.dart';

sealed class OrdersState {
  const OrdersState();
}

class OrdersInitial extends OrdersState {
  const OrdersInitial();
}

class OrdersLoading extends OrdersState {
  const OrdersLoading(this.scope);
  final OrdersScope scope;
}

class OrdersLoaded extends OrdersState {
  const OrdersLoaded({required this.scope, required this.items});
  final OrdersScope scope;
  final List<OrderModel> items;
}

class OrdersFailed extends OrdersState {
  const OrdersFailed({required this.scope, required this.message});
  final OrdersScope scope;
  final String message;
}
