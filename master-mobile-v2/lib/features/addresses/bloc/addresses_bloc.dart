import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itez_mobile/core/exceptions/app_exception.dart';
import 'package:itez_mobile/features/addresses/models/address_model.dart';
import 'package:itez_mobile/features/addresses/repositories/address_repository.dart';

part 'addresses_event.dart';
part 'addresses_state.dart';

/// Список адресов клиента. Один глобальный экземпляр (а не per-page),
/// чтобы при создании заказа список уже был загружен и не моргал.
class AddressesBloc extends Bloc<AddressesEvent, AddressesState> {
  AddressesBloc(this._repo) : super(const AddressesState()) {
    on<AddressesRequested>(_onRequested);
    on<AddressCreated>(_onCreated);
    on<AddressUpdated>(_onUpdated);
    on<AddressDeleted>(_onDeleted);
  }

  final AddressRepository _repo;

  Future<void> _onRequested(
    AddressesRequested event,
    Emitter<AddressesState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final items = await _repo.list();
      emit(state.copyWith(loading: false, items: items));
    } on AppException catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e.message ?? 'Не удалось загрузить адреса',
      ));
    } catch (e) {
      // Любая ошибка парсинга / runtime — лучше показать сообщение, чем
      // зависнуть в loading=true (как было при cast'е lat-строки в num).
      emit(state.copyWith(
        loading: false,
        error: 'Не удалось обработать данные: $e',
      ));
    }
  }

  Future<void> _onCreated(
    AddressCreated event,
    Emitter<AddressesState> emit,
  ) async {
    emit(state.copyWith(mutating: true, clearMutationError: true));
    try {
      final created = await _repo.create(event.draft);
      final list = [..._stripDefaultIfNeeded(created), created];
      list.sort((a, b) {
        if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
        return b.id.compareTo(a.id);
      });
      emit(state.copyWith(
        mutating: false,
        items: list,
        justSavedId: created.id,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        mutating: false,
        mutationError: e.message ?? 'Не удалось сохранить адрес',
      ));
    }
  }

  Future<void> _onUpdated(
    AddressUpdated event,
    Emitter<AddressesState> emit,
  ) async {
    emit(state.copyWith(mutating: true, clearMutationError: true));
    try {
      final updated = await _repo.update(event.id, event.draft);
      final list = [
        for (final a in _stripDefaultIfNeeded(updated))
          if (a.id == updated.id) updated else a,
      ];
      list.sort((a, b) {
        if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
        return b.id.compareTo(a.id);
      });
      emit(state.copyWith(
        mutating: false,
        items: list,
        justSavedId: updated.id,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        mutating: false,
        mutationError: e.message ?? 'Не удалось сохранить адрес',
      ));
    }
  }

  Future<void> _onDeleted(
    AddressDeleted event,
    Emitter<AddressesState> emit,
  ) async {
    final original = state.items;
    // Оптимистично убираем из списка — если упадёт, вернём назад.
    emit(state.copyWith(
      items: state.items.where((a) => a.id != event.id).toList(),
      mutating: true,
      clearMutationError: true,
    ));
    try {
      await _repo.delete(event.id);
      emit(state.copyWith(mutating: false));
    } on AppException catch (e) {
      emit(state.copyWith(
        mutating: false,
        items: original,
        mutationError: e.message ?? 'Не удалось удалить адрес',
      ));
    }
  }

  /// Если новый/обновлённый адрес помечен как default — сбрасываем флаг
  /// у всех остальных (бэк делает то же самое в транзакции).
  Iterable<AddressModel> _stripDefaultIfNeeded(AddressModel touched) {
    if (!touched.isDefault) return state.items.where((a) => a.id != touched.id);
    return state.items
        .where((a) => a.id != touched.id)
        .map((a) => a.isDefault
            ? AddressModel(
                id: a.id,
                label: a.label,
                fullAddress: a.fullAddress,
                lat: a.lat,
                lng: a.lng,
                entrance: a.entrance,
                floor: a.floor,
                intercom: a.intercom,
                note: a.note,
                isDefault: false,
              )
            : a);
  }
}
