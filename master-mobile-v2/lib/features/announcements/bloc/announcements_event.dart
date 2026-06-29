part of 'announcements_bloc.dart';

sealed class AnnouncementsEvent {
  const AnnouncementsEvent();
}

class AnnouncementsRequested extends AnnouncementsEvent {
  const AnnouncementsRequested({this.categoryId, this.sort = 'recent'});
  final int? categoryId;
  final String sort;
}

class AnnouncementsRefreshed extends AnnouncementsEvent {
  const AnnouncementsRefreshed();
}

class AnnouncementsMoreRequested extends AnnouncementsEvent {
  const AnnouncementsMoreRequested();
}
