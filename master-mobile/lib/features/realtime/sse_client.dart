import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:master_mobile/core/api/api_client.dart';
import 'package:master_mobile/core/auth/auth_controller.dart';
import 'package:master_mobile/core/auth/auth_storage.dart';
import 'package:master_mobile/core/config/app_config.dart';

/// Lightweight Server-Sent Events client tailored to the itez.app
/// realtime relay (`/sse/stream?token=<bearer>`).
///
/// The relay piped to clients over plain HTTP because Cloudflare Flexible SSL
/// downgrades WSS → HTTP on the proxied apex (mixed-content blocks the WS
/// path). SSE is just text/event-stream over HTTPS and survives the proxy
/// untouched.
///
/// The client exposes a broadcast [events] stream consumed by chat pages,
/// auto-reconnects on disconnect with exponential backoff, and binds to the
/// authenticated user (re-binds on token change).
class SseClient {
  SseClient();

  http.Client? _http;
  StreamSubscription<String>? _sub;
  Timer? _reconnect;
  bool _disposed = false;
  String? _token;
  int _backoffMs = 1000;

  final _events = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get events => _events.stream;

  /// Start (or restart) the connection with [token]. Safe to call repeatedly;
  /// the implementation closes any in-flight connection before reopening.
  Future<void> connect(String token) async {
    if (_disposed) return;
    if (_token == token && _http != null) return;
    _token = token;
    await _close();
    _open();
  }

  Future<void> disconnect() async {
    _disposed = true;
    _reconnect?.cancel();
    await _close();
  }

  Future<void> _close() async {
    try { await _sub?.cancel(); } catch (_) {}
    _sub = null;
    try { _http?.close(); } catch (_) {}
    _http = null;
  }

  Uri _streamUri() {
    final scheme = AppConfig.wsScheme == 'wss' ? 'https' : 'http';
    // Always uses the main domain. CF is fine with HTTP streaming, no need
    // for the realtime.itez.app workaround we have for WebSocket.
    final host = 'itez.app';
    return Uri.parse('$scheme://$host/sse/stream?token=${Uri.encodeComponent(_token!)}');
  }

  void _open() {
    if (_disposed || _token == null || _token!.isEmpty) return;
    _http = http.Client();
    final req = http.Request('GET', _streamUri());
    req.headers['Accept'] = 'text/event-stream';
    req.headers['Cache-Control'] = 'no-cache';

    _http!.send(req).then((resp) {
      if (_disposed) return;
      if (resp.statusCode != 200) {
        _scheduleReconnect();
        return;
      }
      _backoffMs = 1000;
      final stream = resp.stream.transform(utf8.decoder).transform(const LineSplitter());
      String? pendingData;
      _sub = stream.listen(
        (line) {
          if (line.isEmpty) {
            if (pendingData != null) {
              _emit(pendingData!);
              pendingData = null;
            }
            return;
          }
          if (line.startsWith(':')) return; // comment / heartbeat
          if (line.startsWith('data:')) {
            final chunk = line.substring(5).trimLeft();
            pendingData = (pendingData == null) ? chunk : '$pendingData\n$chunk';
          }
        },
        onError: (_) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
        cancelOnError: true,
      );
    }).catchError((e) {
      if (kDebugMode) debugPrint('[SSE] open error: $e');
      _scheduleReconnect();
    });
  }

  void _emit(String raw) {
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      _events.add(j);
    } catch (e) {
      if (kDebugMode) debugPrint('[SSE] bad payload: $raw ($e)');
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _close();
    final delay = Duration(milliseconds: _backoffMs);
    _backoffMs = (_backoffMs * 2).clamp(1000, 30000);
    _reconnect?.cancel();
    _reconnect = Timer(delay, _open);
  }
}

final sseClientProvider = Provider<SseClient>((ref) {
  final svc = SseClient();
  ref.onDispose(() => svc.disconnect());

  // Hook into auth state — connect with the live token, reconnect on rotate.
  final storage = ref.watch(authStorageProvider);
  ref.listen<AuthState>(authStateProvider, (prev, next) async {
    if (next is AuthAuthenticated) {
      final tok = await storage.readToken();
      if (tok != null) await svc.connect(tok);
    } else {
      await svc.disconnect();
    }
  }, fireImmediately: true);

  return svc;
});
