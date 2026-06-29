import 'package:itez_mobile/core/utils/json_parse.dart';

/// Статусы отклика. Соответствуют backend `OrderApplication::STATUS_*`.
enum ApplicationStatus {
  pending('pending'),
  discussing('discussing'),
  proposed('proposed'),
  accepted('accepted'),
  rejected('rejected'),
  withdrawn('withdrawn'),
  unknown('unknown');

  const ApplicationStatus(this.value);
  final String value;

  static ApplicationStatus fromValue(String? raw) {
    if (raw == null) return ApplicationStatus.unknown;
    for (final s in ApplicationStatus.values) {
      if (s.value == raw) return s;
    }
    return ApplicationStatus.unknown;
  }

  bool get isOpen => const {
        ApplicationStatus.pending,
        ApplicationStatus.discussing,
        ApplicationStatus.proposed,
      }.contains(this);

  bool get isClosed => const {
        ApplicationStatus.rejected,
        ApplicationStatus.withdrawn,
      }.contains(this);
}

/// Отклик мастера на публичный заказ.
/// Зеркало того, что `/master/applications` возвращает (с eager-loaded `order`).
class OrderApplication {
  const OrderApplication({
    required this.id,
    required this.orderId,
    required this.masterId,
    required this.status,
    required this.message,
    required this.proposedPrice,
    required this.proposedDate,
    required this.createdAt,
    required this.master,
    required this.order,
  });

  final int id;
  final int orderId;
  final int masterId;
  final ApplicationStatus status;
  final String? message;
  final double? proposedPrice;
  final DateTime? proposedDate;
  final DateTime? createdAt;

  /// Сырые блоки от бэка — UI рисует только нужные поля.
  final Map<String, dynamic>? master;
  final Map<String, dynamic>? order;

  String? get orderTitle {
    final o = order;
    if (o == null) return null;
    final cat = o['category'];
    if (cat is Map) return cat['name']?.toString();
    return null;
  }

  String? get orderDescription => order?['description']?.toString();

  factory OrderApplication.fromJson(Map<String, dynamic> json) {
    return OrderApplication(
      id: parseInt(json['id']),
      orderId: parseInt(json['order_id']),
      masterId: parseInt(json['master_id']),
      status: ApplicationStatus.fromValue(json['status']?.toString()),
      message: json['message']?.toString(),
      proposedPrice: parseDoubleOrNull(json['proposed_price']),
      proposedDate: parseDate(json['proposed_date']),
      createdAt: parseDate(json['created_at']),
      master: json['master'] is Map<String, dynamic>
          ? json['master'] as Map<String, dynamic>
          : null,
      order: json['order'] is Map<String, dynamic>
          ? json['order'] as Map<String, dynamic>
          : null,
    );
  }
}
