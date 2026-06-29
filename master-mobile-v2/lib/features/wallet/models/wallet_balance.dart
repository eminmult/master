import 'package:itez_mobile/core/utils/json_parse.dart';

class WalletBalance {
  const WalletBalance({
    required this.available,
    required this.pending,
    required this.currency,
  });

  final double available;
  final double pending;
  final String currency;

  double get total => available + pending;

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      available: parseDouble(json['available'] ?? json['balance']),
      pending: parseDouble(json['pending']),
      currency: (json['currency'] ?? '₼').toString(),
    );
  }
}

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  final int id;
  final String type;
  final double amount;
  final String description;
  final DateTime? createdAt;

  bool get isIncome => amount >= 0;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: parseInt(json['id']),
      type: json['type']?.toString() ?? '',
      amount: parseDouble(json['amount']),
      description: (json['description'] ?? json['note'] ?? '').toString(),
      createdAt: parseDate(json['created_at']),
    );
  }
}
