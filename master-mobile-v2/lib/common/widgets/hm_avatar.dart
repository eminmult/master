import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';

/// Круглая аватарка с опциональным жёлтым ring'ом и онлайн-точкой.
/// Используется во всех карточках мастеров, в header'е профиля и т.д.
class HmAvatar extends StatelessWidget {
  const HmAvatar({
    super.key,
    required this.url,
    this.size = 40,
    this.ring = false,
    this.online = false,
    this.heroTag,
    this.fallback,
  });

  final String? url;
  final double size;
  final bool ring;
  final bool online;
  final Object? heroTag;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final r = size.r;
    Widget child = (url == null || url!.isEmpty)
        ? _placeholder(r)
        : CachedNetworkImage(
            imageUrl: url!,
            width: r,
            height: r,
            fit: BoxFit.cover,
            placeholder: (_, __) => _placeholder(r),
            errorWidget: (_, __, ___) => _placeholder(r),
          );

    child = ClipOval(child: child);

    if (ring) {
      child = Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
        child: child,
      );
    }
    if (heroTag != null) {
      child = Hero(tag: heroTag!, child: child);
    }

    if (!online) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: (size * 0.26).r,
            height: (size * 0.26).r,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.bg, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder(double r) =>
      fallback ??
      Container(
        width: r,
        height: r,
        color: AppColors.surface2,
        alignment: Alignment.center,
        child: Icon(Icons.person, color: AppColors.text5, size: r * 0.55),
      );
}
