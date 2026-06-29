import 'package:itez_mobile/core/api_client/api_client.dart';
import 'package:itez_mobile/core/api_client/urls.dart';
import 'package:itez_mobile/features/calls/models/call_model.dart';

class CallRepository {
  CallRepository(this._client);
  final ApiClient _client;

  Future<List<CallModel>> history() async {
    final json = await _client.getJson(Urls.calls, requireAuth: true);
    final raw = json['calls'] ?? json['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(CallModel.fromJson)
        .toList();
  }

  Future<CallModel> initiate({
    required int calleeId,
    int? orderId,
  }) async {
    final json = await _client.postJson(
      Urls.calls,
      body: {
        'callee_id': calleeId,
        if (orderId != null) 'order_id': orderId,
      },
      requireAuth: true,
    );
    return CallModel.fromJson(json['call'] as Map<String, dynamic>);
  }

  Future<CallModel> show(int id) async {
    final json = await _client.getJson(Urls.call(id), requireAuth: true);
    return CallModel.fromJson(json['call'] as Map<String, dynamic>);
  }

  Future<void> accept(int id) =>
      _client.postJson(Urls.callAccept(id), requireAuth: true);

  Future<void> reject(int id) =>
      _client.postJson(Urls.callReject(id), requireAuth: true);

  Future<void> end(int id) =>
      _client.postJson(Urls.callEnd(id), requireAuth: true);

  Future<void> signal(int id, CallSignal signal) =>
      _client.postJson(
        Urls.callSignal(id),
        body: signal.toJson(),
        requireAuth: true,
      );
}
