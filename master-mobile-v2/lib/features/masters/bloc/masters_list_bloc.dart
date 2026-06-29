import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itez_mobile/core/exceptions/app_exception.dart';
import 'package:itez_mobile/features/masters/models/master_list_item.dart';
import 'package:itez_mobile/features/masters/repositories/master_repository.dart';

part 'masters_list_event.dart';
part 'masters_list_state.dart';

/// Список мастеров с фильтрами. Поиск идёт через `restartable` —
/// при быстром наборе текста только последний запрос имеет значение.
/// Backend сам отдаёт до 50 элементов; пагинация не нужна на старте,
/// добавим cursor/offset если потребуется (Phase 2.1).
class MastersListBloc extends Bloc<MastersListEvent, MastersListState> {
  MastersListBloc(this._repo) : super(const MastersListInitial()) {
    on<MastersRequested>(_onRequested, transformer: restartable());
    on<MastersFilterChanged>(_onFilterChanged, transformer: restartable());
    on<MastersRefreshed>(_onRefreshed);
  }

  final MasterRepository _repo;
  MasterListFilter _filter = const MasterListFilter();

  Future<void> _onRequested(
    MastersRequested event,
    Emitter<MastersListState> emit,
  ) async {
    _filter = event.filter;
    emit(MastersListLoading(_filter));
    await _fetch(emit);
  }

  Future<void> _onFilterChanged(
    MastersFilterChanged event,
    Emitter<MastersListState> emit,
  ) async {
    _filter = event.filter;
    emit(MastersListLoading(_filter));
    await _fetch(emit);
  }

  Future<void> _onRefreshed(
    MastersRefreshed event,
    Emitter<MastersListState> emit,
  ) async {
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<MastersListState> emit) async {
    try {
      final items = await _repo.list(_filter);
      if (emit.isDone) return;
      emit(MastersListLoaded(filter: _filter, items: items));
    } on AppException catch (e) {
      emit(MastersListFailed(
        filter: _filter,
        message: e.message ?? 'Не удалось загрузить мастеров',
      ));
    }
  }
}
