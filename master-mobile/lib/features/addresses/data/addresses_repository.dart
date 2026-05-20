import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:master_mobile/core/api/api_client.dart';
import 'package:master_mobile/core/api/api_exception.dart';

part 'addresses_repository.freezed.dart';
part 'addresses_repository.g.dart';

@freezed
class Address with _$Address {
  const factory Address({
    required int id,
    @JsonKey(name: 'user_id') required int userId,
    String? label,
    @JsonKey(name: 'full_address') required String fullAddress,
    @JsonKey(fromJson: _toDouble) double? lat,
    @JsonKey(fromJson: _toDouble) double? lng,
    String? entrance,
    String? floor,
    String? intercom,
    String? note,
    @JsonKey(name: 'is_default') @Default(false) bool isDefault,
  }) = _Address;

  factory Address.fromJson(Map<String, dynamic> json) => _$AddressFromJson(json);
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

final addressesRepositoryProvider = Provider<AddressesRepository>((ref) {
  return AddressesRepository(ref.watch(apiClientProvider));
});

/// FutureProvider for the auth-scoped address list. Auto-disposes after
/// 5 minutes of no listeners; refreshable with `ref.invalidate(...)`.
final addressesListProvider = FutureProvider<List<Address>>((ref) async {
  return ref.watch(addressesRepositoryProvider).list();
});

class AddressesRepository {
  AddressesRepository(this._dio);
  final Dio _dio;

  Future<List<Address>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/addresses');
      final raw = (res.data!['addresses'] as List?) ?? [];
      return raw.map((e) => Address.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Address> create({
    String? label,
    required String fullAddress,
    double? lat,
    double? lng,
    String? entrance,
    String? floor,
    String? intercom,
    String? note,
    bool isDefault = false,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/addresses',
        data: {
          if (label != null && label.isNotEmpty) 'label': label,
          'full_address': fullAddress,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
          if (entrance != null && entrance.isNotEmpty) 'entrance': entrance,
          if (floor != null && floor.isNotEmpty) 'floor': floor,
          if (intercom != null && intercom.isNotEmpty) 'intercom': intercom,
          if (note != null && note.isNotEmpty) 'note': note,
          'is_default': isDefault,
        },
      );
      return Address.fromJson(res.data!['address'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Address> update(int id, {
    String? label,
    required String fullAddress,
    double? lat,
    double? lng,
    String? entrance,
    String? floor,
    String? intercom,
    String? note,
    bool? isDefault,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/addresses/$id',
        data: {
          if (label != null) 'label': label,
          'full_address': fullAddress,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
          if (entrance != null) 'entrance': entrance,
          if (floor != null) 'floor': floor,
          if (intercom != null) 'intercom': intercom,
          if (note != null) 'note': note,
          if (isDefault != null) 'is_default': isDefault,
        },
      );
      return Address.fromJson(res.data!['address'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> destroy(int id) async {
    try {
      await _dio.delete('/addresses/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
