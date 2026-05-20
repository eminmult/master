import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_mobile/core/api/api_client.dart';
import 'package:master_mobile/core/api/api_exception.dart';

/// Public profile fetcher — `/users/{id}/profile` returns a unified shape
/// that works for clients and masters (master_profile is null for clients).
/// Kept as a raw Map for now since the response is read-only and the page
/// only displays a handful of fields; can be promoted to a freezed model
/// later if more places start consuming it.
class UserProfileRepository {
  UserProfileRepository(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> show(int id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/users/$id/profile');
      // API returns `{profile: {...}}`; unwrap so consumers can access fields
      // directly (full_name, master_profile, reviews, etc.) without an extra
      // hop. Tolerate the rare case where the server returns the body flat.
      final body = res.data!;
      final inner = body['profile'];
      if (inner is Map<String, dynamic>) return inner;
      return body;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository(ref.watch(apiClientProvider));
});

final userProfileProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, id) async {
  return ref.watch(userProfileRepositoryProvider).show(id);
});
