part of 'profile_bloc.dart';

sealed class ProfileEvent {
  const ProfileEvent();
}

class ProfileUpdateClient extends ProfileEvent {
  const ProfileUpdateClient({
    required this.firstName,
    this.lastName,
    this.email,
  });
  final String firstName;
  final String? lastName;
  final String? email;
}

class ProfileChangePassword extends ProfileEvent {
  const ProfileChangePassword({
    required this.current,
    required this.next,
    required this.confirm,
  });
  final String current;
  final String next;
  final String confirm;
}

class ProfileResetStatus extends ProfileEvent {
  const ProfileResetStatus();
}
