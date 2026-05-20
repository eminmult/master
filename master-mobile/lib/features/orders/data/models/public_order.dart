import 'package:freezed_annotation/freezed_annotation.dart';

part 'public_order.freezed.dart';
part 'public_order.g.dart';

/// Light-weight DTO for the public order feed (`GET /api/v1/orders/public`).
///
/// The endpoint hides identifying fields (no client_id / status / full
/// address) so guests browsing announcements can't fingerprint requesters.
/// We keep this separate from [Order] so the strict required fields on the
/// authenticated detail model don't crash the parser when faced with the
/// public projection.
@freezed
class PublicOrderItem with _$PublicOrderItem {
  const factory PublicOrderItem({
    required int id,
    String? description,
    String? district,
    String? urgency,
    @JsonKey(name: 'estimated_budget') String? estimatedBudget,
    @JsonKey(name: 'desired_time') String? desiredTime,
    @JsonKey(name: 'scheduled_at') DateTime? scheduledAt,
    @JsonKey(name: 'distance_km') double? distanceKm,
    @JsonKey(name: 'photos_count') @Default(0) int photosCount,
    @JsonKey(name: 'first_photo') String? firstPhoto,
    String? comment,
    Map<String, dynamic>? category,
    Map<String, dynamic>? subcategory,
    Map<String, dynamic>? client,
    /// Public detail returns the full photo list as `[{id, url}, ...]`.
    @Default([]) List<Map<String, dynamic>> photos,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _PublicOrderItem;

  factory PublicOrderItem.fromJson(Map<String, dynamic> json) =>
      _$PublicOrderItemFromJson(json);
}
