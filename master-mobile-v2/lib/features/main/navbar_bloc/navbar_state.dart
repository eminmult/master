part of 'navbar_bloc.dart';

class NavbarState {
  const NavbarState(this.index);
  final int index;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NavbarState && index == other.index;

  @override
  int get hashCode => index.hashCode;
}
