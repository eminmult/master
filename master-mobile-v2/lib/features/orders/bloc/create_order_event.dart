part of 'create_order_bloc.dart';

sealed class CreateOrderEvent {
  const CreateOrderEvent();
}

class CreateOrderSubmitted extends CreateOrderEvent {
  const CreateOrderSubmitted(this.draft);
  final CreateOrderDraft draft;
}

class CreateOrderReset extends CreateOrderEvent {
  const CreateOrderReset();
}
