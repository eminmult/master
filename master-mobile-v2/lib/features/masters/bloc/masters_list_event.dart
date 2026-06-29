part of 'masters_list_bloc.dart';

sealed class MastersListEvent {
  const MastersListEvent();
}

class MastersRequested extends MastersListEvent {
  const MastersRequested(this.filter);
  final MasterListFilter filter;
}

class MastersFilterChanged extends MastersListEvent {
  const MastersFilterChanged(this.filter);
  final MasterListFilter filter;
}

class MastersRefreshed extends MastersListEvent {
  const MastersRefreshed();
}
