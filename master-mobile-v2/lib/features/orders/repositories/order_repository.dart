import 'package:itez_mobile/core/api_client/api_client.dart';
import 'package:itez_mobile/core/api_client/urls.dart';
import 'package:itez_mobile/features/orders/models/create_order_draft.dart';
import 'package:itez_mobile/features/orders/models/order_model.dart';

class OrderRepository {
  OrderRepository(this._client);
  final ApiClient _client;

  Future<List<OrderModel>> my() async {
    final json = await _client.getJson(Urls.ordersMy, requireAuth: true);
    return _list(json['orders']);
  }

  Future<List<OrderModel>> availableForMaster() async {
    final json = await _client.getJson(Urls.ordersAvailable, requireAuth: true);
    return _list(json['orders']);
  }

  /// Публичный feed — не требует auth, но если есть токен, бэк добавит
  /// `my_application_id` для мастера.
  Future<List<OrderModel>> publicFeed({
    int? categoryId,
    String sort = 'recent',
    int page = 1,
    int perPage = 20,
  }) async {
    final json = await _client.getJson(
      Urls.ordersPublic,
      queryParams: {
        if (categoryId != null) 'category_id': categoryId,
        'sort': sort,
        'page': page,
        'per_page': perPage,
      },
    );
    final raw = json['orders'] ?? json['data'];
    return _list(raw);
  }

  Future<OrderModel> show(int id) async {
    final json = await _client.getJson(Urls.order(id), requireAuth: true);
    final raw = json['order'];
    if (raw is! Map<String, dynamic>) {
      throw StateError('GET /orders/$id returned no `order`');
    }
    return OrderModel.fromJson(raw);
  }

  Future<OrderModel> publicShow(int id) async {
    final json = await _client.getJson(Urls.orderPublic(id));
    final raw = json['order'];
    if (raw is! Map<String, dynamic>) {
      throw StateError('GET /orders/public/$id returned no `order`');
    }
    return OrderModel.fromJson(raw);
  }

  Future<OrderModel> create(CreateOrderDraft draft) async {
    final json = await _client.postJson(
      Urls.orders,
      body: draft.toBody(),
      requireAuth: true,
    );
    final raw = json['order'];
    if (raw is! Map<String, dynamic>) {
      throw StateError('POST /orders returned no `order`');
    }
    return OrderModel.fromJson(raw);
  }

  Future<void> cancel(int id, {String? reason}) async {
    await _client.postJson(
      Urls.orderCancel(id),
      body: {if (reason != null && reason.isNotEmpty) 'reason': reason},
      requireAuth: true,
    );
  }

  Future<void> confirm(int id) async {
    await _client.postJson(Urls.orderConfirm(id), requireAuth: true);
  }

  Future<void> rejectProposal(int id) async {
    await _client.postJson(Urls.orderRejectProposal(id), requireAuth: true);
  }

  /// Мастер принимает (direct request).
  Future<void> accept(int id) async {
    await _client.postJson(Urls.orderAccept(id), requireAuth: true);
  }

  Future<void> decline(int id) async {
    await _client.postJson(Urls.orderDecline(id), requireAuth: true);
  }

  Future<void> updateStatus(int id, String status) async {
    await _client.postJson(
      Urls.orderStatus(id),
      body: {'status': status},
      requireAuth: true,
    );
  }

  Future<void> apply(int id, {String? message, double? proposedPrice}) async {
    await _client.postJson(
      Urls.orderApply(id),
      body: {
        if (message != null && message.isNotEmpty) 'message': message,
        if (proposedPrice != null) 'proposed_price': proposedPrice,
      },
      requireAuth: true,
    );
  }

  /// Чат заказа. `since` — id последнего загруженного сообщения, для
  /// инкрементального обновления (poll каждые 10s в OrderDetailBloc).
  Future<List<Map<String, dynamic>>> messages(int id, {int? since}) async {
    final json = await _client.getJson(
      Urls.orderMessages(id),
      queryParams: {if (since != null) 'since': since},
      requireAuth: true,
    );
    final raw = json['messages'] ?? json['data'];
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> sendMessage(
    int id, {
    String? text,
    String? imageDataUri,
  }) async {
    final json = await _client.postJson(
      Urls.orderMessages(id),
      body: {
        if (text != null && text.isNotEmpty) 'text': text,
        if (imageDataUri != null) 'image': imageDataUri,
      },
      requireAuth: true,
    );
    final raw = json['message'] ?? json;
    return raw is Map<String, dynamic> ? raw : <String, dynamic>{};
  }

  /// Мастер шлёт координаты при on_the_way/arrived. Бэкенд бродкастит через
  /// Reverb на private-order.{id}, клиент получает обновлённые координаты.
  Future<void> updateMyLocation(double lat, double lng) async {
    await _client.postJson(
      Urls.masterLocation,
      body: {'lat': lat, 'lng': lng},
      requireAuth: true,
    );
  }

  /// Мастер отмечает работу как выполненную с финальной ценой и датой.
  Future<void> confirmWork(
    int id, {
    required double price,
    DateTime? completedAt,
    String? note,
  }) async {
    await _client.postJson(
      Urls.orderStatus(id),
      body: {
        'status': 'awaiting_completion',
        'agreed_price': price,
        if (completedAt != null)
          'completed_at': completedAt.toUtc().toIso8601String(),
        if (note != null && note.isNotEmpty) 'note': note,
      },
      requireAuth: true,
    );
  }

  Future<Map<String, dynamic>> calloutFeePreview(int id) async {
    return _client.getJson(Urls.orderCalloutFee(id), requireAuth: true);
  }

  Future<void> payCallout(int id) async {
    await _client.postJson(Urls.orderPayCallout(id), requireAuth: true);
  }

  Future<void> postReview(
    int id, {
    required int rating,
    String? comment,
  }) async {
    await _client.postJson(
      Urls.orderReview(id),
      body: {
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
      requireAuth: true,
    );
  }

  List<OrderModel> _list(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(OrderModel.fromJson)
        .toList();
  }
}
