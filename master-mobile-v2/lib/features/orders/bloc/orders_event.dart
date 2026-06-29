part of 'orders_bloc.dart';

/// Какой список заказов отображать.
enum OrdersScope { my, available, publicFeed }

sealed class OrdersEvent {
  const OrdersEvent();
}

class OrdersRequested extends OrdersEvent {
  const OrdersRequested(this.scope);
  final OrdersScope scope;
}

class OrdersRefreshed extends OrdersEvent {
  const OrdersRefreshed();
}
