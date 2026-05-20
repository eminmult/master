import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Minimal Pusher protocol client tuned for Laravel Reverb.
///
/// Does just enough to subscribe to a single authenticated private channel and
/// fan out `client-` / app-emitted events to a single listener. Avoids the
/// `pusher_channels_flutter` plugin which has no web bindings.
class ReverbClient {
  ReverbClient({
    required this.host,
    required this.port,
    required this.scheme,
    required this.appKey,
    required this.dio,
    required this.authEndpoint,
  });

  final String host;
  final int port;
  final String scheme; // 'wss' or 'ws'
  final String appKey;
  final Dio dio;
  /// Absolute or relative URL of /broadcasting/auth — used to authorize private channels.
  final String authEndpoint;

  WebSocketChannel? _channel;
  String? _socketId;
  StreamSubscription? _sub;
  Completer<void>? _connecting;

  final _events = StreamController<ReverbEvent>.broadcast();
  Stream<ReverbEvent> get events => _events.stream;

  bool get isConnected => _socketId != null;

  Future<void> connect() async {
    if (_socketId != null) return;
    if (_connecting != null) return _connecting!.future;
    _connecting = Completer<void>();

    final wsUri = Uri.parse('$scheme://$host:$port/app/$appKey?protocol=7&client=master-mobile&version=1.0.0');
    _channel = WebSocketChannel.connect(wsUri);

    _sub = _channel!.stream.listen(
      _onFrame,
      onError: (e) {
        if (kDebugMode) debugPrint('[Reverb] error: $e');
        _teardown();
      },
      onDone: () {
        if (kDebugMode) debugPrint('[Reverb] closed');
        _teardown();
      },
    );

    return _connecting!.future;
  }

  Future<void> subscribePrivate(String channel) async {
    await connect();
    if (_socketId == null) return;
    final auth = await _authorize(channel);
    _send({
      'event': 'pusher:subscribe',
      'data': {
        'channel': channel,
        'auth': auth,
      },
    });
  }

  void unsubscribe(String channel) {
    _send({
      'event': 'pusher:unsubscribe',
      'data': {'channel': channel},
    });
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    await _channel?.sink.close();
    _teardown();
  }

  // ----------------- private -----------------

  void _onFrame(dynamic raw) {
    Map<String, dynamic> frame;
    try {
      frame = (raw is String) ? jsonDecode(raw) as Map<String, dynamic> : raw as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final event = frame['event'] as String?;
    final channel = frame['channel'] as String?;
    final rawData = frame['data'];
    Map<String, dynamic>? data;
    if (rawData is String) {
      try {
        data = jsonDecode(rawData) as Map<String, dynamic>;
      } catch (_) {}
    } else if (rawData is Map) {
      data = Map<String, dynamic>.from(rawData);
    }
    if (event == 'pusher:connection_established') {
      _socketId = (data?['socket_id'] as String?) ?? '';
      _connecting?.complete();
      _connecting = null;
      return;
    }
    if (event == 'pusher:error') {
      _connecting?.completeError(Exception(data?['message'] ?? 'reverb error'));
      _connecting = null;
      return;
    }
    if (event == null) return;
    _events.add(ReverbEvent(event: event, channel: channel, data: data ?? const {}));
  }

  Future<String> _authorize(String channel) async {
    // The /broadcasting/auth endpoint returns `{"auth":"<key>:<sig>"}` after
    // verifying that the bearer token belongs to a user allowed on the channel.
    final res = await dio.post<Map<String, dynamic>>(
      authEndpoint,
      data: {
        'socket_id': _socketId,
        'channel_name': channel,
      },
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return res.data?['auth'] as String? ?? '';
  }

  void _send(Map<String, dynamic> frame) {
    _channel?.sink.add(jsonEncode(frame));
  }

  void _teardown() {
    _socketId = null;
    _channel = null;
    _sub = null;
    _connecting?.completeError(StateError('Disconnected'));
    _connecting = null;
  }
}

class ReverbEvent {
  ReverbEvent({required this.event, required this.channel, required this.data});
  final String event;
  final String? channel;
  final Map<String, dynamic> data;
}
