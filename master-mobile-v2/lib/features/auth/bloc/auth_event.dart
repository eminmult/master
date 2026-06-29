part of 'auth_bloc.dart';

sealed class AuthEvent {
  const AuthEvent();
}

/// Поднимается в `main` после initLocator + LocalStorage.init —
/// читает токен и вызывает `/me` если он есть.
class AuthBootstrapRequested extends AuthEvent {
  const AuthBootstrapRequested();
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.login, required this.password});
  final String login;
  final String password;
}

class AuthRegisterClientRequested extends AuthEvent {
  const AuthRegisterClientRequested({
    required this.firstName,
    this.lastName,
    required this.phone,
    this.email,
    required this.password,
    required this.passwordConfirmation,
  });
  final String firstName;
  final String? lastName;
  final String phone;
  final String? email;
  final String password;
  final String passwordConfirmation;
}

class AuthRegisterMasterRequested extends AuthEvent {
  const AuthRegisterMasterRequested({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    required this.city,
    this.district,
    required this.description,
    required this.experienceYears,
    required this.categoryIds,
  });
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String city;
  final String? district;
  final String description;
  final int experienceYears;
  final List<int> categoryIds;
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthMeRefreshRequested extends AuthEvent {
  const AuthMeRefreshRequested();
}

/// Внутреннее — сбрасывает Failed обратно в Unauthenticated/Authenticated,
/// чтобы UI мог скрыть ошибку (например, после snackbar или повторной попытки).
class AuthErrorCleared extends AuthEvent {
  const AuthErrorCleared();
}
