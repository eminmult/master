import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itez_mobile/core/exceptions/app_exception.dart';
import 'package:itez_mobile/features/auth/bloc/auth_bloc.dart';
import 'package:itez_mobile/features/auth/repositories/auth_repository.dart';
import 'package:itez_mobile/features/profile/repositories/profile_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

/// Мутации профиля. Сам пользователь живёт в [AuthBloc] —
/// после успешного сохранения дёргаем `AuthMeRefreshRequested`,
/// чтобы все экраны получили свежие данные.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required ProfileRepository profileRepository,
    required AuthRepository authRepository,
    required AuthBloc auth,
  })  : _profile = profileRepository,
        _authRepo = authRepository,
        _auth = auth,
        super(const ProfileState()) {
    on<ProfileUpdateClient>(_onUpdateClient);
    on<ProfileChangePassword>(_onChangePassword);
    on<ProfileResetStatus>(
      (_, emit) => emit(state.copyWith(
        status: ProfileStatus.idle,
        clearError: true,
        clearErrors: true,
      )),
    );
  }

  final ProfileRepository _profile;
  final AuthRepository _authRepo;
  final AuthBloc _auth;

  Future<void> _onUpdateClient(
    ProfileUpdateClient event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(
      status: ProfileStatus.saving,
      clearError: true,
      clearErrors: true,
    ));
    try {
      await _profile.updateClient(
        firstName: event.firstName,
        lastName: event.lastName,
        email: event.email,
      );
      _auth.add(const AuthMeRefreshRequested());
      emit(state.copyWith(status: ProfileStatus.saved));
    } on ValidationException catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.failed,
        error: e.message,
        errors: e.errors,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.failed,
        error: e.message ?? 'Не удалось сохранить профиль',
      ));
    }
  }

  Future<void> _onChangePassword(
    ProfileChangePassword event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(
      status: ProfileStatus.saving,
      clearError: true,
      clearErrors: true,
    ));
    try {
      await _authRepo.changePassword(
        currentPassword: event.current,
        newPassword: event.next,
        newPasswordConfirmation: event.confirm,
      );
      emit(state.copyWith(status: ProfileStatus.passwordChanged));
    } on ValidationException catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.failed,
        error: e.message,
        errors: e.errors,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.failed,
        error: e.message ?? 'Не удалось изменить пароль',
      ));
    }
  }
}
