import 'package:itez_mobile/core/api_client/api_client.dart';
import 'package:itez_mobile/core/api_client/urls.dart';
import 'package:itez_mobile/features/masters/models/master_detail.dart';
import 'package:itez_mobile/features/masters/models/master_list_item.dart';
import 'package:itez_mobile/features/masters/models/master_review.dart';

/// Параметры списка мастеров — single source of truth для query params.
/// Передаётся в BLoC, репозиторий просто складывает их в `?key=value`.
class MasterListFilter {
  const MasterListFilter({
    this.search,
    this.categoryId,
    this.categorySlug,
    this.city,
    this.citySlug,
    this.district,
    this.onlineOnly = false,
    this.minRating,
    this.lat,
    this.lng,
    this.sort = 'orders',
  });

  final String? search;
  final int? categoryId;
  final String? categorySlug;
  final String? city;
  final String? citySlug;
  final String? district;
  final bool onlineOnly;
  final double? minRating;
  final double? lat;
  final double? lng;

  /// orders | rating | experience | newest | distance
  final String sort;

  Map<String, dynamic> toQuery() => {
        if (search != null && search!.isNotEmpty) 'search': search,
        if (categoryId != null) 'category_id': categoryId,
        if (categorySlug != null && categorySlug!.isNotEmpty)
          'category_slug': categorySlug,
        if (city != null && city!.isNotEmpty) 'city': city,
        if (citySlug != null && citySlug!.isNotEmpty) 'city_slug': citySlug,
        if (district != null && district!.isNotEmpty) 'district': district,
        if (onlineOnly) 'online': 1,
        if (minRating != null) 'min_rating': minRating,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'sort': sort,
      };

  MasterListFilter copyWith({
    String? search,
    int? categoryId,
    String? categorySlug,
    String? city,
    String? citySlug,
    String? district,
    bool? onlineOnly,
    double? minRating,
    double? lat,
    double? lng,
    String? sort,
  }) =>
      MasterListFilter(
        search: search ?? this.search,
        categoryId: categoryId ?? this.categoryId,
        categorySlug: categorySlug ?? this.categorySlug,
        city: city ?? this.city,
        citySlug: citySlug ?? this.citySlug,
        district: district ?? this.district,
        onlineOnly: onlineOnly ?? this.onlineOnly,
        minRating: minRating ?? this.minRating,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        sort: sort ?? this.sort,
      );
}

class MasterRepository {
  MasterRepository(this._client);
  final ApiClient _client;

  Future<List<MasterListItem>> list(MasterListFilter filter) async {
    final json = await _client.getJson(
      Urls.masters,
      queryParams: filter.toQuery(),
    );
    final raw = json['masters'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(MasterListItem.fromJson)
        .toList();
  }

  Future<MasterDetail> show(String idOrSlug) async {
    final json = await _client.getJson(Urls.master(idOrSlug));
    final raw = json['master'];
    if (raw is! Map<String, dynamic>) {
      throw StateError('GET /masters/$idOrSlug returned no `master`');
    }
    return MasterDetail.fromJson(raw);
  }

  Future<MasterReviewsPage> reviews(
    String idOrSlug, {
    int limit = 10,
    int offset = 0,
  }) async {
    final json = await _client.getJson(
      Urls.masterReviews(idOrSlug),
      queryParams: {'limit': limit, 'offset': offset},
    );
    final raw = json['reviews'];
    final total = (json['total'] as num?)?.toInt() ?? 0;
    final items = raw is List
        ? raw
            .whereType<Map<String, dynamic>>()
            .map(MasterReview.fromJson)
            .toList()
        : <MasterReview>[];
    return MasterReviewsPage(items: items, total: total);
  }
}

class MasterReviewsPage {
  const MasterReviewsPage({required this.items, required this.total});
  final List<MasterReview> items;
  final int total;
}
