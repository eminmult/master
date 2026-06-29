import 'package:itez_mobile/core/api_client/api_client.dart';
import 'package:itez_mobile/core/api_client/urls.dart';
import 'package:itez_mobile/features/addresses/models/address_model.dart';

class AddressRepository {
  AddressRepository(this._client);
  final ApiClient _client;

  Future<List<AddressModel>> list() async {
    final json = await _client.getJson(Urls.addresses, requireAuth: true);
    final raw = json['addresses'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(AddressModel.fromJson)
        .toList();
  }

  Future<AddressModel> create(AddressModel draft) async {
    final json = await _client.postJson(
      Urls.addresses,
      body: draft.toCreateBody(),
      requireAuth: true,
    );
    final raw = json['address'];
    if (raw is! Map<String, dynamic>) {
      throw StateError('POST /addresses returned no `address`');
    }
    return AddressModel.fromJson(raw);
  }

  Future<AddressModel> update(int id, AddressModel draft) async {
    final json = await _client.putJson(
      Urls.address(id),
      body: draft.toCreateBody(),
    );
    final raw = json['address'];
    if (raw is! Map<String, dynamic>) {
      throw StateError('PUT /addresses/$id returned no `address`');
    }
    return AddressModel.fromJson(raw);
  }

  Future<void> delete(int id) async {
    await _client.deleteJson(Urls.address(id));
  }
}
