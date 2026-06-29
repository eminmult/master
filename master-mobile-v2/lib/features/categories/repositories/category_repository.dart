import 'package:itez_mobile/core/api_client/api_client.dart';
import 'package:itez_mobile/core/api_client/urls.dart';
import 'package:itez_mobile/features/categories/models/category_model.dart';

class CategoryRepository {
  CategoryRepository(this._client);
  final ApiClient _client;

  Future<List<CategoryModel>> list({
    bool includeSubcategories = false,
    bool onlyWithMasters = true,
  }) async {
    final json = await _client.getJson(
      Urls.categories,
      queryParams: {
        if (includeSubcategories) 'include_subcategories': '1',
        if (onlyWithMasters) 'only_with_masters': '1',
      },
    );
    final raw = json['categories'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(CategoryModel.fromJson)
        .toList();
  }

  Future<CategoryModel> show(int id) async {
    final json = await _client.getJson(Urls.category(id));
    final raw = json['category'];
    if (raw is! Map<String, dynamic>) {
      throw StateError('GET /categories/$id returned no `category`');
    }
    return CategoryModel.fromJson(raw);
  }
}
