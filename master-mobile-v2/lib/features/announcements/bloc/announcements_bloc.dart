import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itez_mobile/core/exceptions/app_exception.dart';
import 'package:itez_mobile/features/orders/models/order_model.dart';
import 'package:itez_mobile/features/orders/repositories/order_repository.dart';

part 'announcements_event.dart';
part 'announcements_state.dart';

/// Лента публичных заказов (`/orders/public`).
/// Тот же контракт что и у моих заказов, но видна всем — масштабирована для
/// гостя (без авторизации) и для мастера (выбирает на что откликнуться).
class AnnouncementsBloc extends Bloc<AnnouncementsEvent, AnnouncementsState> {
  AnnouncementsBloc(this._repo) : super(const AnnouncementsState()) {
    on<AnnouncementsRequested>(_onRequested);
    on<AnnouncementsRefreshed>(_onRefreshed);
    on<AnnouncementsMoreRequested>(_onMore);
  }

  final OrderRepository _repo;
  int _page = 1;

  Future<void> _onRequested(
    AnnouncementsRequested event,
    Emitter<AnnouncementsState> emit,
  ) async {
    _page = 1;
    emit(state.copyWith(
      loading: true,
      categoryId: event.categoryId,
      sort: event.sort,
      endReached: false,
      clearError: true,
      clearCategory: event.categoryId == null,
    ));
    await _fetchFirst(emit);
  }

  Future<void> _onRefreshed(
    AnnouncementsRefreshed event,
    Emitter<AnnouncementsState> emit,
  ) async {
    _page = 1;
    emit(state.copyWith(loading: true, endReached: false, clearError: true));
    await _fetchFirst(emit);
  }

  Future<void> _onMore(
    AnnouncementsMoreRequested event,
    Emitter<AnnouncementsState> emit,
  ) async {
    if (state.loading || state.loadingMore || state.endReached) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final next = await _repo.publicFeed(
        categoryId: state.categoryId,
        sort: state.sort,
        page: _page + 1,
      );
      if (next.isEmpty) {
        emit(state.copyWith(loadingMore: false, endReached: true));
        return;
      }
      _page++;
      emit(state.copyWith(
        loadingMore: false,
        items: [...state.items, ...next],
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        loadingMore: false,
        error: e.message ?? 'Не удалось подгрузить',
      ));
    }
  }

  Future<void> _fetchFirst(Emitter<AnnouncementsState> emit) async {
    try {
      final items = await _repo.publicFeed(
        categoryId: state.categoryId,
        sort: state.sort,
        page: 1,
      );
      emit(state.copyWith(
        loading: false,
        items: items,
        endReached: items.isEmpty,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e.message ?? 'Не удалось загрузить объявления',
      ));
    }
  }
}
