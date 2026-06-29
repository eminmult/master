part of 'call_bloc.dart';

enum CallPhase {
  idle,
  outgoing,
  incoming,
  connecting,
  active,
  ended,
  failed,
}

class CallState {
  const CallState({
    this.phase = CallPhase.idle,
    this.call,
    this.muted = false,
    this.speaker = false,
    this.error,
  });

  final CallPhase phase;
  final CallModel? call;
  final bool muted;
  final bool speaker;
  final String? error;

  CallState copyWith({
    CallPhase? phase,
    CallModel? call,
    bool? muted,
    bool? speaker,
    String? error,
    bool clearError = false,
    bool clearCall = false,
  }) =>
      CallState(
        phase: phase ?? this.phase,
        call: clearCall ? null : (call ?? this.call),
        muted: muted ?? this.muted,
        speaker: speaker ?? this.speaker,
        error: clearError ? null : (error ?? this.error),
      );
}
