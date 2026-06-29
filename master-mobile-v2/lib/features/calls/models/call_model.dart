import 'package:itez_mobile/core/utils/json_parse.dart';

enum CallStatus {
  initiated('initiated'),
  ringing('ringing'),
  accepted('accepted'),
  rejected('rejected'),
  ended('ended'),
  missed('missed'),
  unknown('unknown');

  const CallStatus(this.value);
  final String value;

  static CallStatus fromValue(String? raw) {
    for (final s in CallStatus.values) {
      if (s.value == raw) return s;
    }
    return CallStatus.unknown;
  }
}

class CallModel {
  const CallModel({
    required this.id,
    required this.callerId,
    required this.calleeId,
    required this.status,
    required this.orderId,
    required this.createdAt,
    required this.raw,
  });

  final int id;
  final int callerId;
  final int calleeId;
  final CallStatus status;
  final int? orderId;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;

  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      id: parseInt(json['id']),
      callerId: parseInt(json['caller_id']),
      calleeId: parseInt(json['callee_id']),
      status: CallStatus.fromValue(json['status']?.toString()),
      orderId: parseIntOrNull(json['order_id']),
      createdAt: parseDate(json['created_at']),
      raw: json,
    );
  }
}

/// Сигнал WebRTC, передаваемый через REST + realtime.
class CallSignal {
  const CallSignal({
    required this.type,
    required this.payload,
  });

  /// 'offer' | 'answer' | 'ice'
  final String type;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {'type': type, 'payload': payload};

  factory CallSignal.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'];
    return CallSignal(
      type: json['type']?.toString() ?? 'unknown',
      payload: payload is Map<String, dynamic>
          ? payload
          : const <String, dynamic>{},
    );
  }
}
