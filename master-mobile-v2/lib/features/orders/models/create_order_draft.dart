import 'package:itez_mobile/features/orders/models/order_status.dart';

/// Тело POST /orders. Все опциональные поля — null, если пользователь
/// их не заполнил; backend сам валидирует обязательность.
class CreateOrderDraft {
  const CreateOrderDraft({
    required this.categoryId,
    this.subcategoryId,
    required this.description,
    required this.fullAddress,
    this.lat,
    this.lng,
    this.entrance,
    this.floor,
    this.intercom,
    required this.contactPhone,
    this.desiredTime = DesiredTime.asap,
    this.scheduledAt,
    this.urgency = OrderUrgency.normal,
    this.estimatedBudget,
    this.comment,
    this.preferredMasterId,
    this.photosBase64 = const [],
  });

  final int categoryId;
  final int? subcategoryId;
  final String description;
  final String fullAddress;
  final double? lat;
  final double? lng;
  final String? entrance;
  final String? floor;
  final String? intercom;
  final String contactPhone;
  final DesiredTime desiredTime;
  final DateTime? scheduledAt;
  final OrderUrgency urgency;
  final double? estimatedBudget;
  final String? comment;
  final int? preferredMasterId;
  final List<String> photosBase64;

  Map<String, dynamic> toBody() => {
        'category_id': categoryId,
        if (subcategoryId != null) 'subcategory_id': subcategoryId,
        'description': description,
        'full_address': fullAddress,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (entrance != null && entrance!.isNotEmpty) 'entrance': entrance,
        if (floor != null && floor!.isNotEmpty) 'floor': floor,
        if (intercom != null && intercom!.isNotEmpty) 'intercom': intercom,
        'contact_phone': contactPhone,
        'desired_time': desiredTime.value,
        if (scheduledAt != null)
          'scheduled_at': scheduledAt!.toUtc().toIso8601String(),
        'urgency': urgency.value,
        if (estimatedBudget != null) 'estimated_budget': estimatedBudget,
        if (comment != null && comment!.isNotEmpty) 'comment': comment,
        if (preferredMasterId != null) 'preferred_master_id': preferredMasterId,
        if (photosBase64.isNotEmpty) 'photos': photosBase64,
      };
}
