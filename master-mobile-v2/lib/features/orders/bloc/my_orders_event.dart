part of 'my_orders_bloc.dart';

sealed class MyOrdersEvent {
  const MyOrdersEvent();
}

class MyOrdersRequested extends MyOrdersEvent {
  const MyOrdersRequested({this.isMaster = false});
  final bool isMaster;
}

class MyOrdersRefreshed extends MyOrdersEvent {
  const MyOrdersRefreshed({this.isMaster = false});
  final bool isMaster;
}

class MyOrdersTabChanged extends MyOrdersEvent {
  const MyOrdersTabChanged(this.showHistory);
  final bool showHistory;
}

/// Внутренний: мастер вытянул новый/обновлённый заказ или отклик
/// (использован после accept / withdraw / updateStatus).
class MyOrdersInvalidated extends MyOrdersEvent {
  const MyOrdersInvalidated({this.isMaster = false});
  final bool isMaster;
}
