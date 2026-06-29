import 'package:itez_mobile/features/auth/models/user_model.dart';

/// Ответ login/register/refresh: пара `{user?, token}`. Refresh не возвращает
/// `user`, только `token` + `expires_at` — поэтому `user` nullable.
class AuthResponse {
  const AuthResponse({
    required this.token,
    this.user,
    this.expiresAt,
  });

  final String token;
  final UserModel? user;
  final DateTime? expiresAt;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['user'];
    return AuthResponse(
      token: json['token']?.toString() ?? '',
      user: raw is Map<String, dynamic> ? UserModel.fromJson(raw) : null,
      expiresAt: switch (json['expires_at']) {
        final String s when s.isNotEmpty => DateTime.tryParse(s),
        _ => null,
      },
    );
  }
}
