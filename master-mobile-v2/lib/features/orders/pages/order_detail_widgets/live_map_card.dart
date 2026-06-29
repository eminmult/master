import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/core/i18n/l10n_ext.dart';
import 'package:itez_mobile/core/utils/json_parse.dart';
import 'package:itez_mobile/features/orders/live_tracking/live_tracking_bloc.dart';
import 'package:itez_mobile/features/orders/models/order_model.dart';
import 'package:itez_mobile/features/orders/models/order_status.dart';
import 'package:latlong2/latlong.dart';

/// Карта с двумя маркерами: адрес заказа (destination) + текущая позиция
/// мастера (если LiveTrackingBloc подписан и приходят координаты, либо
/// статически из master_profile.current_lat/current_lng).
class LiveMapCard extends StatelessWidget {
  const LiveMapCard({super.key, required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocBuilder<LiveTrackingBloc, LiveTrackingState>(
      builder: (context, tracking) {
        final dest = _destination(order);
        final master = _masterPos(order, tracking);

        if (dest == null && master == null) {
          return const SizedBox.shrink();
        }

        final center = master ?? dest!;
        final markers = <Marker>[
          if (dest != null)
            Marker(
              point: dest,
              width: 36,
              height: 36,
              alignment: Alignment.topCenter,
              child: const Icon(
                Icons.location_on_rounded,
                color: AppColors.accent,
                size: 30,
                shadows: [
                  Shadow(
                    color: Colors.black87,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          if (master != null)
            Marker(
              point: master,
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x6622C55E),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
        ];

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: master != null && dest != null
                    ? _zoomForBounds(master, dest)
                    : 14,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'az.gasimov.itez',
                  maxZoom: 18,
                ),
                if (master != null && dest != null)
                  PolylineLayer(polylines: [
                    Polyline(
                      points: [master, dest],
                      color: AppColors.accent.withOpacity(0.8),
                      strokeWidth: 3,
                      pattern: StrokePattern.dashed(
                          segments: const [10, 6]),
                    ),
                  ]),
                MarkerLayer(markers: markers),
              ],
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      order.status == OrderStatus.arrived
                          ? l.order_live_map_arrived
                          : l.order_live_map_on_the_way,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  LatLng? _destination(OrderModel o) {
    if (o.lat != null && o.lng != null) {
      return LatLng(o.lat!, o.lng!);
    }
    return null;
  }

  LatLng? _masterPos(OrderModel o, LiveTrackingState live) {
    // 1. Из live-tracking (свежее, чем JSON).
    if (live.lat != null && live.lng != null) {
      return LatLng(live.lat!, live.lng!);
    }
    // 2. Из master_profile (последний снимок при загрузке заказа).
    final m = o.raw['master'];
    if (m is Map) {
      final mp = m['master_profile'];
      if (mp is Map) {
        final lat = parseDoubleOrNull(mp['current_lat']);
        final lng = parseDoubleOrNull(mp['current_lng']);
        if (lat != null && lng != null) return LatLng(lat, lng);
      }
    }
    return null;
  }

  double _zoomForBounds(LatLng a, LatLng b) {
    final dLat = (a.latitude - b.latitude).abs();
    final dLng = (a.longitude - b.longitude).abs();
    final span = dLat > dLng ? dLat : dLng;
    if (span < 0.005) return 16;
    if (span < 0.02) return 14;
    if (span < 0.05) return 13;
    if (span < 0.1) return 12;
    if (span < 0.3) return 11;
    return 10;
  }
}
