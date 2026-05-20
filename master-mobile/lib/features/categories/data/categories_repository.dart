import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:master_mobile/core/api/api_client.dart';
import 'package:master_mobile/core/api/api_exception.dart';

part 'categories_repository.freezed.dart';
part 'categories_repository.g.dart';

@freezed
class ServiceCategory with _$ServiceCategory {
  const factory ServiceCategory({
    required int id,
    required String name,
    required String slug,
    @JsonKey(name: 'icon_url') String? iconUrl,
    String? description,
    @JsonKey(name: 'masters_count') @Default(0) int mastersCount,
  }) = _ServiceCategory;

  factory ServiceCategory.fromJson(Map<String, dynamic> json) => _$ServiceCategoryFromJson(json);
}

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository(ref.watch(apiClientProvider));
});

class CategoriesRepository {
  CategoriesRepository(this._dio);
  final Dio _dio;

  /// Public listings (home tile row, /categories grid, /list/<slug> resolve)
  /// pass `onlyWithMasters: true` so the user never sees a category that
  /// would lead to an empty results page. Master-registration leaves this
  /// off so the master can subscribe to any active category.
  Future<List<ServiceCategory>> list({bool onlyWithMasters = false}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/categories',
        queryParameters: {if (onlyWithMasters) 'only_with_masters': 1},
      );
      final list = (res.data!['categories'] as List?) ?? [];
      final parsed = list
          .map((e) => ServiceCategory.fromJson(e as Map<String, dynamic>))
          .toList();
      // Belt-and-braces: in case the backend ever returns a 0-count category
      // despite the flag, drop it client-side too.
      if (onlyWithMasters) {
        parsed.removeWhere((c) => c.mastersCount == 0);
      }
      return parsed;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ServiceCategory> show(int id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/categories/$id');
      return ServiceCategory.fromJson(res.data!['category'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
