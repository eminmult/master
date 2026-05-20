import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:master_mobile/core/api/api_client.dart';
import 'package:master_mobile/core/api/api_exception.dart';

part 'masters_repository.freezed.dart';
part 'masters_repository.g.dart';

@freezed
class MasterListItem with _$MasterListItem {
  const factory MasterListItem({
    required int id,
    @JsonKey(name: 'first_name') required String firstName,
    @JsonKey(name: 'last_name') String? lastName,
    @JsonKey(name: 'full_name') required String fullName,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'rating_avg') String? ratingAvg,
    @JsonKey(name: 'rating_count') @Default(0) int ratingCount,
    String? city,
    String? district,
    String? description,
    @JsonKey(name: 'experience_years') @Default(0) int experienceYears,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'completed_orders_count') @Default(0) int completedOrdersCount,
    List<dynamic>? categories,
    List<dynamic>? portfolio,
    List<dynamic>? reviews,
  }) = _MasterListItem;

  factory MasterListItem.fromJson(Map<String, dynamic> json) => _$MasterListItemFromJson(json);
}

final mastersRepositoryProvider = Provider<MastersRepository>((ref) {
  return MastersRepository(ref.watch(apiClientProvider));
});

class MastersRepository {
  MastersRepository(this._dio);
  final Dio _dio;

  Future<({List<MasterListItem> items, bool hasMore})> list({
    int? categoryId,
    String? city,
    String? query,
    int page = 1,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/masters', queryParameters: {
        if (categoryId != null) 'category_id': categoryId,
        if (city != null && city.isNotEmpty) 'city': city,
        if (query != null && query.isNotEmpty) 'q': query,
        'page': page,
      });
      final items = ((res.data!['masters'] as List?) ?? [])
          .map((e) => MasterListItem.fromJson(e as Map<String, dynamic>)).toList();
      final hasMore = (res.data!['pagination'] as Map?)?['has_more'] == true;
      return (items: items, hasMore: hasMore);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<MasterListItem> show(int id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/masters/$id');
      return MasterListItem.fromJson(res.data!['master'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<dynamic>> reviews(int masterId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/masters/$masterId/reviews');
      return (res.data!['reviews'] as List?) ?? [];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
