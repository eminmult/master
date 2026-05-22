import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_mobile/core/api/api_client.dart';
import 'package:master_mobile/core/auth/auth_storage.dart';
import 'package:master_mobile/features/auth/data/auth_repository.dart';
import 'package:master_mobile/features/auth/data/models/user.dart';

/// Auth state machine: who is signed in (or still loading).
///
/// Pages observe via `ref.watch(authStateProvider)`. The router listens to
/// the same provider and redirects unauthenticated users away from
/// protected pages.
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

/// Riverpod 2.5+ Notifier. Migrated off StateNotifier because Riverpod 3
/// will drop it; Notifier also has tighter ergonomics (build() instead of
/// constructor, no separate Listenable lifecycle, easier to test). Callers
/// using `ref.watch(authStateProvider)` / `ref.read(authStateProvider.notifier)`
/// continue to work unchanged.
final authStateProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  // Read dependencies at point-of-use via ref.read instead of caching them
  // as `late final` in build(). Notifier.build() can run more than once
  // (e.g., on a watched-dependency change), and `late final` re-assignment
  // throws "Field has already been initialized" on the second run.
  AuthRepository get _repo => ref.read(authRepositoryProvider);
  AuthStorage get _storage => ref.read(authStorageProvider);

  @override
  AuthState build() {
    // Kick off /auth/me asynchronously — state transitions to authenticated
    // or unauthenticated once we have an answer. Initial state is Loading.
    Future.microtask(_bootstrap);
    return const AuthLoading();
  }

  /// Wrap a storage call with a 3-second timeout. flutter_secure_storage on
  /// web hangs indefinitely if the browser API is misbehaving (incognito,
  /// restricted localStorage, third-party cookies blocked); we'd rather
  /// fail-open to "unauthenticated" than leave the user on a splash screen.
  /// Using `Future<T?>` avoids the `null as T` cast that throws at runtime
  /// for non-nullable T.
  static Future<T?> _bounded<T extends Object>(Future<T?> f) =>
      f.timeout(const Duration(seconds: 3), onTimeout: () => null);

  Future<void> _bootstrap() async {
    try {
      final token = await _bounded<String>(_storage.readToken());
      if (token == null) {
        state = const AuthUnauthenticated();
        return;
      }
      try {
        final user = await _repo.me().timeout(const Duration(seconds: 8));
        state = AuthAuthenticated(user);
      } catch (_) {
        try {
          await _storage.clear().timeout(const Duration(seconds: 3));
        } catch (_) {/* storage broken — moving on */}
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
