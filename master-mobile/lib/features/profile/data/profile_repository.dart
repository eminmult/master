import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_mobile/core/api/api_client.dart';
import 'package:master_mobile/core/api/api_exception.dart';

/// Self-profile mutations: avatar upload, client/master text fields. Reads
/// remain in `UserProfileRepository` (which targets `/users/{id}/profile`).
class ProfileRepository {
  ProfileRepository(this._dio);
  final Dio _dio;

  /// Uploads a `data:image/...;base64,...` URL. Returns the new avatar URL.
  Future<String> uploadAvatar(String dataUrl) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/avatar',
        data: {'avatar': dataUrl},
      );
      return res.data!['avatar_url'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> updateClient({
    required String firstName,
    String? lastName,
    String? email,
  }) async {
    try {
      await _dio.put<void>('/client/profile', data: {
        'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (email != null && email.isNotEmpty) 'email': email,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post<void>('/auth/change-password', data: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPassword,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _dio.post<void>('/me/delete');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> updateMaster({
    required String firstName,
    required String lastName,
    String? email,
    String? description,
    String? city,
    String? district,
    int? experienceYears,
  }) async {
    try {
      await _dio.put<void>('/master/profile', data: {
        'first_name': firstName,
        'last_name': lastName,
        if (email != null && email.isNotEmpty) 'email': email,
        if (description != null) 'description': description,
        if (city != null) 'city': city,
        if (district != null) 'district': district,
        if (experienceYears != null) 'experience_years': experienceYears,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(apiClientProvider));
});
