part of 'master_detail_bloc.dart';

sealed class MasterDetailEvent {
  const MasterDetailEvent();
}

class MasterDetailRequested extends MasterDetailEvent {
  const MasterDetailRequested(this.idOrSlug);
  final String idOrSlug;
}

class MasterReviewsRequested extends MasterDetailEvent {
  const MasterReviewsRequested({this.limit = 10});
  final int limit;
}

class MasterReviewsMoreRequested extends MasterDetailEvent {
  const MasterReviewsMoreRequested();
}
