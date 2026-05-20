import 'package:freezed_annotation/freezed_annotation.dart';

part 'order.freezed.dart';
part 'order.g.dart';

/// Mirror of backend Order::STATUS_* constants. When backend adds a status,
/// add it here too — `unknown` keeps deserialisation safe in the meantime.
enum OrderStatus {
  @JsonValue('draft') draft,
  @JsonValue('new') newOrder,
  @JsonValue('searching_master') searching,
  @JsonValue('pending_master') pendingMaster,
  @JsonValue('discussion') discussion,
  @JsonValue('pending_client') pendingClient,
  /// Master proposed time, client accepted but callout fee payment isn't done
  /// yet. The order is locked to this master but not yet committed; on payment
  /// success → confirmed, on timeout → back to pending_client.
  @JsonValue('pending_payment') pendingPayment,
  @JsonValue('confirmed') confirmed,
  @JsonValue('accepted') accepted,
  @JsonValue('on_the_way') onTheWay,
  @JsonValue('arrived') arrived,
  @JsonValue('in_progress') inProgress,
  @JsonValue('awaiting_completion') awaitingCompletion,
  @JsonValue('completed') completed,
  @JsonValue('awaiting_review') awaitingReview,
  @JsonValue('canceled_by_client') canceledByClient,
  @JsonValue('canceled_by_master') canceledByMaster,
  @JsonValue('canceled_by_system') canceledBySystem,
  @JsonValue('disputed') disputed,
  @JsonValue('closed') closed,
  unknown,
}

@freezed
class Order with _$Order {
  const Order._();
  const factory Order({
    required int id,
    @JsonKey(name: 'client_id') required int clientId,
    @JsonKey(name: 'master_id') int? masterId,
    @JsonKey(name: 'category_id') int? categoryId,
    @JsonKey(unknownEnumValue: OrderStatus.unknown) required OrderStatus status,
    String? description,
    String? address,
    @JsonKey(name: 'full_address') String? fullAddress,
    // Backend casts these to `decimal:7` so the JSON sends them as strings
    // ("40.4598000"). json_serializable's default `as num?` cast throws on
    // strings, so we coerce explicitly.
    @JsonKey(name: 'lat', fromJson: _toDouble) double? latitude,
    @JsonKey(name: 'lng', fromJson: _toDouble) double? longitude,
    @JsonKey(name: 'estimated_budget', fromJson: _toDouble) double? estimatedBudget,
    @JsonKey(name: 'agreed_price', fromJson: _toDouble) double? agreedPrice,
    @JsonKey(name: 'agreed_date') DateTime? agreedDate,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'completed_at') DateTime? completedAt,
    @JsonKey(name: 'canceled_at') DateTime? canceledAt,
    @JsonKey(name: 'closed_at') DateTime? closedAt,
    @JsonKey(name: 'cancel_reason') String? cancelReason,
    @JsonKey(name: 'client_reviewed') @Default(false) bool clientReviewed,
    @JsonKey(name: 'master_reviewed') @Default(false) bool masterReviewed,
    Map<String, dynamic>? category,
    Map<String, dynamic>? client,
    Map<String, dynamic>? master,
    @Default([]) List<Map<String, dynamic>> photos,
    @JsonKey(name: 'status_history') @Default([]) List<Map<String, dynamic>> statusHistory,
    @JsonKey(name: 'cancel_lat', fromJson: _toDouble) double? cancelLat,
    @JsonKey(name: 'cancel_lng', fromJson: _toDouble) double? cancelLng,
    @JsonKey(name: 'contact_phone') String? contactPhone,
    String? comment,
    String? urgency,
    @JsonKey(name: 'scheduled_at') DateTime? scheduledAt,
    @JsonKey(name: 'desired_time') String? desiredTime,
    @JsonKey(name: 'address_id') int? addressId,
    String? entrance,
    String? floor,
    String? intercom,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  bool get isOpenAnnouncement =>
      status == OrderStatus.searching || status == OrderStatus.pendingMaster;
  bool get isInProgress => {
        OrderStatus.confirmed,
        OrderStatus.accepted,
        OrderStatus.onTheWay,
        OrderStatus.arrived,
        OrderStatus.inProgress,
        OrderStatus.awaitingCompletion,
      }.contains(status);
  bool get isTerminal => {
        OrderStatus.completed,
        OrderStatus.closed,
        OrderStatus.canceledByClient,
        OrderStatus.canceledByMaster,
        OrderStatus.canceledBySystem,
      }.contains(status);
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
