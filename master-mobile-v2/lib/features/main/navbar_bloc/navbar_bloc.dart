import 'package:flutter_bloc/flutter_bloc.dart';

part 'navbar_event.dart';
part 'navbar_state.dart';

class NavbarBloc extends Bloc<NavbarEvent, NavbarState> {
  NavbarBloc() : super(const NavbarState(0)) {
    on<SelectTabEvent>((event, emit) {
      if (state.index != event.index) {
        emit(NavbarState(event.index));
      }
    });
  }
}
