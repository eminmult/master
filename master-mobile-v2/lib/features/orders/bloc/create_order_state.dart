part of 'create_order_bloc.dart';

sealed class CreateOrderState {
  const CreateOrderState();
}

class CreateOrderIdle extends CreateOrderState {
  const CreateOrderIdle();
}

class CreateOrderInProgress extends CreateOrderState {
  const CreateOrderInProgress();
}

class CreateOrderSuccess extends CreateOrderState {
  const CreateOrderSuccess(this.order);
  final OrderModel order;
}

class CreateOrderFailure extends CreateOrderState {
  const CreateOrderFailure({required this.message, this.errors});
  final String message;
  final Map<String, List<String>>? errors;
}
