import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:master_mobile/features/auth/data/models/master_subscription.dart';

part 'user.freezed.dart';
part 'user.g.dart';

enum UserRole {
  @JsonValue('client') client,
  @JsonValue('master') master,
  @JsonValue('admin') admin,
}

@freezed
class User with _$User {
  const User._();
  const factory User({
    required int id,
    @JsonKey(name: 'first_name') required String firstName,
    @JsonKey(name: 'last_name') String? lastName,
    @JsonKey(name: 'full_name') required String fullName,
    String? email,
    required String phone,
    required UserRole role,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    String? locale,
    @JsonKey(name: 'rating_avg') String? ratingAvg,
    @JsonKey(name: 'rating_count') @Default(0) int ratingCount,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'is_verified') @Default(false) bool isVerified,
    @JsonKey(name: 'verified_at') DateTime? verifiedAt,
    @JsonKey(name: 'email_verified_at') DateTime? emailVerifiedAt,
    @JsonKey(name: 'phone_verified_at') DateTime? phoneVerifiedAt,
    MasterSubscription? subscription,
    @JsonKey(name: 'master_profile') Map<String, dynamic>? masterProfile,
    List<Map<String, dynamic>>? addresses,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  bool get isClient => role == UserRole.client;
  bool get isMaster => role == UserRole.master;
  bool get isAdmin => role == UserRole.admin;
  bool get emailVerified => emailVerifiedAt != null;
  bool get phoneVerified => phoneVerifiedAt != null;

  /// Master can take orders / chat / propose? Honors backend gate.
  bool get canOperate {
    if (!isMaster) return true;
    return subscription?.canOperate ?? false;
  }
}
