import 'package:itez_mobile/core/api_client/api_client.dart';
import 'package:itez_mobile/core/api_client/urls.dart';
import 'package:itez_mobile/features/auth/models/user_model.dart';

class ProfileRepository {
  ProfileRepository(this._client);
  final ApiClient _client;

  Future<UserModel> updateClient({
    required String firstName,
    String? lastName,
    String? email,
  }) async {
    final json = await _client.putJson(
      Urls.clientProfile,
      body: {
        'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (email != null) 'email': email,
      },
    );
    final raw = json['user'];
    if (raw is! Map<String, dynamic>) {
      throw StateError('PUT /client/profile returned no `user`');
    }
    return UserModel.fromJson(raw);
  }

  /// Backend для мастера принимает свой набор полей; держим `extra` Map,
  /// чтобы UI мог добавлять любые поля без правки сигнатуры.
  Future<UserModel> updateMaster({
    String? firstName,
    String? lastName,
    String? email,
    Map<String, dynamic> extra = const {},
  }) async {
    final json = await _client.putJson(
      Urls.masterProfile,
      body: {
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (email != null) 'email': email,
        ...extra,
      },
    );
    final raw = json['user'];
    if (raw is! Map<String, dynamic>) {
      throw StateError('PUT /master/profile returned no `user`');
    }
    return UserModel.fromJson(raw);
  }

  Future<void> setLocale(String locale) async {
    await _client.patchJson(Urls.meLocale, body: {'locale': locale});
  }

  Future<void> exportData() async {
    await _client.postJson(Urls.meExport, requireAuth: true);
  }

  Future<void> deleteAccount({String? reason}) async {
    await _client.postJson(
      Urls.meDelete,
      body: {if (reason != null && reason.isNotEmpty) 'reason': reason},
      requireAuth: true,
    );
  }
}
