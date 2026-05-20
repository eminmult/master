import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_mobile/core/api/api_client.dart';
import 'package:master_mobile/core/api/api_exception.dart';
import 'package:master_mobile/features/orders/data/models/order.dart';
import 'package:master_mobile/features/orders/data/models/public_order.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(apiClientProvider));
});

class OrdersRepository {
  OrdersRepository(this._dio);
  final Dio _dio;

  Future<List<Order>> myOrders() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/orders/my');
      final list = (res.data!['orders'] as List?) ?? [];
      return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<({List<PublicOrderItem> items, bool hasMore})> publicFeed({int page = 1}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/orders/public', queryParameters: {'page': page});
      final items = ((res.data!['orders'] as List?) ?? [])
          .map((e) => PublicOrderItem.fromJson(e as Map<String, dynamic>)).toList();
      final hasMore = (res.data!['pagination'] as Map?)?['has_more'] == true;
      return (items: items, hasMore: hasMore);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Public detail projection — visible to anyone (no auth required). Hides
  /// PII like full address / phone / coords.
  Future<PublicOrderItem> publicShow(int id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/orders/public/$id');
      return PublicOrderItem.fromJson(res.data!['order'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Same payload as [publicShow] but returns the raw map so callers can read
  /// fields not modeled on [PublicOrderItem] (e.g. `my_application_id` for
  /// authenticated masters who already applied).
  Future<Map<String, dynamic>> publicShowRaw(int id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/orders/public/$id');
      return (res.data!['order'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Order>> available() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/orders/available');
      final list = (res.data!['orders'] as List?) ?? [];
      return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Order> show(int id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/orders/$id');
      return Order.fromJson(res.data!['order'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Order> create(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/orders', data: data);
      return Order.fromJson(res.data!['order'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> updateStatus(int orderId, String status) async {
    try {
      await _dio.post<void>('/orders/$orderId/status', data: {'status': status});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Master accepts an order offered to them. Used by /master/orders.
  Future<void> accept(int orderId) async {
    try {
      await _dio.post<void>('/orders/$orderId/accept');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Live GPS update — master pings their current coordinates while heading
  /// to the client. Backend stores them on `master_profile.current_lat/lng`,
  /// which the order `show` payload pulls in for the live-tracking map.
  Future<void> updateMyLocation(double lat, double lng) async {
    try {
      await _dio.post<void>('/master/location', data: {'lat': lat, 'lng': lng});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> decline(int orderId, {String? reason}) async {
    try {
      await _dio.post<void>('/orders/$orderId/decline',
          data: {if (reason != null) 'reason': reason});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Master in `discussion` proposes ONLY an arrival time. Price of the work
  /// itself is negotiated freely in the chat — the only platform-mediated
  /// money is the fixed callout fee that the client pays to confirm.
  /// On the client side, confirmation now goes through `payCallout` (POST
  /// /orders/{id}/pay-callout) — see CalloutFeeRepository.
  Future<void> confirm(int orderId, {required DateTime agreedDate}) async {
    try {
      await _dio.post<void>(
        '/orders/$orderId/confirm',
        data: {'agreed_date': agreedDate.toIso8601String()},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Client rejects the master's proposal — bumps the order back to
  /// `discussion` so they can keep negotiating in the chat.
  Future<void> rejectProposal(int orderId) async {
    try {
      await _dio.post<void>('/orders/$orderId/reject-proposal');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Order-level chat — for the assigned master/client pair, available
  /// while status is in {discussion, pending_client, confirmed, accepted,
  /// on_the_way, arrived, in_progress}. Distinct from the application-
  /// level chat (`/order-applications/{id}/messages`) used during the
  /// public-pool bidding phase.
  Future<List<Map<String, dynamic>>> messages(int orderId, {int? before, int? since}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/orders/$orderId/messages',
        queryParameters: {
          if (before != null) 'before': before,
          if (since != null && since > 0) 'since': since,
        },
      );
      final list = (res.data!['messages'] as List?) ?? [];
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// `text` and/or `photoBase64` — backend accepts either or both. A photo
  /// without text becomes an image-only message; with text the text reads as
  /// a caption beneath the image.
  Future<Map<String, dynamic>> sendMessage(int orderId, {String? text, String? photoBase64}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/orders/$orderId/messages',
        data: {
          if (text != null && text.isNotEmpty) 'text': text,
          if (photoBase64 != null && photoBase64.isNotEmpty) 'photo': photoBase64,
        },
      );
      return (res.data!['message'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> cancel(int orderId, {String? reason}) async {
    try {
      await _dio.post<void>('/orders/$orderId/cancel', data: {if (reason != null) 'reason': reason});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> openDispute(int orderId, {required String reason, String? description}) async {
    try {
      await _dio.post<void>('/orders/$orderId/dispute', data: {
        'reason': reason,
        if (description != null) 'description': description,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> review(int orderId, {
    required int rating,
    String? text,
    List<String> tags = const [],
    List<String> photosBase64 = const [],
  }) async {
    try {
      await _dio.post<void>('/orders/$orderId/review', data: {
        'rating': rating,
        if (text != null && text.isNotEmpty) 'text': text,
        if (tags.isNotEmpty) 'tags': tags,
        if (photosBase64.isNotEmpty) 'photos': photosBase64,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
