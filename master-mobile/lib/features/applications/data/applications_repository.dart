import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_mobile/core/api/api_client.dart';
import 'package:master_mobile/core/api/api_exception.dart';
import 'package:master_mobile/features/applications/data/models/application.dart';
import 'package:master_mobile/features/chat/data/models/chat_message.dart';

final applicationsRepositoryProvider = Provider<ApplicationsRepository>((ref) {
  return ApplicationsRepository(ref.watch(apiClientProvider));
});

/// All endpoints under /order-applications/* and /orders/{order}/applications.
/// Mirrors backend logic 1:1 — see /root/master-site/MOBILE_API.md §5.6-5.13.
class ApplicationsRepository {
  ApplicationsRepository(this._dio);
  final Dio _dio;

  /// Single application with parent order + counterparty preloaded. Used
  /// by the application chat page so it can show order context without a
  /// second round-trip to /orders/:id (which 403s for the master before
  /// the client picks them).
  Future<Map<String, dynamic>> show(int applicationId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
          '/order-applications/$applicationId');
      return (res.data!['application'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// List all applications for an order (client view).
  Future<List<OrderApplication>> forOrder(int orderId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/orders/$orderId/applications');
      final list = (res.data!['applications'] as List?) ?? [];
      return list.map((e) => OrderApplication.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Master applies to public order with optional proposed price.
  Future<OrderApplication> apply(int orderId, {String? message, double? proposedPrice}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/orders/$orderId/apply', data: {
        if (message != null) 'message': message,
        if (proposedPrice != null) 'proposed_price': proposedPrice,
      });
      return OrderApplication.fromJson(res.data!['application'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> startDiscussion(int applicationId) async {
    try {
      await _dio.post<void>('/order-applications/$applicationId/start-discussion');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> reject(int applicationId, {String? reason}) async {
    try {
      await _dio.post<void>('/order-applications/$applicationId/reject', data: {if (reason != null) 'reason': reason});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> withdraw(int applicationId, {String? reason}) async {
    try {
      await _dio.post<void>('/order-applications/$applicationId/withdraw', data: {if (reason != null) 'reason': reason});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Master proposes the arrival time. Price of the work itself is negotiated
  /// in chat — the only platform-mediated money is the fixed callout fee that
  /// the client pays to confirm.
  Future<void> propose(int applicationId, {required DateTime date}) async {
    try {
      await _dio.post<void>('/order-applications/$applicationId/propose', data: {
        'proposed_date': date.toIso8601String(),
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Client accepts a proposal — closes the announcement, auto-rejects others.
  Future<void> acceptProposal(int applicationId) async {
    try {
      await _dio.post<void>('/order-applications/$applicationId/accept-proposal');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> rejectProposal(int applicationId) async {
    try {
      await _dio.post<void>('/order-applications/$applicationId/reject-proposal');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Master's own applications (paginated 20/page).
  Future<({List<OrderApplication> items, bool hasMore})> mine({int page = 1}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/master/applications', queryParameters: {'page': page});
      final list = ((res.data!['applications'] as List?) ?? [])
          .map((e) => OrderApplication.fromJson(e as Map<String, dynamic>)).toList();
      final hasMore = (res.data!['pagination'] as Map?)?['has_more'] == true;
      return (items: list, hasMore: hasMore);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<ChatMessage>> messages(int applicationId, {int? before, int? since}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/order-applications/$applicationId/messages',
        queryParameters: {
          if (before != null) 'before': before,
          if (since != null && since > 0) 'since': since,
        },
      );
      final list = (res.data!['messages'] as List?) ?? [];
      return list.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ChatMessage> sendMessage(int applicationId, String text) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/order-applications/$applicationId/messages',
        data: {'text': text},
      );
      return ChatMessage.fromJson(res.data!['message'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
