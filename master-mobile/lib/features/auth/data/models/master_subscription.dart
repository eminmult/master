import 'package:freezed_annotation/freezed_annotation.dart';

part 'master_subscription.freezed.dart';
part 'master_subscription.g.dart';

@freezed
class MasterSubscription with _$MasterSubscription {
  const factory MasterSubscription({
    required bool active,
    @JsonKey(name: 'expires_at') DateTime? expiresAt,
    required bool required,
    @JsonKey(name: 'free_launch_until') String? freeLaunchUntil,
    @JsonKey(name: 'can_operate') required bool canOperate,
  }) = _MasterSubscription;

  factory MasterSubscription.fromJson(Map<String, dynamic> json) =>
      _$MasterSubscriptionFromJson(json);
}
