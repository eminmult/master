import 'package:itez_mobile/core/api_client/api_client.dart';
import 'package:itez_mobile/core/api_client/urls.dart';
import 'package:itez_mobile/features/applications/models/order_application.dart';

/// CRUD + actions для откликов мастеров.
/// Backend контракты — см. `/order-applications/*` в Laravel routes.
class ApplicationRepository {
  ApplicationRepository(this._client);
  final ApiClient _client;

  /// Все мои отклики (master view). С eager-loaded `order`.
  Future<List<OrderApplication>> mine({int page = 1}) async {
    final json = await _client.getJson(
      Urls.masterApplications,
      queryParams: {'page': page},
      requireAuth: true,
    );
    final raw = json['applications'] ?? json['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(OrderApplication.fromJson)
        .toList();
  }

  Future<List<OrderApplication>> forOrder(int orderId) async {
    final json = await _client.getJson(
      Urls.orderApplications(orderId),
      requireAuth: true,
    );
    final raw = json['applications'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(OrderApplication.fromJson)
        .toList();
  }

  Future<OrderApplication> show(int id) async {
    final json = await _client.getJson(Urls.application(id), requireAuth: true);
    final raw = json['application'];
    if (raw is! Map<String, dynamic>) {
      throw StateError('GET /order-applications/$id returned no application');
    }
    return OrderApplication.fromJson(raw);
  }

  Future<OrderApplication> apply(
    int orderId, {
    String? message,
    double? proposedPrice,
  }) async {
    final json = await _client.postJson(
      Urls.orderApply(orderId),
      body: {
        if (message != null && message.isNotEmpty) 'message': message,
        if (proposedPrice != null) 'proposed_price': proposedPrice,
      },
      requireAuth: true,
    );
    final raw = json['application'];
    if (raw is! Map<String, dynamic>) {
      throw StateError('POST /orders/$orderId/apply returned no application');
    }
    return OrderApplication.fromJson(raw);
  }

  Future<void> startDiscussion(int id) =>
      _client.postJson(Urls.applicationStartDiscussion(id), requireAuth: true);

  Future<void> reject(int id, {String? reason}) => _client.postJson(
        Urls.applicationReject(id),
        body: {if (reason != null && reason.isNotEmpty) 'reason': reason},
        requireAuth: true,
      );

  Future<void> withdraw(int id, {String? reason}) => _client.postJson(
        Urls.applicationWithdraw(id),
        body: {if (reason != null && reason.isNotEmpty) 'reason': reason},
        requireAuth: true,
      );

  Future<void> propose(
    int id, {
    required DateTime arrivalAt,
    double? proposedPrice,
    String? message,
  }) =>
      _client.postJson(
        Urls.applicationPropose(id),
        body: {
          'arrival_at': arrivalAt.toUtc().toIso8601String(),
          if (proposedPrice != null) 'proposed_price': proposedPrice,
          if (message != null && message.isNotEmpty) 'message': message,
        },
        requireAuth: true,
      );

  Future<void> acceptProposal(int id) =>
      _client.postJson(Urls.applicationAcceptProposal(id), requireAuth: true);

  Future<void> rejectProposal(int id) =>
      _client.postJson(Urls.applicationRejectProposal(id), requireAuth: true);
}
