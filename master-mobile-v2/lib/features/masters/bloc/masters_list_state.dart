part of 'masters_list_bloc.dart';

sealed class MastersListState {
  const MastersListState();
}

class MastersListInitial extends MastersListState {
  const MastersListInitial();
}

class MastersListLoading extends MastersListState {
  const MastersListLoading(this.filter);
  final MasterListFilter filter;
}

class MastersListLoaded extends MastersListState {
  const MastersListLoaded({required this.filter, required this.items});
  final MasterListFilter filter;
  final List<MasterListItem> items;
}

class MastersListFailed extends MastersListState {
  const MastersListFailed({required this.filter, required this.message});
  final MasterListFilter filter;
  final String message;
}
