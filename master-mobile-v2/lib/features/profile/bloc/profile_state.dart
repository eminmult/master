part of 'profile_bloc.dart';

enum ProfileStatus { idle, saving, saved, passwordChanged, failed }

class ProfileState {
  const ProfileState({
    this.status = ProfileStatus.idle,
    this.error,
    this.errors,
  });

  final ProfileStatus status;
  final String? error;
  final Map<String, List<String>>? errors;

  bool get isSaving => status == ProfileStatus.saving;

  ProfileState copyWith({
    ProfileStatus? status,
    String? error,
    Map<String, List<String>>? errors,
    bool clearError = false,
    bool clearErrors = false,
  }) =>
      ProfileState(
        status: status ?? this.status,
        error: clearError ? null : (error ?? this.error),
        errors: clearErrors ? null : (errors ?? this.errors),
      );
}
