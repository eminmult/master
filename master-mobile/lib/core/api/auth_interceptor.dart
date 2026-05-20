import 'package:dio/dio.dart';
import 'package:master_mobile/core/auth/auth_storage.dart';

/// Attaches the bearer token, and on 401 attempts a single token refresh
/// before propagating the failure. If refresh also fails the user is logged
/// out by clearing storage — UI listens to AuthController and routes to login.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, this._refreshDio, this._onLoggedOut);

  final AuthStorage _storage;

  /// A separate Dio used only for refresh, to avoid recursing through this
  /// interceptor when the refresh call itself happens.
  final Dio _refreshDio;

  /// Called when refresh fails — UI should send the user to login.
  final Future<void> Function() _onLoggedOut;

  bool _refreshing = false;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.readToken();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final isAuthCall = err.requestOptions.path.contains('/auth/login') ||
        err.requestOptions.path.contains('/auth/refresh') ||
        err.requestOptions.path.contains('/auth/register');

    if (status != 401 || isAuthCall || _refreshing) {
      return handler.next(err);
    }

    final hadToken = await _storage.readToken();
    if (hadToken == null) return handler.next(err);

    _refreshing = true;
    try {
      final res = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        options: Options(headers: {'Authorization': 'Bearer $hadToken'}),
      );
      final newToken = res.data?['token'] as String?;
      if (newToken == null) throw err;
      await _storage.writeToken(newToken);

      // Retry the original request with the new token.
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
      await _storage.clear();
      await _onLoggedOut();
      return handler.next(err);
    } finally {
      _refreshing = false;
    }
  }
}
