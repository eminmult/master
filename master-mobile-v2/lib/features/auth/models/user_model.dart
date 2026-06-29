import 'package:itez_mobile/features/auth/models/user_role.dart';

/// Зеркало `userResponse()` из AuthController на backend.
/// Поля `master_profile`/`addresses` подгружаются только когда сервер их
/// положил в payload — мы не моделируем их строго на старте, оставляем
/// как сырой Map; в Phase 3/4 заведём строгие модели MasterProfile/Address
/// и переключимся.
class UserModel {
  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.avatarUrl,
    required this.locale,
    required this.ratingAvg,
    required this.ratingCount,
    required this.isActive,
    required this.isVerified,
    required this.verifiedAt,
    required this.emailVerifiedAt,
    required this.phoneVerifiedAt,
    required this.createdAt,
    this.subscription,
    this.masterProfile,
    this.addresses,
  });

  final int id;
  final String firstName;
  final String? lastName;
  final String fullName;
  final String? email;
  final String phone;
  final UserRole role;
  final String? avatarUrl;
  final String? locale;
  final double ratingAvg;
  final int ratingCount;
  final bool isActive;
  final bool isVerified;
  final DateTime? verifiedAt;
  final DateTime? emailVerifiedAt;
  final DateTime? phoneVerifiedAt;
  final DateTime? createdAt;

  final Map<String, dynamic>? subscription;
  final Map<String, dynamic>? masterProfile;
  final List<dynamic>? addresses;

  bool get isClient => role.isClient;
  bool get isMaster => role.isMaster;
  bool get hasVerifiedPhone => phoneVerifiedAt != null;
  bool get hasVerifiedEmail => emailVerifiedAt != null;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _num(json['id']).toInt(),
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString(),
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString() ?? '',
      role: UserRole.fromValue(json['role']?.toString()),
      avatarUrl: json['avatar_url']?.toString(),
      locale: json['locale']?.toString(),
      ratingAvg: _num(json['rating_avg']).toDouble(),
      ratingCount: _num(json['rating_count']).toInt(),
      isActive: json['is_active'] == true,
      isVerified: json['is_verified'] == true,
      verifiedAt: _date(json['verified_at']),
      emailVerifiedAt: _date(json['email_verified_at']),
      phoneVerifiedAt: _date(json['phone_verified_at']),
      createdAt: _date(json['created_at']),
      subscription: json['subscription'] is Map<String, dynamic>
          ? json['subscription'] as Map<String, dynamic>
          : null,
      masterProfile: json['master_profile'] is Map<String, dynamic>
          ? json['master_profile'] as Map<String, dynamic>
          : null,
      addresses: json['addresses'] is List ? json['addresses'] as List : null,
    );
  }

  static num _num(Object? v) {
    if (v is num) return v;
    if (v is String) return num.tryParse(v) ?? 0;
    return 0;
  }

  static DateTime? _date(Object? v) {
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }
}
