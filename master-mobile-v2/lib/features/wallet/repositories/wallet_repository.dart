import 'package:itez_mobile/core/api_client/api_client.dart';
import 'package:itez_mobile/core/api_client/urls.dart';
import 'package:itez_mobile/features/wallet/models/wallet_balance.dart';

class WalletRepository {
  WalletRepository(this._client);
  final ApiClient _client;

  Future<WalletBalance> balance() async {
    final json = await _client.getJson(Urls.walletBalance, requireAuth: true);
    final raw = json['balance'] is Map<String, dynamic>
        ? json['balance'] as Map<String, dynamic>
        : json;
    return WalletBalance.fromJson(raw);
  }

  Future<List<WalletTransaction>> transactions({int page = 1}) async {
    final json = await _client.getJson(
      Urls.walletTx,
      queryParams: {'page': page},
      requireAuth: true,
    );
    final raw = json['transactions'] ?? json['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(WalletTransaction.fromJson)
        .toList();
  }

  /// Превью комиссии (используется на странице оплаты выезда).
  Future<Map<String, dynamic>> calloutPreview(int orderId) async {
    return _client.getJson(Urls.orderCalloutFee(orderId), requireAuth: true);
  }

  Future<Map<String, dynamic>> payCallout(int orderId) async {
    return _client.postJson(Urls.orderPayCallout(orderId), requireAuth: true);
  }
}
