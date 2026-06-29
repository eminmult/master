import 'package:itez_mobile/core/utils/json_parse.dart';

/// Категория услуг. Зеркало `projectCategory()` из бэкенда.
/// Slug — канонический (AZ) для всех локалей; имя — локализованное.
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.nameAz,
    required this.slug,
    required this.iconUrl,
    required this.description,
    required this.sortOrder,
    required this.mastersCount,
    required this.subcategories,
    this.content,
  });

  final int id;
  final String name;
  final String nameAz;
  final String slug;
  final String? iconUrl;
  final String? description;
  final int sortOrder;
  final int mastersCount;
  final List<SubcategoryModel> subcategories;
  final String? content;

  bool get hasMasters => mastersCount > 0;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final subsRaw = json['subcategories'];
    final subs = subsRaw is List
        ? subsRaw
            .whereType<Map<String, dynamic>>()
            .map(SubcategoryModel.fromJson)
            .toList()
        : <SubcategoryModel>[];
    return CategoryModel(
      id: parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      nameAz: json['name_az']?.toString() ?? json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      iconUrl: json['icon_url']?.toString(),
      description: json['description']?.toString(),
      sortOrder: parseInt(json['sort_order']),
      mastersCount: parseInt(json['masters_count']),
      subcategories: subs,
      content: json['content']?.toString(),
    );
  }
}

class SubcategoryModel {
  const SubcategoryModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  final int id;
  final String name;
  final String slug;

  factory SubcategoryModel.fromJson(Map<String, dynamic> json) {
    return SubcategoryModel(
      id: parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
    );
  }
}
