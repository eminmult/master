import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_mobile/core/auth/auth_storage.dart';
import 'package:master_mobile/core/api/api_client.dart';
import 'package:master_mobile/features/auth/data/auth_repository.dart';
import 'package:master_mobile/features/auth/data/models/user.dart';

/// Single source of truth for "who am I, am I logged in".
/// UI listens via ref.watch(authStateProvider) — when state goes to
/// AuthState.unauthenticated, the router redirects to /login.
sealed class AuthState {
  const AuthState();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final User user;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final authStateProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(authStorageProvider),
  );
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo, this._storage) : super(const AuthLoading()) {
    bootstrap();
  }

  final AuthRepository _repo;
  final AuthStorage _storage;

  /// Called on app start. If we have a token, fetch /auth/me to validate it.
  /// Failure → unauthenticated. Success → authenticated.
  ///
  /// The whole body is wrapped in try/catch so that ANY failure (secure
  /// storage broken on web, /auth/me unreachable, deserialisation error)
  /// transitions us to AuthUnauthenticated instead of leaving the splash
  /// hanging forever in AuthLoading.
  Future<void> bootstrap() async {
    // 3-second timeout on every storage call. flutter_secure_storage on web
    // can hang indefinitely if the underlying browser API is misbehaving
    // (incognito + restricted localStorage, third-party cookies blocked, etc).
    // We'd rather fail-open to "unauthenticated" than leave the user staring
    // at a splash screen forever.
    Future<T?> _bounded<T>(Future<T> f) =>
        f.timeout(const Duration(seconds: 3), onTimeout: () => null as T);

    try {
      final token = await _bounded(_storage.readToken());
      if (token == null) {
        state = const AuthUnauthenticated();
        return;
      }
      try {
        final user = await _repo.me().timeout(const Duration(seconds: 8));
        state = AuthAuthenticated(user);
      } catch (_) {
        try { await _bounded(_storage.clear()); } catch (_) {}
        state = const AuthUnauthenticated();
      }
    } catch (e, st) {
      debugPrint('Auth bootstrap failed: $e\n$st');
      state = const AuthUnauthenticated();
    }
  }

  Future<void> login(String login, String password) async {
    state = const AuthLoading();
    final res = await _repo.login(login: login, password: password);
    await _storage.writeToken(res.token);
    state = AuthAuthenticated(res.user);
  }

  Future<void> registerClient(Map<String, dynamic> data) async {
    state = const AuthLoading();
    final res = await _repo.registerClient(data);
    await _storage.writeToken(res.token);
    state = AuthAuthenticated(res.user);
  }

  Future<void> registerMaster(Map<String, dynamic> data) async {
    state = const AuthLoading();
    final res = await _repo.registerMaster(data);
    await _storage.writeToken(res.token);
    state = AuthAuthenticated(res.user);
  }

  Future<void> refreshUser() async {
    if (state is! AuthAuthenticated) return;
    try {
      final user = await _repo.me();
      state = AuthAuthenticated(user);
    } catch (_) {
      // Don't downgrade on transient errors — token interceptor handles 401.
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    await _storage.clear();
    state = const AuthUnauthenticated();
  }
}
