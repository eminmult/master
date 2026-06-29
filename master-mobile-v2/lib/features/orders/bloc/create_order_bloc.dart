import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itez_mobile/core/exceptions/app_exception.dart';
import 'package:itez_mobile/features/orders/models/create_order_draft.dart';
import 'package:itez_mobile/features/orders/models/order_model.dart';
import 'package:itez_mobile/features/orders/repositories/order_repository.dart';

part 'create_order_event.dart';
part 'create_order_state.dart';

class CreateOrderBloc extends Bloc<CreateOrderEvent, CreateOrderState> {
  CreateOrderBloc(this._repo) : super(const CreateOrderIdle()) {
    on<CreateOrderSubmitted>(_onSubmit);
    on<CreateOrderReset>((_, emit) => emit(const CreateOrderIdle()));
  }

  final OrderRepository _repo;

  Future<void> _onSubmit(
    CreateOrderSubmitted event,
    Emitter<CreateOrderState> emit,
  ) async {
    emit(const CreateOrderInProgress());
    try {
      final order = await _repo.create(event.draft);
      emit(CreateOrderSuccess(order));
    } on ValidationException catch (e) {
      emit(CreateOrderFailure(
        message: e.message ?? 'Проверьте поля',
        errors: e.errors,
      ));
    } on AppException catch (e) {
      emit(CreateOrderFailure(message: e.message ?? 'Не удалось создать заказ'));
    }
  }
}
