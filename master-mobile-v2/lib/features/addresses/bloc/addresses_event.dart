part of 'addresses_bloc.dart';

sealed class AddressesEvent {
  const AddressesEvent();
}

class AddressesRequested extends AddressesEvent {
  const AddressesRequested();
}

class AddressCreated extends AddressesEvent {
  const AddressCreated(this.draft);
  final AddressModel draft;
}

class AddressUpdated extends AddressesEvent {
  const AddressUpdated(this.id, this.draft);
  final int id;
  final AddressModel draft;
}

class AddressDeleted extends AddressesEvent {
  const AddressDeleted(this.id);
  final int id;
}
