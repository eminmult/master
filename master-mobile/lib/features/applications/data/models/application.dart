import 'package:freezed_annotation/freezed_annotation.dart';

part 'application.freezed.dart';
part 'application.g.dart';

enum ApplicationStatus {
  @JsonValue('pending') pending,
  @JsonValue('discussing') discussing,
  @JsonValue('proposed') proposed,
  @JsonValue('accepted') accepted,
  @JsonValue('rejected') rejected,
  @JsonValue('withdrawn') withdrawn,
  unknown,
}

@freezed
class OrderApplication with _$OrderApplication {
  const factory OrderApplication({
    required int id,
    @JsonKey(name: 'order_id') required int orderId,
    @JsonKey(name: 'master_id') required int masterId,
    @JsonKey(unknownEnumValue: ApplicationStatus.unknown) required ApplicationStatus status,
    String? message,
    // Backend casts proposed_price to decimal:2 → JSON string. Coerce.
    @JsonKey(name: 'proposed_price', fromJson: _toDouble) double? proposedPrice,
    @JsonKey(name: 'proposed_date') DateTime? proposedDate,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    Map<String, dynamic>? master,
    /// Eagerly loaded order — present when backend returns the master's
    /// applications list (`/master/applications`). Has at least
    /// id/category/description/full_address/status fields.
    Map<String, dynamic>? order,
  }) = _OrderApplication;

  factory OrderApplication.fromJson(Map<String, dynamic> json) =>
      _$OrderApplicationFromJson(json);
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
