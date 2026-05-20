import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_mobile/core/api/api_client.dart';
import 'package:master_mobile/core/api/api_exception.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.watch(apiClientProvider));
});

class WalletBalance {
  WalletBalance(this.cents, this.currency);
  final int cents;
  final String currency;
}

class WalletTransactionRow {
  WalletTransactionRow({
    required this.id,
    required this.kind,
    required this.amountCents,
    required this.currency,
    required this.orderId,
    required this.createdAt,
  });
  final int id;
  final String kind;
  /// Signed: positive = credit, negative = debit.
  final int amountCents;
  final String currency;
  final int? orderId;
  final DateTime createdAt;

  factory WalletTransactionRow.fromJson(Map<String, dynamic> j) => WalletTransactionRow(
        id: j['id'] as int,
        kind: j['kind'] as String,
        amountCents: (j['amount_cents'] as num).toInt(),
        currency: (j['currency'] as String?) ?? 'AZN',
        orderId: (j['order_id'] as num?)?.toInt(),
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class WithdrawalRow {
  WithdrawalRow({
    required this.id,
    required this.amountCents,
    required this.currency,
    required this.status,
    required this.iban,
    required this.createdAt,
  });
  final int id;
  final int amountCents;
  final String currency;
  /// pending|approved|paid|rejected|cancelled
  final String status;
  final String? iban;
  final DateTime createdAt;

  factory WithdrawalRow.fromJson(Map<String, dynamic> j) => WithdrawalRow(
        id: j['id'] as int,
        amountCents: (j['amount_cents'] as num).toInt(),
        currency: (j['currency'] as String?) ?? 'AZN',
        status: j['status'] as String,
        iban: j['iban'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class WalletRepository {
  WalletRepository(this._dio);
  final Dio _dio;

  Future<WalletBalance> balance() async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/wallet/balance');
      final d = r.data ?? const {};
      return WalletBalance((d['balance_cents'] as num?)?.toInt() ?? 0, (d['currency'] as String?) ?? 'AZN');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<WalletTransactionRow>> transactions({int limit = 50}) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/wallet/transactions', queryParameters: {'limit': limit});
      final list = (r.data?['transactions'] as List?) ?? const [];
      return list.map((e) => WalletTransactionRow.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<WithdrawalRow>> withdrawals() async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/withdrawals');
      final list = (r.data?['withdrawals'] as List?) ?? const [];
      return list.map((e) => WithdrawalRow.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> requestWithdrawal({
    required int amountCents,
    required String iban,
    required String holder,
    String? note,
  }) async {
    try {
      await _dio.post<void>('/withdrawals', data: {
        'amount_cents': amountCents,
        'iban': iban,
        'account_holder': holder,
        if (note != null && note.isNotEmpty) 'note': note,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> cancelWithdrawal(int id) async {
    try {
      await _dio.post<void>('/withdrawals/$id/cancel');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

/// Callout fee — payment side of the wallet feature, lives here to keep the
/// payment surface in one file.
final calloutFeeRepositoryProvider = Provider<CalloutFeeRepository>((ref) {
  return CalloutFeeRepository(ref.watch(apiClientProvider));
});

class CalloutFeePricing {
  CalloutFeePricing(this.amountCents, this.currency);
  final int amountCents;
  final String currency;
}

class CalloutFeeRepository {
  CalloutFeeRepository(this._dio);
  final Dio _dio;

  Future<CalloutFeePricing> preview(int orderId) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/orders/$orderId/callout-fee');
      final d = r.data ?? const {};
      return CalloutFeePricing((d['amount_cents'] as num?)?.toInt() ?? 2500, (d['currency'] as String?) ?? 'AZN');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> pay(int orderId, {required int paymentCardId}) async {
    try {
      await _dio.post<void>('/orders/$orderId/pay-callout', data: {
        'payment_card_id': paymentCardId,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
