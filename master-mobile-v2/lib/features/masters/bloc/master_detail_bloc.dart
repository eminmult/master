import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itez_mobile/core/exceptions/app_exception.dart';
import 'package:itez_mobile/features/masters/models/master_detail.dart';
import 'package:itez_mobile/features/masters/models/master_review.dart';
import 'package:itez_mobile/features/masters/repositories/master_repository.dart';

part 'master_detail_event.dart';
part 'master_detail_state.dart';

/// BLoC деталки мастера. Скоупится per-page через AutoRouteWrapper —
/// каждая вкладка имеет свой экземпляр; кеш переиспользовать тут смысла нет
/// (мастер открыт = он нас интересует прямо сейчас, при следующем заходе
/// данные могут уже устареть: online/accepting меняются часто).
class MasterDetailBloc extends Bloc<MasterDetailEvent, MasterDetailState> {
  MasterDetailBloc(this._repo) : super(const MasterDetailState()) {
    on<MasterDetailRequested>(_onDetail);
    on<MasterReviewsRequested>(_onReviews);
    on<MasterReviewsMoreRequested>(_onReviewsMore);
  }

  final MasterRepository _repo;
  String? _idOrSlug;
  int _reviewsOffset = 0;
  static const _reviewsLimit = 10;

  Future<void> _onDetail(
    MasterDetailRequested event,
    Emitter<MasterDetailState> emit,
  ) async {
    _idOrSlug = event.idOrSlug;
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final master = await _repo.show(event.idOrSlug);
      emit(state.copyWith(loading: false, master: master));
    } on AppException catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e.message ?? 'Не удалось загрузить мастера',
      ));
    }
  }

  Future<void> _onReviews(
    MasterReviewsRequested event,
    Emitter<MasterDetailState> emit,
  ) async {
    final id = _idOrSlug;
    if (id == null) return;
    _reviewsOffset = 0;
    emit(state.copyWith(reviewsLoading: true, clearReviewsError: true));
    try {
      final page = await _repo.reviews(id, limit: event.limit, offset: 0);
      _reviewsOffset = page.items.length;
      emit(state.copyWith(
        reviews: page.items,
        reviewsTotal: page.total,
        reviewsLoading: false,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        reviewsLoading: false,
        reviewsError: e.message ?? 'Не удалось загрузить отзывы',
      ));
    }
  }

  Future<void> _onReviewsMore(
    MasterReviewsMoreRequested event,
    Emitter<MasterDetailState> emit,
  ) async {
    final id = _idOrSlug;
    if (id == null || state.reviewsLoading || !state.hasMoreReviews) return;
    emit(state.copyWith(reviewsLoading: true));
    try {
      final page = await _repo.reviews(
        id,
        limit: _reviewsLimit,
        offset: _reviewsOffset,
      );
      _reviewsOffset += page.items.length;
      emit(state.copyWith(
        reviews: [...state.reviews, ...page.items],
        reviewsTotal: page.total,
        reviewsLoading: false,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        reviewsLoading: false,
        reviewsError: e.message ?? 'Не удалось подгрузить отзывы',
      ));
    }
  }
}
