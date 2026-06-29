import 'package:itez_mobile/features/orders/models/order_status.dart';

/// Универсальная модель заказа. Используется и для списка `/orders/my`,
/// и для деталки `/orders/{id}`. Поля, которые присутствуют только в одном
/// из вариантов (statusHistory, applications, master), nullable.
class OrderModel {
  const OrderModel({
    required this.id,
    required this.status,
    required this.description,
    required this.fullAddress,
    required this.urgency,
    required this.desiredTime,
    required this.scheduledAt,
    required this.estimatedBudget,
    required this.contactPhone,
    required this.createdAt,
    required this.categoryId,
    required this.categoryName,
    required this.subcategoryName,
    required this.clientId,
    required this.masterId,
    required this.lat,
    required this.lng,
    required this.photos,
    required this.client,
    required this.master,
    required this.raw,
  });

  final int id;
  final OrderStatus status;
  final String? description;
  final String? fullAddress;
  final OrderUrgency urgency;
  final DesiredTime desiredTime;
  final DateTime? scheduledAt;
  final double? estimatedBudget;
  final String? contactPhone;
  final DateTime? createdAt;
  final int? categoryId;
  final String? categoryName;
  final String? subcategoryName;
  final int? clientId;
  final int? masterId;
  final double? lat;
  final double? lng;
  final List<OrderPhoto> photos;
  final OrderParty? client;
  final OrderParty? master;

  /// Полный JSON для секций, которые мы не моделируем строго
  /// (statusHistory, applications, master_profile, кастомные поля).
  final Map<String, dynamic> raw;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final cat = json['category'];
    final sub = json['subcategory'];
    final client = json['client'];
    final master = json['master'];
    final photosRaw = json['photos'];

    return OrderModel(
      id: _toInt(json['id']),
      status: OrderStatus.fromValue(json['status']?.toString()),
      description: json['description']?.toString(),
      fullAddress: json['full_address']?.toString(),
      urgency: OrderUrgency.fromValue(json['urgency']?.toString()),
      desiredTime: DesiredTime.fromValue(json['desired_time']?.toString()),
      scheduledAt: _date(json['scheduled_at']),
      estimatedBudget: _toDoubleOrNull(json['estimated_budget']),
      contactPhone: json['contact_phone']?.toString(),
      createdAt: _date(json['created_at']),
      categoryId: cat is Map ? _toIntOrNull(cat['id']) : null,
      categoryName: cat is Map ? cat['name']?.toString() : null,
      subcategoryName: sub is Map ? sub['name']?.toString() : null,
      clientId: _toIntOrNull(json['client_id']),
      masterId: _toIntOrNull(json['master_id']),
      lat: _toDoubleOrNull(json['lat']),
      lng: _toDoubleOrNull(json['lng']),
      photos: photosRaw is List
          ? photosRaw
              .whereType<Map<String, dynamic>>()
              .map(OrderPhoto.fromJson)
              .toList()
          : const [],
      client: client is Map<String, dynamic> ? OrderParty.fromJson(client) : null,
      master: master is Map<String, dynamic> ? OrderParty.fromJson(master) : null,
      raw: json,
    );
  }

  static DateTime? _date(Object? v) {
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }
}

int _toInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? 0;
  return 0;
}

int? _toIntOrNull(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt();
  return null;
}

double? _toDoubleOrNull(Object? v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

class OrderPhoto {
  const OrderPhoto({required this.id, required this.url, required this.type});

  final int id;
  final String url;
  final String? type;

  factory OrderPhoto.fromJson(Map<String, dynamic> json) => OrderPhoto(
        id: _toInt(json['id']),
        url: json['url']?.toString() ?? '',
        type: json['type']?.toString(),
      );
}

class OrderParty {
  const OrderParty({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.avatarUrl,
    required this.phone,
    required this.ratingAvg,
    required this.ratingCount,
  });

  final int id;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final double? ratingAvg;
  final int? ratingCount;

  String get displayName =>
      fullName ?? [firstName, lastName].whereType<String>().join(' ').trim();

  factory OrderParty.fromJson(Map<String, dynamic> json) => OrderParty(
        id: _toIntOrNull(json['id']) ?? 0,
        firstName: json['first_name']?.toString(),
        lastName: json['last_name']?.toString(),
        fullName: json['full_name']?.toString(),
        avatarUrl: json['avatar_url']?.toString(),
        phone: json['phone']?.toString(),
        ratingAvg: _toDoubleOrNull(json['rating_avg']),
        ratingCount: _toIntOrNull(json['rating_count']),
      );
}
