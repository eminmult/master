import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itez_mobile/core/exceptions/app_exception.dart';
import 'package:itez_mobile/core/services/local_storage.dart';
import 'package:itez_mobile/features/auth/models/auth_response.dart';
import 'package:itez_mobile/features/auth/models/user_model.dart';
import 'package:itez_mobile/features/auth/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Глобальный BLoC. Регистрируется один раз в `App.MultiBlocProvider`,
/// чтобы любой экран мог `context.watch<AuthBloc>()`.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository repository})
      : _repo = repository,
        super(const AuthUnknown()) {
    on<AuthBootstrapRequested>(_onBootstrap);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterClientRequested>(_onRegisterClient);
    on<AuthRegisterMasterRequested>(_onRegisterMaster);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthMeRefreshRequested>(_onMeRefresh);
    on<AuthErrorCleared>(_onErrorCleared);
  }

  final AuthRepository _repo;

  Future<void> _onBootstrap(
    AuthBootstrapRequested event,
    Emitter<AuthState> emit,
  ) async {
    final token = await LocalStorage.getAuthToken();
    if (token == null || token.isEmpty) {
      emit(const AuthUnauthenticated());
      return;
    }
    emit(const AuthLoading());
    try {
      final user = await _repo.me();
      emit(AuthAuthenticated(user));
    } on UnauthorizedException {
      await LocalStorage.clearAuth();
      emit(const AuthUnauthenticated());
    } on AppException catch (e) {
      // Сеть упала на старте — оставляем токен, но переходим в
      // неавторизованный режим: UI потом сможет повторить попытку.
      log('bootstrap failed: $e');
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final res = await _repo.login(
        login: event.login,
        password: event.password,
      );
      await _persist(res);
      final user = res.user ?? await _repo.me();
      emit(AuthAuthenticated(user));
    } on ValidationException catch (e) {
      emit(AuthFailed(e.message ?? 'Некорректные данные', errors: e.errors));
    } on AppException catch (e) {
      emit(AuthFailed(e.message ?? 'Не удалось войти'));
    }
  }

  Future<void> _onRegisterClient(
    AuthRegisterClientRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final res = await _repo.registerClient(
        firstName: event.firstName,
        lastName: event.lastName,
        phone: event.phone,
        email: event.email,
        password: event.password,
        passwordConfirmation: event.passwordConfirmation,
      );
      await _persist(res);
      final user = res.user ?? await _repo.me();
      emit(AuthAuthenticated(user));
    } on ValidationException catch (e) {
      emit(AuthFailed(e.message ?? 'Некорректные данные', errors: e.errors));
    } on AppException catch (e) {
      emit(AuthFailed(e.message ?? 'Не удалось зарегистрироваться'));
    }
  }

  Future<void> _onRegisterMaster(
    AuthRegisterMasterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final res = await _repo.registerMaster(
        firstName: event.firstName,
        lastName: event.lastName,
        phone: event.phone,
        email: event.email,
        password: event.password,
        passwordConfirmation: event.passwordConfirmation,
        city: event.city,
        district: event.district,
        description: event.description,
        experienceYears: event.experienceYears,
        categoryIds: event.categoryIds,
      );
      await _persist(res);
      final user = res.user ?? await _repo.me();
      emit(AuthAuthenticated(user));
    } on ValidationException catch (e) {
      emit(AuthFailed(e.message ?? 'Некорректные данные', errors: e.errors));
    } on AppException catch (e) {
      emit(AuthFailed(e.message ?? 'Не удалось зарегистрироваться'));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final previous = state.user;
    try {
      await _repo.logout();
    } on AppException catch (e) {
      // Сервер недоступен — всё равно вычищаем локально, юзер не должен
      // оставаться в "вроде вышел" подвешенном состоянии.
      log('logout server-side failed: $e — clearing local anyway');
    }
    await LocalStorage.clearAuth();
    emit(const AuthUnauthenticated());
    // previous намеренно проигнорирован: после logout user всегда null.
    _silence(previous);
  }

  Future<void> _onMeRefresh(
    AuthMeRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthAuthenticated) return;
    try {
      final user = await _repo.me();
      emit(AuthAuthenticated(user));
    } on UnauthorizedException {
      await LocalStorage.clearAuth();
      emit(const AuthUnauthenticated());
    } on AppException catch (e) {
      log('me refresh failed: $e');
    }
  }

  Future<void> _onErrorCleared(
    AuthErrorCleared event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthFailed) return;
    final user = state.user;
    emit(user != null ? AuthAuthenticated(user) : const AuthUnauthenticated());
  }

  Future<void> _persist(AuthResponse res) async {
    if (res.token.isEmpty) return;
    await LocalStorage.setAuthToken(
      token: res.token,
      expiresAt: res.expiresAt,
    );
  }

  // ignore: avoid_unused_constructor_parameters
  void _silence(Object? _) {}
}
