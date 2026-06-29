part of 'navbar_bloc.dart';

sealed class NavbarEvent {
  const NavbarEvent();
}

class SelectTabEvent extends NavbarEvent {
  const SelectTabEvent(this.index);
  final int index;
}
