/// Карточка мастера в списке. Соответствует item из `GET /masters`.
class MasterListItem {
  const MasterListItem({
    required this.id,
    required this.slug,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.avatarUrl,
    required this.ratingAvg,
    required this.ratingCount,
    required this.description,
    required this.experienceYears,
    required this.city,
    required this.district,
    required this.isOnline,
    required this.isAccepting,
    required this.isVerified,
    required this.completedOrders,
    required this.categories,
    required this.distanceKm,
  });

  final int id;
  final String slug;
  final String? firstName;
  final String? lastName;
  final String fullName;
  final String? avatarUrl;
  final double ratingAvg;
  final int ratingCount;
  final String? description;
  final int experienceYears;
  final String? city;
  final String? district;
  final bool isOnline;
  final bool isAccepting;
  final bool isVerified;
  final int completedOrders;
  final List<CategoryRef> categories;
  final double? distanceKm;

  bool get isActiveNow => isOnline && isAccepting;

  factory MasterListItem.fromJson(Map<String, dynamic> json) {
    final catsRaw = json['categories'];
    return MasterListItem(
      id: _toInt(json['id']),
      slug: json['slug']?.toString() ?? '',
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      fullName: json['full_name']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      ratingAvg: _toDouble(json['rating_avg']),
      ratingCount: _toInt(json['rating_count']),
      description: json['description']?.toString(),
      experienceYears: _toInt(json['experience_years']),
      city: json['city']?.toString(),
      district: json['district']?.toString(),
      isOnline: json['is_online'] == true,
      isAccepting: json['is_accepting'] == true,
      isVerified: json['is_verified'] == true,
      completedOrders: _toInt(json['completed_orders']),
      categories: catsRaw is List
          ? catsRaw
              .whereType<Map<String, dynamic>>()
              .map(CategoryRef.fromJson)
              .toList()
          : const [],
      distanceKm: _toDoubleOrNull(json['distance_km']),
    );
  }
}

/// Бэкенд частично шлёт числа как строки (Laravel decimal cast → "4.64").
/// Толерантный парсер: `num | String | null` → нормализованный int/double.
int _toInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? 0;
  return 0;
}

double _toDouble(Object? v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

double? _toDoubleOrNull(Object? v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

class CategoryRef {
  const CategoryRef({
    required this.id,
    required this.slug,
    required this.name,
    required this.iconUrl,
  });

  final int id;
  final String slug;
  final String name;
  final String? iconUrl;

  factory CategoryRef.fromJson(Map<String, dynamic> json) {
    return CategoryRef(
      id: _toInt(json['id']),
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      iconUrl: json['icon_url']?.toString(),
    );
  }
}
