import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_mobile/core/api/api_client.dart';
import 'package:master_mobile/core/api/api_exception.dart';
import 'package:master_mobile/features/auth/data/models/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

/// Repository = thin wrapper over Dio. Returns plain models, throws
/// ApiException. Don't put any UI logic here.
class AuthRepository {
  AuthRepository(this._dio);
  final Dio _dio;

  Future<({User user, String token})> login({
    required String login,
    required String password,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'login': login, 'password': password},
      );
      return (
        user: User.fromJson(res.data!['user'] as Map<String, dynamic>),
        token: res.data!['token'] as String,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<({User user, String token})> registerClient(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/auth/register/client', data: data);
      return (
        user: User.fromJson(res.data!['user'] as Map<String, dynamic>),
        token: res.data!['token'] as String,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<({User user, String token})> registerMaster(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/auth/register/master', data: data);
      return (
        user: User.fromJson(res.data!['user'] as Map<String, dynamic>),
        token: res.data!['token'] as String,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<User> me() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/auth/me');
      return User.fromJson(res.data!['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<({String token, DateTime expiresAt})> refresh() async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/auth/refresh');
      return (
        token: res.data!['token'] as String,
        expiresAt: DateTime.parse(res.data!['expires_at'] as String),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<void>('/auth/logout');
    } on DioException catch (_) {
      // Best-effort — swallow network errors so the user can still log out locally.
    }
  }

  Future<void> forgotPassword(String login) async {
    try {
      await _dio.post<void>('/auth/forgot-password', data: {'login': login});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> resetPassword({
    required String login,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _dio.post<void>('/auth/reset-password', data: {
        'login': login,
        'token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> requestPhoneOtp() async {
    try {
      await _dio.post<void>('/auth/phone/request-otp');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> verifyPhoneOtp(String code) async {
    try {
      await _dio.post<void>('/auth/phone/verify-otp', data: {'code': code});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> verifyEmail({required String token, required int userId}) async {
    try {
      await _dio.post<void>('/auth/verify-email', data: {'token': token, 'user_id': userId});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> resendEmailVerification() async {
    try {
      await _dio.post<void>('/auth/resend-verification');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
