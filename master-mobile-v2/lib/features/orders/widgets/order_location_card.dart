import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/features/orders/live_tracking/live_tracking_bloc.dart';

/// Карточка локации заказа.
///
/// — Если есть lat/lng — рендерим OpenStreetMap static-image preview.
/// — Если live tracking прислал координаты мастера — пин рядом.
/// — Кнопки «Карты», «Yandex», «Waze» открывают системные приложения
///   через `geo:` / URI scheme (link-handler провайдер).
///
/// Никаких нативных map-зависимостей: static image работает и на web,
/// и в release APK, и в любом темпе соединения.
class OrderLocationCard extends StatelessWidget {
  const OrderLocationCard({
    super.key,
    required this.address,
    required this.lat,
    required this.lng,
    required this.tracking,
    required this.onOpenMaps,
  });

  final String? address;
  final double? lat;
  final double? lng;
  final LiveTrackingState tracking;
  final ValueChanged<MapApp>? onOpenMaps;

  @override
  Widget build(BuildContext context) {
    final hasCoords = lat != null && lng != null;
    final liveLat = tracking.lat ?? lat;
    final liveLng = tracking.lng ?? lng;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(color: AppColors.border2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: hasCoords
                ? _StaticMap(lat: liveLat!, lng: liveLng!)
                : _MapPlaceholder(),
          ),
          if (tracking.hasFix)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              color: AppColors.success.withOpacity(0.15),
              child: Row(
                children: [
                  Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Мастер в пути',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.place_outlined,
                        size: 16.r, color: AppColors.text4),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        address ?? 'Адрес скрыт до принятия заказа',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text2,
                        ),
                      ),
                    ),
                  ],
                ),
                if (hasCoords && onOpenMaps != null) ...[
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Открыть'),
                          onPressed: () => onOpenMaps!(MapApp.google),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _SmallButton(
                        label: 'Yandex',
                        onTap: () => onOpenMaps!(MapApp.yandex),
                      ),
                      SizedBox(width: 8.w),
                      _SmallButton(
                        label: 'Waze',
                        onTap: () => onOpenMaps!(MapApp.waze),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum MapApp { google, yandex, waze }

class _StaticMap extends StatelessWidget {
  const _StaticMap({required this.lat, required this.lng});
  final double lat;
  final double lng;

  /// Public OpenStreetMap static image API (без ключа). Маркер по центру.
  String get _url =>
      'https://staticmap.openstreetmap.de/staticmap.php?'
      'center=$lat,$lng&zoom=15&size=600x340&maptype=mapnik'
      '&markers=$lat,$lng,red-pushpin';

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: _url,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: AppColors.surface2),
          errorWidget: (_, __, ___) => _MapPlaceholder(),
        ),
        // Затемнение поверх + центральный пин: на случай если static image
        // не отрисуется (часть провайдеров режет hotlink) — UI всё равно
        // выглядит осмысленно.
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: AppShadows.accentGlow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, color: AppColors.black, size: 14.r),
                SizedBox(width: 4.w),
                Text(
                  'Здесь',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface2,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined, color: AppColors.text5, size: 32.r),
          SizedBox(height: 6.h),
          Text(
            'Координаты появятся после принятия',
            style: TextStyle(
              color: AppColors.text5,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface2,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.border2),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}
