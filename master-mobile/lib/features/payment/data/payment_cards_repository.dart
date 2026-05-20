import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:master_mobile/core/api/api_client.dart';
import 'package:master_mobile/core/api/api_exception.dart';

part 'payment_cards_repository.freezed.dart';
part 'payment_cards_repository.g.dart';

/// Saved card row as returned by `/payment-cards`. PAN/CVV never leave the
/// add-card form — only brand/last4/expiry/holder are persisted.
@freezed
class PaymentCard with _$PaymentCard {
  const factory PaymentCard({
    required int id,
    @JsonKey(name: 'user_id') required int userId,
    required String brand,
    required String last4,
    @JsonKey(name: 'exp_month') required int expMonth,
    @JsonKey(name: 'exp_year') required int expYear,
    @JsonKey(name: 'holder_name') String? holderName,
    @JsonKey(name: 'is_default') @Default(false) bool isDefault,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _PaymentCard;
  factory PaymentCard.fromJson(Map<String, dynamic> json) =>
      _$PaymentCardFromJson(json);
}

class PaymentCardsRepository {
  PaymentCardsRepository(this._dio);
  final Dio _dio;

  Future<List<PaymentCard>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/payment-cards');
      final raw = (res.data!['cards'] as List?) ?? const [];
      return raw
          .map((e) => PaymentCard.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<PaymentCard> add({
    required String number,
    required int expMonth,
    required int expYear,
    required String cvv,
    String? holderName,
    bool isDefault = false,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/payment-cards',
        data: {
          'number': number,
          'exp_month': expMonth,
          'exp_year': expYear,
          'cvv': cvv,
          if (holderName != null && holderName.isNotEmpty)
            'holder_name': holderName,
          'is_default': isDefault,
        },
      );
      return PaymentCard.fromJson(res.data!['card'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> setDefault(int id) async {
    try {
      await _dio.post<void>('/payment-cards/$id/default');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> destroy(int id) async {
    try {
      await _dio.delete('/payment-cards/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final paymentCardsRepositoryProvider = Provider<PaymentCardsRepository>((ref) {
  return PaymentCardsRepository(ref.watch(apiClientProvider));
});

final paymentCardsListProvider =
    FutureProvider.autoDispose<List<PaymentCard>>((ref) async {
  return ref.watch(paymentCardsRepositoryProvider).list();
});
