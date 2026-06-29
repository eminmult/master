import 'dart:async';
import 'dart:developer';

import 'package:geolocator/geolocator.dart';
import 'package:itez_mobile/features/orders/repositories/order_repository.dart';

/// Мастер-side GPS uplink. Активируется, пока заказ в "live-map" статусе
/// (on_the_way / arrived / in_progress / awaiting_completion) и
/// текущий пользователь = master заказа.
///
/// API минимальная — `start`/`stop`. Один singleton на DI, чтобы переключение
/// между страницами не плодило дубликаты подписок.
class GpsPusher {
  GpsPusher({required OrderRepository orders}) : _orders = orders;
  final OrderRepository _orders;

  StreamSubscription<Position>? _sub;
  Timer? _heartbeat;
  int? _activeOrderId;

  bool get isActive => _activeOrderId != null;

  Future<void> start(int orderId) async {
    if (_activeOrderId == orderId) return;
    await stop();
    _activeOrderId = orderId;
    try {
      final servicesOk = await Geolocator.isLocationServiceEnabled();
      if (!servicesOk) {
        _activeOrderId = null;
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _activeOrderId = null;
        return;
      }

      // Первая позиция — сразу, чтобы маркер не залипал в "—".
      try {
        final p = await Geolocator.getCurrentPosition();
        await _push(p.latitude, p.longitude);
      } catch (_) {/* keep streaming */}

      _sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 30,
        ),
      ).listen(
        (p) => _push(p.latitude, p.longitude),
        onError: (Object e) => log('GpsPusher stream error: $e'),
      );

      // Heartbeat: даже если девайс не двигается, шлём раз в 30 сек, чтобы
      // маркер на клиенте не считался stale.
      _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) async {
        try {
          final p = await Geolocator.getCurrentPosition();
          await _push(p.latitude, p.longitude);
        } catch (_) {/* ignore */}
      });
    } catch (e) {
      log('GpsPusher start failed: $e');
      _activeOrderId = null;
    }
  }

  Future<void> stop() async {
    _activeOrderId = null;
    await _sub?.cancel();
    _sub = null;
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  Future<void> _push(double lat, double lng) async {
    try {
      await _orders.updateMyLocation(lat, lng);
    } catch (_) {/* network may flap, next tick retries */}
  }
}
