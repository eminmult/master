import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:itez_mobile/core/api_client/urls.dart';
import 'package:itez_mobile/core/services/local_storage.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

/// Тонкая обёртка над Pusher (он же говорит с Laravel Reverb по тому же
/// протоколу). Один экземпляр на приложение, подписки — методами.
///
/// Каналы:
///  - `private-user.{id}` — личные события: новый заказ / сообщение / звонок
///  - `private-order.{id}` — чат + статусы заказа
///  - `private-call.{id}`  — WebRTC сигналы (offer/answer/ice)
class RealtimeService {
  final _pusher = PusherChannelsFlutter.getInstance();

  bool _started = false;
  final _events = StreamController<RealtimeEvent>.broadcast();

  Stream<RealtimeEvent> get events => _events.stream;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    if (Urls.reverbKey.isEmpty) {
      log('RealtimeService: REVERB_KEY пуст — пропускаем подключение');
      return;
    }
    // pusher_channels_flutter 2.4 не поддерживает кастомные wsHost/wsPort
    // напрямую — кластер выбирает Pusher-инфру. Для Laravel Reverb за
    // тем же доменом (itez.app/app/) это работает через `authEndpoint`
    // + cluster=mt1 как safe default. Если REVERB_KEY пуст — пропускаем
    // подключение (см. ранний return выше).
    await _pusher.init(
      apiKey: Urls.reverbKey,
      cluster: 'mt1',
      useTLS: true,
      authEndpoint: Urls.broadcastingAuth,
      onAuthorizer: (channelName, socketId, options) async {
        final token = await LocalStorage.getAuthToken();
        return {
          'headers': {
            if (token != null) 'Authorization': 'Bearer $token',
          },
          'body': {
            'socket_id': socketId,
            'channel_name': channelName,
          },
        };
      },
      onEvent: _onEvent,
      onError: (msg, code, ex) => log('Reverb error: $msg ($code)'),
      onConnectionStateChange: (current, previous) =>
          log('Reverb state: $previous → $current'),
    );
    await _pusher.connect();
  }

  Future<void> subscribeUser(int userId) =>
      _pusher.subscribe(channelName: 'private-user.$userId');

  Future<void> subscribeOrder(int orderId) =>
      _pusher.subscribe(channelName: 'private-order.$orderId');

  Future<void> subscribeCall(int callId) =>
      _pusher.subscribe(channelName: 'private-call.$callId');

  Future<void> unsubscribe(String channelName) =>
      _pusher.unsubscribe(channelName: channelName);

  void _onEvent(PusherEvent event) {
    // Pusher отдаёт data как строку — пытаемся декодировать в JSON.
    Map<String, dynamic> data = const {};
    final raw = event.data;
    if (raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) data = decoded;
      } catch (_) {/* not JSON */}
    }
    _events.add(RealtimeEvent(
      channel: event.channelName,
      name: event.eventName,
      data: data,
    ));
  }

  Future<void> stop() async {
    if (!_started) return;
    try {
      await _pusher.disconnect();
    } catch (_) {/* ignore */}
    _started = false;
  }

  Future<void> dispose() async {
    await stop();
    await _events.close();
  }
}

class RealtimeEvent {
  const RealtimeEvent({
    required this.channel,
    required this.name,
    required this.data,
  });
  final String channel;
  final String name;
  final Map<String, dynamic> data;
}
