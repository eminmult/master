import 'package:itez_mobile/core/utils/json_parse.dart';

/// Адрес клиента (используется при создании заказа).
/// Соответствует таблице `addresses` Laravel-моделей.
class AddressModel {
  const AddressModel({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.lat,
    required this.lng,
    required this.entrance,
    required this.floor,
    required this.intercom,
    required this.note,
    required this.isDefault,
  });

  final int id;
  final String? label;
  final String fullAddress;
  final double? lat;
  final double? lng;
  final String? entrance;
  final String? floor;
  final String? intercom;
  final String? note;
  final bool isDefault;

  String get displayTitle {
    if (label != null && label!.isNotEmpty) return label!;
    return fullAddress;
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: parseInt(json['id']),
      label: json['label']?.toString(),
      fullAddress: json['full_address']?.toString() ?? '',
      lat: parseDoubleOrNull(json['lat']),
      lng: parseDoubleOrNull(json['lng']),
      entrance: json['entrance']?.toString(),
      floor: json['floor']?.toString(),
      intercom: json['intercom']?.toString(),
      note: json['note']?.toString(),
      isDefault: parseBool(json['is_default']),
    );
  }

  Map<String, dynamic> toCreateBody() => {
        if (label != null && label!.isNotEmpty) 'label': label,
        'full_address': fullAddress,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (entrance != null && entrance!.isNotEmpty) 'entrance': entrance,
        if (floor != null && floor!.isNotEmpty) 'floor': floor,
        if (intercom != null && intercom!.isNotEmpty) 'intercom': intercom,
        if (note != null && note!.isNotEmpty) 'note': note,
        'is_default': isDefault,
      };
}
