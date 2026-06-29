import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:itez_mobile/core/api_client/urls.dart';
import 'package:itez_mobile/core/exceptions/app_exception.dart';
import 'package:itez_mobile/core/services/local_storage.dart';

/// Тонкий HTTP-клиент над `http` пакетом.
///
/// — Single source of truth: путь + queryParams → http.Response/JSON
/// — Bearer-токен подставляется автоматически
/// — На 401 пытаемся обновить токен (один общий Future для всех конкурирующих 401)
/// — Ошибки нормализуются в иерархию [AppException]
class ApiClient {
  factory ApiClient() => _instance;
  ApiClient._();
  static final ApiClient _instance = ApiClient._();

  final http.Client _client = http.Client();
  Future<String?>? _refreshFuture;
  String? _localeOverride;

  /// Установить локаль (ru/az/en), которая будет уходить в Accept-Language.
  /// Обновлять при переключении языка в ConfigBloc.
  void setLocale(String code) => _localeOverride = code;

  // ───────── public API ─────────
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? queryParams,
    bool requireAuth = false,
  }) async {
    final res = await _send(
      method: 'GET',
      path: path,
      queryParams: queryParams,
      requireAuth: requireAuth,
    );
    return _decodeJsonObject(res);
  }

  Future<List<dynamic>> getJsonList(
    String path, {
    Map<String, dynamic>? queryParams,
    bool requireAuth = false,
  }) async {
    final res = await _send(
      method: 'GET',
      path: path,
      queryParams: queryParams,
      requireAuth: requireAuth,
    );
    return _decodeJsonList(res);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    bool requireAuth = false,
  }) async {
    final res = await _send(
      method: 'POST',
      path: path,
      body: body,
      requireAuth: requireAuth,
    );
    return _decodeJsonObject(res);
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    final res = await _send(
      method: 'PUT',
      path: path,
      body: body,
      requireAuth: requireAuth,
    );
    return _decodeJsonObject(res);
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    final res = await _send(
      method: 'PATCH',
      path: path,
      body: body,
      requireAuth: requireAuth,
    );
    return _decodeJsonObject(res);
  }

  Future<void> deleteJson(
    String path, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    await _send(
      method: 'DELETE',
      path: path,
      body: body,
      requireAuth: requireAuth,
    );
  }

  // ───────── core send ─────────
  Future<http.Response> _send({
    required String method,
    required String path,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? body,
    required bool requireAuth,
    bool isRetry = false,
  }) async {
    try {
      final uri = Uri.parse(path).replace(
        queryParameters: queryParams?.map(
          (k, v) => MapEntry(k, v?.toString() ?? ''),
        ),
      );

      final headers = await _buildHeaders(requireAuth: requireAuth);
      final encodedBody = body == null ? null : jsonEncode(body);

      final response = await _dispatch(method, uri, headers, encodedBody);

      if (response.statusCode == 401 && requireAuth && !isRetry) {
        final refreshed = await (_refreshFuture ??= _tryRefresh());
        _refreshFuture = null;
        if (refreshed != null) {
          return _send(
            method: method,
            path: path,
            queryParams: queryParams,
            body: body,
            requireAuth: requireAuth,
            isRetry: true,
          );
        }
      }

      _throwIfError(response);
      return response;
    } on SocketException catch (e) {
      log('ApiClient socket: $e');
      throw const NetworkException();
    } on HttpException catch (e) {
      log('ApiClient http: $e');
      throw const NetworkException();
    } on FormatException catch (e) {
      log('ApiClient format: $e');
      throw const UnknownException();
    } on TimeoutException catch (e) {
      log('ApiClient timeout: $e');
      throw const NetworkException(message: 'Превышено время ожидания');
    }
  }

  Future<http.Response> _dispatch(
    String method,
    Uri uri,
    Map<String, String> headers,
    String? body,
  ) async {
    const timeout = Duration(seconds: 30);
    switch (method) {
      case 'GET':
        return _client.get(uri, headers: headers).timeout(timeout);
      case 'POST':
        return _client.post(uri, headers: headers, body: body).timeout(timeout);
      case 'PUT':
        return _client.put(uri, headers: headers, body: body).timeout(timeout);
      case 'PATCH':
        return _client.patch(uri, headers: headers, body: body).timeout(timeout);
      case 'DELETE':
        return _client.delete(uri, headers: headers, body: body).timeout(timeout);
      default:
        throw StateError('Unsupported HTTP method: $method');
    }
  }

  Future<Map<String, String>> _buildHeaders({required bool requireAuth}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (_localeOverride != null) 'Accept-Language': _localeOverride!,
    };
    if (requireAuth) {
      final token = await LocalStorage.getAuthToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// Sanctum token rotation:
  /// POST /auth/refresh c Bearer текущего токена → `{token, expires_at}`.
  /// Старый токен на сервере уже revoke'нут, держать его смысла нет.
  /// Если ответ не 200 — очищаем хранилище и возвращаем null
  /// (вызвавшая операция упадёт в UnauthorizedException, UI выкинет на логин).
  Future<String?> _tryRefresh() async {
    final current = await LocalStorage.getAuthToken();
    if (current == null || current.isEmpty) return null;
    try {
      final res = await _client.post(
        Uri.parse(Urls.authRefresh),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $current',
        },
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        await LocalStorage.clearAuth();
        return null;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final token = data['token'] as String?;
      if (token == null) {
        await LocalStorage.clearAuth();
        return null;
      }
      final expiresRaw = data['expires_at'] as String?;
      final expiresAt = expiresRaw == null ? null : DateTime.tryParse(expiresRaw);
      await LocalStorage.setAuthToken(token: token, expiresAt: expiresAt);
      return token;
    } catch (e) {
      log('refresh failed: $e');
      return null;
    }
  }

  // ───────── decoding ─────────
  Map<String, dynamic> _decodeJsonObject(http.Response res) {
    if (res.body.isEmpty) return const {};
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const UnknownException(message: 'Ожидался объект в ответе');
  }

  List<dynamic> _decodeJsonList(http.Response res) {
    if (res.body.isEmpty) return const [];
    final decoded = jsonDecode(res.body);
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic> && decoded['data'] is List) {
      return decoded['data'] as List<dynamic>;
    }
    throw const UnknownException(message: 'Ожидался список в ответе');
  }

  void _throwIfError(http.Response res) {
    final code = res.statusCode;
    if (code >= 200 && code < 300) return;

    String? message;
    Map<String, List<String>>? errors;
    try {
      final body = jsonDecode(res.body);
      if (body is Map<String, dynamic>) {
        message = body['message']?.toString();
        final rawErrors = body['errors'];
        if (rawErrors is Map<String, dynamic>) {
          errors = rawErrors.map(
            (k, v) => MapEntry(
              k,
              (v as List<dynamic>).map((e) => e.toString()).toList(),
            ),
          );
        }
      }
    } catch (_) {/* not JSON */}

    switch (code) {
      case 401:
        throw UnauthorizedException(message: message ?? 'Требуется авторизация');
      case 403:
        throw ForbiddenException(message: message ?? 'Доступ запрещён');
      case 404:
        throw NotFoundException(message: message ?? 'Не найдено');
      case 422:
        throw ValidationException(
          message: message ?? 'Некорректные данные',
          errors: errors,
        );
      default:
        if (code >= 500) {
          throw ServerException(message: message, statusCode: code);
        }
        throw AppException(message: message, statusCode: code);
    }
  }
}
