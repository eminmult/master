import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itez_mobile/core/realtime/realtime_service.dart';

/// Подписка на realtime-канал `private-order.{id}` для live-tracking мастера.
/// Когда мастер шлёт `master.location.updated`, бэкенд бродкастит событие
/// в этот канал. UI получает координаты и перерисовывает маркер.
///
/// Если REVERB_KEY пуст или подключение упало — состояние остаётся
/// `LiveTrackingState.idle`, UI отрисует только статичный адрес.
class LiveTrackingBloc extends Bloc<LiveTrackingEvent, LiveTrackingState> {
  LiveTrackingBloc({required RealtimeService realtime})
      : _realtime = realtime,
        super(const LiveTrackingState.idle()) {
    on<LiveTrackingStarted>(_onStart);
    on<LiveTrackingStopped>(_onStop);
    on<LiveTrackingUpdated>(_onUpdate);
  }

  final RealtimeService _realtime;
  StreamSubscription<RealtimeEvent>? _sub;
  int? _orderId;

  Future<void> _onStart(
    LiveTrackingStarted event,
    Emitter<LiveTrackingState> emit,
  ) async {
    if (_orderId == event.orderId) return;
    _orderId = event.orderId;
    try {
      await _realtime.subscribeOrder(event.orderId);
      _sub?.cancel();
      _sub = _realtime.events
          .where((e) =>
              e.channel == 'private-order.${event.orderId}' &&
              e.name.contains('location'))
          .listen((e) {
        final lat = (e.data['lat'] as num?)?.toDouble();
        final lng = (e.data['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) return;
        add(LiveTrackingUpdated(lat: lat, lng: lng));
      });
    } catch (e) {
      log('LiveTracking start failed: $e');
    }
  }

  Future<void> _onStop(
    LiveTrackingStopped event,
    Emitter<LiveTrackingState> emit,
  ) async {
    final id = _orderId;
    _orderId = null;
    await _sub?.cancel();
    _sub = null;
    if (id != null) {
      try {
        await _realtime.unsubscribe('private-order.$id');
      } catch (_) {/* ignore */}
    }
    emit(const LiveTrackingState.idle());
  }

  Future<void> _onUpdate(
    LiveTrackingUpdated event,
    Emitter<LiveTrackingState> emit,
  ) async {
    emit(LiveTrackingState.tracking(
      lat: event.lat,
      lng: event.lng,
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    if (_orderId != null) {
      try {
        await _realtime.unsubscribe('private-order.$_orderId');
      } catch (_) {/* ignore */}
    }
    return super.close();
  }
}

sealed class LiveTrackingEvent {
  const LiveTrackingEvent();
}

class LiveTrackingStarted extends LiveTrackingEvent {
  const LiveTrackingStarted(this.orderId);
  final int orderId;
}

class LiveTrackingStopped extends LiveTrackingEvent {
  const LiveTrackingStopped();
}

class LiveTrackingUpdated extends LiveTrackingEvent {
  const LiveTrackingUpdated({required this.lat, required this.lng});
  final double lat;
  final double lng;
}

class LiveTrackingState {
  const LiveTrackingState.idle()
      : lat = null,
        lng = null,
        updatedAt = null;
  const LiveTrackingState.tracking({
    required double this.lat,
    required double this.lng,
    required DateTime this.updatedAt,
  });
  final double? lat;
  final double? lng;
  final DateTime? updatedAt;

  bool get hasFix => lat != null && lng != null;
}
