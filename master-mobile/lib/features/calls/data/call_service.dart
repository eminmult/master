import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:master_mobile/core/api/api_client.dart';
import 'package:master_mobile/core/auth/auth_controller.dart';
import 'package:master_mobile/core/config/app_config.dart';
import 'package:master_mobile/features/calls/data/reverb_client.dart';

/// Singleton-per-user WebRTC + Reverb signaling for in-app voice calls.
///
/// Manages exactly one peer connection at a time; cross-call interleavings are
/// rejected at the backend ([CallController]) and ignored client-side via the
/// [activeCall] state.
final callServiceProvider = Provider<CallService>((ref) {
  final dio = ref.watch(apiClientProvider);
  final svc = CallService(dio);
  ref.onDispose(svc.dispose);
  // Subscribe to user channel whenever auth state becomes Authenticated.
  ref.listen<AuthState>(authStateProvider, (prev, next) {
    if (next is AuthAuthenticated) {
      svc.bind(next.user.id);
    } else {
      svc.unbind();
    }
  }, fireImmediately: true);
  return svc;
});

enum CallPhase { idle, dialing, incoming, inCall, ended }

class CallSnapshot {
  CallSnapshot({
    required this.phase,
    this.callId,
    this.orderId,
    this.peerId,
    this.peerName,
    this.peerAvatar,
    this.error,
    this.micMuted = false,
    this.durationSec = 0,
  });

  final CallPhase phase;
  final int? callId;
  final int? orderId;
  final int? peerId;
  final String? peerName;
  final String? peerAvatar;
  final String? error;
  final bool micMuted;
  final int durationSec;

  CallSnapshot copyWith({
    CallPhase? phase,
    int? callId,
    int? orderId,
    int? peerId,
    String? peerName,
    String? peerAvatar,
    String? error,
    bool? micMuted,
    int? durationSec,
  }) =>
      CallSnapshot(
        phase: phase ?? this.phase,
        callId: callId ?? this.callId,
        orderId: orderId ?? this.orderId,
        peerId: peerId ?? this.peerId,
        peerName: peerName ?? this.peerName,
        peerAvatar: peerAvatar ?? this.peerAvatar,
        error: error,
        micMuted: micMuted ?? this.micMuted,
        durationSec: durationSec ?? this.durationSec,
      );
}

class CallService extends ChangeNotifier {
  CallService(this._dio);

  final Dio _dio;
  ReverbClient? _reverb;
  StreamSubscription? _evtSub;
  int? _userId;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final List<Map<String, dynamic>> _pendingIce = [];
  Map<String, dynamic>? _pendingRemoteSdp;
  Timer? _durationTimer;
  DateTime? _connectedAt;

  CallSnapshot _state = CallSnapshot(phase: CallPhase.idle);
  CallSnapshot get state => _state;

  /// Renderer for the remote audio stream — host UI reads this if it needs to
  /// attach to a widget. Not used directly because audio plays automatically
  /// through `RTCVideoRenderer.srcObject` is not needed for audio-only — the
  /// audio track is consumed straight from the [MediaStream].
  MediaStream? get remoteStream => _remoteStream;

  /// Public, filtered event stream for other features that want to piggy-back
  /// on the same private user channel (e.g. realtime chat). Each subscriber
  /// gets a broadcast view so multiple widgets can listen concurrently.
  Stream<ReverbEvent> get reverbEvents =>
      _reverb?.events ?? const Stream.empty();

  static const _rtcConfig = <String, dynamic>{
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  // ============= public API =============

  Future<void> bind(int userId) async {
    if (_userId == userId && _reverb?.isConnected == true) return;
    await unbind();
    _userId = userId;
    _reverb = ReverbClient(
      host: AppConfig.wsHost,
      port: AppConfig.wsPort,
      scheme: AppConfig.wsScheme,
      appKey: AppConfig.reverbAppKey,
      dio: _dio,
      // Absolute URL — bypasses Dio's `/api/v1` baseUrl so the bearer token
      // hits the actual Broadcast::routes(['prefix'=>'api']) handler.
      authEndpoint: '${AppConfig.wsScheme == 'wss' ? 'https' : 'http'}://${AppConfig.wsHost}/api/broadcasting/auth',
    );
    try {
      await _reverb!.connect();
      await _reverb!.subscribePrivate('private-user.$userId');
      _evtSub = _reverb!.events.listen(_onReverbEvent);
    } catch (e) {
      if (kDebugMode) debugPrint('[CallService] bind failed: $e');
    }
  }

  Future<void> unbind() async {
    await _evtSub?.cancel();
    _evtSub = null;
    await _reverb?.disconnect();
    _reverb = null;
    _userId = null;
  }

  /// Outgoing call.
  Future<void> startOutgoing({
    required int orderId,
    required int calleeId,
    String? calleeName,
    String? calleeAvatar,
  }) async {
    if (_state.phase != CallPhase.idle && _state.phase != CallPhase.ended) return;
    _set(_state.copyWith(
      phase: CallPhase.dialing,
      orderId: orderId,
      peerId: calleeId,
      peerName: calleeName,
      peerAvatar: calleeAvatar,
      error: null,
      durationSec: 0,
    ));
    try {
      await _ensureLocalMedia();
      await _buildPeer();
      final offer = await _pc!.createOffer({'offerToReceiveAudio': true, 'offerToReceiveVideo': false});
      await _pc!.setLocalDescription(offer);
      final res = await _dio.post(
        '/calls',
        data: {
          'order_id': orderId,
          'callee_id': calleeId,
          'sdp': {'sdp': offer.sdp, 'type': offer.type},
        },
      );
      final call = (res.data as Map<String, dynamic>)['call'] as Map<String, dynamic>;
      _set(_state.copyWith(callId: call['id'] as int));
    } catch (e) {
      _set(_state.copyWith(error: _err(e), phase: CallPhase.ended));
      await _teardown();
    }
  }

  Future<void> accept() async {
    if (_state.phase != CallPhase.incoming || _state.callId == null || _pendingRemoteSdp == null) return;
    try {
      await _ensureLocalMedia();
      await _buildPeer();
      await _pc!.setRemoteDescription(RTCSessionDescription(
        _pendingRemoteSdp!['sdp'] as String,
        _pendingRemoteSdp!['type'] as String,
      ));
      await _flushPendingIce();
      final answer = await _pc!.createAnswer({'offerToReceiveAudio': true});
      await _pc!.setLocalDescription(answer);
      await _dio.post('/calls/${_state.callId}/accept', data: {
        'sdp': {'sdp': answer.sdp, 'type': answer.type},
      });
      _startTimer();
      _set(_state.copyWith(phase: CallPhase.inCall));
    } catch (e) {
      _set(_state.copyWith(error: _err(e)));
      await end();
    }
  }

  Future<void> reject() async {
    if (_state.phase != CallPhase.incoming || _state.callId == null) return;
    try {
      await _dio.post('/calls/${_state.callId}/reject');
    } catch (_) {}
    _set(_state.copyWith(phase: CallPhase.ended));
    await _teardown();
  }

  Future<void> end() async {
    final id = _state.callId;
    if (id != null) {
      try {
        await _dio.post('/calls/$id/end');
      } catch (_) {}
    }
    _set(_state.copyWith(phase: CallPhase.ended));
    await _teardown();
  }

  void toggleMic() {
    if (_localStream == null) return;
    final muted = !_state.micMuted;
    for (final t in _localStream!.getAudioTracks()) {
      t.enabled = !muted;
    }
    _set(_state.copyWith(micMuted: muted));
  }

  void dismiss() {
    if (_state.phase == CallPhase.ended) {
      _set(CallSnapshot(phase: CallPhase.idle));
    }
  }

  // ============= internals =============

  Future<void> _onReverbEvent(ReverbEvent e) async {
    if (!e.event.startsWith('call.')) return;
    final type = e.event.substring(5); // ringing|accepted|rejected|cancelled|ended|offer|answer|ice
    final callId = e.data['call_id'] as int?;
    final payload = (e.data['payload'] as Map?)?.cast<String, dynamic>() ?? const {};

    switch (type) {
      case 'ringing':
        if (_state.phase == CallPhase.inCall || _state.phase == CallPhase.dialing) return;
        _pendingRemoteSdp = payload['sdp'] is Map ? Map<String, dynamic>.from(payload['sdp'] as Map) : null;
        _pendingIce.clear();
        final caller = payload['caller'] is Map ? Map<String, dynamic>.from(payload['caller'] as Map) : <String, dynamic>{};
        final name = '${caller['first_name'] ?? ''} ${caller['last_name'] ?? ''}'.trim();
        _set(_state.copyWith(
          phase: CallPhase.incoming,
          callId: callId,
          orderId: payload['order_id'] as int?,
          peerId: payload['caller_id'] as int?,
          peerName: name.isEmpty ? null : name,
          peerAvatar: caller['avatar_url'] as String?,
          error: null,
        ));
        break;
      case 'accepted':
        if (_state.phase != CallPhase.dialing || _pc == null) return;
        final sdp = payload['sdp'] is Map ? Map<String, dynamic>.from(payload['sdp'] as Map) : null;
        if (sdp == null) return;
        await _pc!.setRemoteDescription(RTCSessionDescription(sdp['sdp'] as String, sdp['type'] as String));
        await _flushPendingIce();
        _startTimer();
        _set(_state.copyWith(phase: CallPhase.inCall));
        break;
      case 'rejected':
      case 'cancelled':
      case 'ended':
        _set(_state.copyWith(phase: CallPhase.ended));
        await _teardown();
        break;
      case 'offer':
      case 'answer':
        if (_pc == null) return;
        await _pc!.setRemoteDescription(RTCSessionDescription(payload['sdp'] as String, payload['type'] as String));
        await _flushPendingIce();
        if (type == 'offer') {
          final ans = await _pc!.createAnswer({'offerToReceiveAudio': true});
          await _pc!.setLocalDescription(ans);
        }
        break;
      case 'ice':
        if (_pc == null || _pc!.getRemoteDescription == null) {
          _pendingIce.add(Map<String, dynamic>.from(payload));
          return;
        }
        try {
          await _pc!.addCandidate(RTCIceCandidate(
            payload['candidate'] as String?,
            payload['sdpMid'] as String?,
            payload['sdpMLineIndex'] as int?,
          ));
        } catch (_) {}
        break;
    }
  }

  Future<void> _ensureLocalMedia() async {
    _localStream ??= await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
  }

  Future<void> _buildPeer() async {
    _pc = await createPeerConnection(_rtcConfig);
    if (_localStream != null) {
      for (final t in _localStream!.getTracks()) {
        await _pc!.addTrack(t, _localStream!);
      }
    }
    _pc!.onIceCandidate = (c) async {
      final id = _state.callId;
      if (id == null) return;
      try {
        await _dio.post('/calls/$id/signal', data: {
          'type': 'ice',
          'payload': {
            'candidate': c.candidate,
            'sdpMid': c.sdpMid,
            'sdpMLineIndex': c.sdpMLineIndex,
          },
        });
      } catch (_) {}
    };
    _pc!.onTrack = (ev) {
      if (ev.streams.isNotEmpty) {
        _remoteStream = ev.streams.first;
        notifyListeners();
      }
    };
    _pc!.onConnectionState = (s) {
      if (s == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          s == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        end();
      }
    };
  }

  Future<void> _flushPendingIce() async {
    if (_pc == null || _pendingIce.isEmpty) return;
    for (final c in _pendingIce) {
      try {
        await _pc!.addCandidate(RTCIceCandidate(
          c['candidate'] as String?,
          c['sdpMid'] as String?,
          c['sdpMLineIndex'] as int?,
        ));
      } catch (_) {}
    }
    _pendingIce.clear();
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _connectedAt = DateTime.now();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_connectedAt == null) return;
      final d = DateTime.now().difference(_connectedAt!).inSeconds;
      _set(_state.copyWith(durationSec: d));
    });
  }

  Future<void> _teardown() async {
    _durationTimer?.cancel();
    _durationTimer = null;
    _connectedAt = null;
    try {
      await _pc?.close();
    } catch (_) {}
    _pc = null;
    try {
      _localStream?.getTracks().forEach((t) => t.stop());
      await _localStream?.dispose();
    } catch (_) {}
    _localStream = null;
    try {
      await _remoteStream?.dispose();
    } catch (_) {}
    _remoteStream = null;
    _pendingIce.clear();
    _pendingRemoteSdp = null;
  }

  String? _err(Object e) {
    if (e is DioException) {
      final msg = e.response?.data is Map ? (e.response!.data as Map)['message']?.toString() : null;
      return msg ?? e.message;
    }
    return e.toString();
  }

  void _set(CallSnapshot s) {
    _state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    unbind();
    _teardown();
    super.dispose();
  }
}

/// Listenable wrapper so widgets can `ref.watch(callStateProvider)`.
final callStateProvider = ChangeNotifierProvider<CallService>((ref) {
  return ref.watch(callServiceProvider);
});
