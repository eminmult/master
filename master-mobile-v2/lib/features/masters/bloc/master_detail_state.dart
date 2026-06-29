part of 'master_detail_bloc.dart';

class MasterDetailState {
  const MasterDetailState({
    this.loading = false,
    this.master,
    this.error,
    this.reviews = const [],
    this.reviewsTotal = 0,
    this.reviewsLoading = false,
    this.reviewsError,
  });

  final bool loading;
  final MasterDetail? master;
  final String? error;

  final List<MasterReview> reviews;
  final int reviewsTotal;
  final bool reviewsLoading;
  final String? reviewsError;

  bool get hasMoreReviews => reviews.length < reviewsTotal;

  MasterDetailState copyWith({
    bool? loading,
    MasterDetail? master,
    String? error,
    List<MasterReview>? reviews,
    int? reviewsTotal,
    bool? reviewsLoading,
    String? reviewsError,
    bool clearError = false,
    bool clearReviewsError = false,
  }) =>
      MasterDetailState(
        loading: loading ?? this.loading,
        master: master ?? this.master,
        error: clearError ? null : (error ?? this.error),
        reviews: reviews ?? this.reviews,
        reviewsTotal: reviewsTotal ?? this.reviewsTotal,
        reviewsLoading: reviewsLoading ?? this.reviewsLoading,
        reviewsError:
            clearReviewsError ? null : (reviewsError ?? this.reviewsError),
      );
}
