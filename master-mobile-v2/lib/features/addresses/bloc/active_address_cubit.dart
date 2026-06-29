import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itez_mobile/core/services/local_storage.dart';
import 'package:itez_mobile/features/addresses/bloc/addresses_bloc.dart';
import 'package:itez_mobile/features/addresses/models/address_model.dart';

/// Хранит id выбранного пользователем адреса. Сам адрес не дублирует —
/// при необходимости разрешает по id из `AddressesBloc.items`.
///
/// Сохранение в [LocalStorage] делает выбор persistent между сессиями.
/// Если сохранённый id больше не существует в актуальном списке (адрес
/// был удалён) — fallback на default-адрес.
class ActiveAddressCubit extends Cubit<int?> {
  ActiveAddressCubit(this._addressesBloc) : super(null) {
    _bootstrap();
    _sub = _addressesBloc.stream.listen(_reconcile);
  }

  final AddressesBloc _addressesBloc;
  late final StreamSubscription<AddressesState> _sub;

  Future<void> _bootstrap() async {
    final stored = await LocalStorage.getActiveAddressId();
    if (stored != null) emit(stored);
  }

  void _reconcile(AddressesState s) {
    if (s.items.isEmpty) {
      if (state != null) emit(null);
      return;
    }
    final current = state;
    final stillExists =
        current != null && s.items.any((a) => a.id == current);
    if (stillExists) return;

    // Адрес был удалён или ничего не выбрано — берём default.
    final fallback = s.items.firstWhere(
      (a) => a.isDefault,
      orElse: () => s.items.first,
    );
    emit(fallback.id);
    unawaited(LocalStorage.setActiveAddressId(fallback.id));
  }

  Future<void> select(int id) async {
    emit(id);
    await LocalStorage.setActiveAddressId(id);
  }

  /// Удобный helper: текущий выбранный адрес из state'а bloc'а.
  AddressModel? resolve() {
    final id = state;
    if (id == null) return null;
    final items = _addressesBloc.state.items;
    for (final a in items) {
      if (a.id == id) return a;
    }
    return null;
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
