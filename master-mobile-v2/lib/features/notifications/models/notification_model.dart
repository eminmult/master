/// Уведомление приходит из бэка как DatabaseNotification —
/// `{id, type, data, read_at, created_at}`. `data` — payload произвольной
/// структуры; чтобы клиент мог отрисовать без правки модели на каждый новый
/// тип, держим её сырой и достаём `title/message/order_id` по конвенции.
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.data,
    required this.readAt,
    required this.createdAt,
  });

  /// Backend для DatabaseNotification использует UUID-строки.
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime? createdAt;

  bool get isUnread => readAt == null;

  String get title =>
      (data['title'] ?? data['subject'] ?? 'Уведомление').toString();
  String get message =>
      (data['message'] ?? data['body'] ?? '').toString();
  int? get orderId {
    final raw = data['order_id'];
    return raw is num ? raw.toInt() : null;
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      data: raw is Map<String, dynamic> ? raw : const {},
      readAt: _date(json['read_at']),
      createdAt: _date(json['created_at']),
    );
  }

  static DateTime? _date(Object? v) {
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }
}
