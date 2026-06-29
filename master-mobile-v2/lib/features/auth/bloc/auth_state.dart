part of 'auth_bloc.dart';

/// Жизненный цикл авторизации:
/// AuthUnknown → AuthLoading → (AuthAuthenticated | AuthUnauthenticated)
/// при ошибках сетевой/валидации эмитим AuthFailed с предыдущим юзером
/// (если был) — так UI знает, что показать (snackbar/redirect).
sealed class AuthState {
  const AuthState();

  UserModel? get user => null;
  bool get isAuthenticated => user != null;
}

class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this._user);
  final UserModel _user;
  @override
  UserModel get user => _user;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthFailed extends AuthState {
  const AuthFailed(this.message, {this.errors, UserModel? previousUser})
      : _previous = previousUser;
  final String message;
  final Map<String, List<String>>? errors;
  final UserModel? _previous;
  @override
  UserModel? get user => _previous;
  @override
  bool get isAuthenticated => _previous != null;
}
