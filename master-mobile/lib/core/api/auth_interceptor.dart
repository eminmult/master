import 'dart:async';

import 'package:dio/dio.dart';
import 'package:master_mobile/core/auth/auth_storage.dart';

/// Attaches the bearer token to every outgoing request and, on a 401,
/// transparently refreshes the token then retries the original call.
///
/// Concurrency model:
///
/// Multiple inflight requests can hit token expiry simultaneously and each
/// receive a 401. Without coordination we'd fire N refresh calls (racing the
/// storage write) or, worse, succeed for the first caller and drop the rest
/// with stale `next(err)`. We funnel every concurrent 401 through a single
/// `_refreshFuture` — the first caller starts the refresh, everyone else
/// awaits the same Future and retries with whatever token pops out.
///
/// On refresh failure we clear the auth storage and notify the host so the
/// router can land the user on /login.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, this._refreshDio, this._onLoggedOut);

  final AuthStorage _storage;

  /// Separate Dio used only for the refresh call, so the recursive refresh
  /// doesn't bounce back through this interceptor.
  final Dio _refreshDio;

  /// Called when refresh fails — UI should send the user to login.
  final Future<void> Function() _onLoggedOut;

  /// While non-null, a refresh attempt is in flight. Concurrent 401 handlers
  /// await this Future instead of starting their own.
  Future<String?>? _refreshFuture;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.readToken();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;
    final isAuthCall = path.contains('/auth/login') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/register');

    if (status != 401 || isAuthCall) {
      return handler.next(err);
    }

    final hadToken = await _storage.readToken();
    if (hadToken == null) return handler.next(err);

    // Coalesce concurrent refresh attempts onto a single Future.
    final newToken = await (_refreshFuture ??= _runRefresh(hadToken));
    if (newToken == null) return handler.next(err);

    try {
      final retried = await _refreshDio.fetch<dynamic>(
        err.requestOptions.copyWith(
          headers: {
            ...err.requestOptions.headers,
            'Authorization': 'Bearer $newToken',
          },
        ),
      );
      return handler.resolve(retried);
    } catch (_) {
      return handler.next(err);
    }
  }

  Future<String?> _runRefresh(String oldToken) async {
    try {
      final res = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        options: Options(headers: {'Authorization': 'Bearer $oldToken'}),
      );
      final newToken = res.data?['token'] as String?;
      if (newToken == null) {
        await _bailout();
        return null;
      }
      await _storage.writeToken(newToken);
      return newToken;
    } catch (_) {
      await _bailout();
      return null;
    } finally {
      // Release the lock only AFTER every concurrent awaiter has resolved.
      _refreshFuture = null;
    }
  }

  Future<void> _bailout() async {
    try { await _storage.clear(); } catch (_) {/* token already gone */}
    try { await _onLoggedOut(); } catch (_) {/* host's problem */}
  }
}
