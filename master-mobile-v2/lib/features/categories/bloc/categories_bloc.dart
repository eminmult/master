import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itez_mobile/core/exceptions/app_exception.dart';
import 'package:itez_mobile/features/categories/models/category_model.dart';
import 'package:itez_mobile/features/categories/repositories/category_repository.dart';

part 'categories_event.dart';
part 'categories_state.dart';

/// Список категорий — публичный, кешируется на сервере (Cache::remember).
/// На клиенте не кешируем: 6h серверного кеша + смена локали (Accept-Language)
/// сразу даёт правильные локализованные имена.
class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  CategoriesBloc(this._repo) : super(const CategoriesInitial()) {
    on<CategoriesRequested>(_onRequested);
    on<CategoriesRefreshed>(_onRefreshed);
  }

  final CategoryRepository _repo;
  bool _includeSubs = false;
  bool _onlyWithMasters = true;

  Future<void> _onRequested(
    CategoriesRequested event,
    Emitter<CategoriesState> emit,
  ) async {
    _includeSubs = event.includeSubcategories;
    _onlyWithMasters = event.onlyWithMasters;
    emit(const CategoriesLoading());
    await _load(emit);
  }

  Future<void> _onRefreshed(
    CategoriesRefreshed event,
    Emitter<CategoriesState> emit,
  ) async {
    await _load(emit);
  }

  Future<void> _load(Emitter<CategoriesState> emit) async {
    try {
      final items = await _repo.list(
        includeSubcategories: _includeSubs,
        onlyWithMasters: _onlyWithMasters,
      );
      emit(CategoriesLoaded(items));
    } on AppException catch (e) {
      emit(CategoriesFailed(e.message ?? 'Не удалось загрузить категории'));
    }
  }
}
