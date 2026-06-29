import 'package:itez_mobile/core/api_client/api_client.dart';
import 'package:itez_mobile/core/api_client/urls.dart';
import 'package:itez_mobile/features/auth/models/auth_response.dart';
import 'package:itez_mobile/features/auth/models/user_model.dart';

/// Все вызовы к `/auth/*`. Ошибки `ApiClient` поднимает иерархией
/// [AppException], репозиторий их не глотает — пусть BLoC решает,
/// как маппить на UI.
class AuthRepository {
  AuthRepository(this._client);
  final ApiClient _client;

  Future<AuthResponse> login({
    required String login,
    required String password,
  }) async {
    final json = await _client.postJson(
      Urls.authLogin,
      body: {'login': login, 'password': password},
    );
    return AuthResponse.fromJson(json);
  }

  Future<AuthResponse> registerClient({
    required String firstName,
    String? lastName,
    required String phone,
    String? email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final json = await _client.postJson(
      Urls.authRegisterClient,
      body: {
        'first_name': firstName,
        if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
        'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    return AuthResponse.fromJson(json);
  }

  Future<AuthResponse> registerMaster({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String city,
    String? district,
    required String description,
    required int experienceYears,
    required List<int> categoryIds,
  }) async {
    final json = await _client.postJson(
      Urls.authRegisterMaster,
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'city': city,
        if (district != null && district.isNotEmpty) 'district': district,
        'description': description,
        'experience_years': experienceYears,
        'category_ids': categoryIds,
      },
    );
    return AuthResponse.fromJson(json);
  }

  Future<UserModel> me() async {
    final json = await _client.getJson(Urls.authMe, requireAuth: true);
    final raw = json['user'];
    if (raw is! Map<String, dynamic>) {
      throw StateError('Auth /me returned no `user`');
    }
    return UserModel.fromJson(raw);
  }

  Future<void> logout() async {
    await _client.postJson(Urls.authLogout, requireAuth: true);
  }

  Future<void> forgotPassword(String login) async {
    await _client.postJson(Urls.authForgotPassword, body: {'login': login});
  }

  Future<void> resetPassword({
    required String login,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _client.postJson(
      Urls.authResetPassword,
      body: {
        'login': login,
        'token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    await _client.postJson(
      Urls.authChangePassword,
      body: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPasswordConfirmation,
      },
      requireAuth: true,
    );
  }

  Future<void> requestPhoneOtp() async {
    await _client.postJson(Urls.authPhoneRequestOtp, requireAuth: true);
  }

  Future<UserModel> verifyPhoneOtp(String code) async {
    final json = await _client.postJson(
      Urls.authPhoneVerifyOtp,
      body: {'code': code},
      requireAuth: true,
    );
    final raw = json['user'];
    if (raw is! Map<String, dynamic>) {
      throw StateError('verify-otp returned no `user`');
    }
    return UserModel.fromJson(raw);
  }
}
