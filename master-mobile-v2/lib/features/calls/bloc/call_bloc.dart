import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:itez_mobile/core/exceptions/app_exception.dart';
import 'package:itez_mobile/features/calls/models/call_model.dart';
import 'package:itez_mobile/features/calls/repositories/call_repository.dart';

part 'call_event.dart';
part 'call_state.dart';

/// Sole responsibility: lifecycle одного WebRTC-звонка с REST-сигналингом
/// через `/calls/{id}/signal`. Realtime-приём сигналов (offer/answer/ice)
/// делает [RealtimeService] поверх Reverb-канала и пушит сюда события.
///
/// Не управляет UI / разрешениями / маршрутом — это всё снаружи.
class CallBloc extends Bloc<CallEvent, CallState> {
  CallBloc(this._repo) : super(const CallState()) {
    on<CallOutgoingRequested>(_onOutgoing);
    on<CallIncomingArrived>(_onIncoming);
    on<CallAccepted>(_onAccept);
    on<CallRejected>(_onReject);
    on<CallHungUp>(_onHangUp);
    on<CallSignalReceived>(_onSignal);
    on<CallStatusChanged>(_onStatusChanged);
  }

  final CallRepository _repo;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  static const _iceConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ],
  };

  Future<void> _initPeer(int callId, {required bool isCaller}) async {
    _pc = await createPeerConnection(_iceConfig);
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });
    for (final track in _localStream!.getTracks()) {
      await _pc!.addTrack(track, _localStream!);
    }
    _pc!.onIceCandidate = (candidate) async {
      try {
        await _repo.signal(
          callId,
          CallSignal(type: 'ice', payload: candidate.toMap()),
        );
      } catch (e) {
        log('signal ice failed: $e');
      }
    };
    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) _remoteStream = event.streams.first;
    };
    if (isCaller) {
      final offer = await _pc!.createOffer({});
      await _pc!.setLocalDescription(offer);
      await _repo.signal(
        callId,
        CallSignal(type: 'offer', payload: offer.toMap()),
      );
    }
  }

  Future<void> _onOutgoing(
    CallOutgoingRequested event,
    Emitter<CallState> emit,
  ) async {
    emit(state.copyWith(phase: CallPhase.outgoing, clearError: true));
    try {
      final call = await _repo.initiate(
        calleeId: event.calleeId,
        orderId: event.orderId,
      );
      emit(state.copyWith(call: call));
      await _initPeer(call.id, isCaller: true);
    } on AppException catch (e) {
      emit(state.copyWith(
        phase: CallPhase.failed,
        error: e.message ?? 'Не удалось начать звонок',
      ));
    }
  }

  Future<void> _onIncoming(
    CallIncomingArrived event,
    Emitter<CallState> emit,
  ) async {
    emit(state.copyWith(phase: CallPhase.incoming, call: event.call));
  }

  Future<void> _onAccept(CallAccepted event, Emitter<CallState> emit) async {
    final call = state.call;
    if (call == null) return;
    emit(state.copyWith(phase: CallPhase.connecting));
    try {
      await _repo.accept(call.id);
      await _initPeer(call.id, isCaller: false);
      emit(state.copyWith(phase: CallPhase.active));
    } on AppException catch (e) {
      emit(state.copyWith(
        phase: CallPhase.failed,
        error: e.message,
      ));
    }
  }

  Future<void> _onReject(CallRejected event, Emitter<CallState> emit) async {
    final call = state.call;
    if (call != null) {
      try {
        await _repo.reject(call.id);
      } on AppException {/* tolerate */}
    }
    await _cleanup();
    emit(state.copyWith(phase: CallPhase.ended, clearCall: true));
  }

  Future<void> _onHangUp(CallHungUp event, Emitter<CallState> emit) async {
    final call = state.call;
    if (call != null) {
      try {
        await _repo.end(call.id);
      } on AppException {/* tolerate */}
    }
    await _cleanup();
    emit(state.copyWith(phase: CallPhase.ended, clearCall: true));
  }

  Future<void> _onSignal(
    CallSignalReceived event,
    Emitter<CallState> emit,
  ) async {
    final pc = _pc;
    if (pc == null) return;
    final s = event.signal;
    try {
      switch (s.type) {
        case 'offer':
          await pc.setRemoteDescription(
            RTCSessionDescription(
              s.payload['sdp']?.toString(),
              s.payload['type']?.toString(),
            ),
          );
          final answer = await pc.createAnswer({});
          await pc.setLocalDescription(answer);
          await _repo.signal(
            state.call!.id,
            CallSignal(type: 'answer', payload: answer.toMap()),
          );
          break;
        case 'answer':
          await pc.setRemoteDescription(
            RTCSessionDescription(
              s.payload['sdp']?.toString(),
              s.payload['type']?.toString(),
            ),
          );
          emit(state.copyWith(phase: CallPhase.active));
          break;
        case 'ice':
          await pc.addCandidate(RTCIceCandidate(
            s.payload['candidate']?.toString(),
            s.payload['sdpMid']?.toString(),
            (s.payload['sdpMLineIndex'] as num?)?.toInt(),
          ));
          break;
      }
    } catch (e) {
      log('signal apply failed: $e');
    }
  }

  Future<void> _onStatusChanged(
    CallStatusChanged event,
    Emitter<CallState> emit,
  ) async {
    if (event.status == CallStatus.ended ||
        event.status == CallStatus.rejected ||
        event.status == CallStatus.missed) {
      await _cleanup();
      emit(state.copyWith(phase: CallPhase.ended, clearCall: true));
    }
  }

  Future<void> _cleanup() async {
    for (final t in _localStream?.getTracks() ?? const []) {
      await t.stop();
    }
    await _localStream?.dispose();
    await _remoteStream?.dispose();
    await _pc?.close();
    _localStream = null;
    _remoteStream = null;
    _pc = null;
  }

  @override
  Future<void> close() async {
    await _cleanup();
    return super.close();
  }
}
