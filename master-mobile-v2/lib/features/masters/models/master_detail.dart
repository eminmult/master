import 'package:itez_mobile/features/masters/models/master_list_item.dart';

/// Деталь мастера. Соответствует `master` из `GET /masters/{idOrSlug}`.
/// Делим тяжёлые секции (skills/portfolio) как сырой Map, чтобы UI
/// мог отрисовать всё что есть без перетряхивания моделей при изменении бэка.
class MasterDetail {
  const MasterDetail({
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
    required this.urgentAvailable,
    required this.workRadiusKm,
    required this.languages,
    required this.categories,
    required this.skillsByGroup,
    required this.portfolio,
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
  final bool urgentAvailable;
  final double? workRadiusKm;
  final List<String> languages;
  final List<CategoryRef> categories;
  final Map<String, List<Map<String, dynamic>>> skillsByGroup;
  final List<Map<String, dynamic>> portfolio;

  factory MasterDetail.fromJson(Map<String, dynamic> json) {
    final catsRaw = json['categories'];
    final cats = catsRaw is List
        ? catsRaw
            .whereType<Map<String, dynamic>>()
            .map(CategoryRef.fromJson)
            .toList()
        : <CategoryRef>[];

    final skillsRaw = json['skills'];
    final skills = <String, List<Map<String, dynamic>>>{};
    if (skillsRaw is Map) {
      skillsRaw.forEach((k, v) {
        if (v is List) {
          skills[k.toString()] = v.whereType<Map<String, dynamic>>().toList();
        }
      });
    }

    final portfolioRaw = json['portfolio'];
    final portfolio = portfolioRaw is List
        ? portfolioRaw.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];

    final langsRaw = json['languages'];
    final langs = langsRaw is List
        ? langsRaw.map((e) => e.toString()).toList()
        : <String>[];

    return MasterDetail(
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
      urgentAvailable: json['urgent_available'] == true,
      workRadiusKm: _toDoubleOrNull(json['work_radius_km']),
      languages: langs,
      categories: cats,
      skillsByGroup: skills,
      portfolio: portfolio,
    );
  }
}

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
