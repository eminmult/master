import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/features/masters/models/master_list_item.dart';

/// Карточка мастера в стиле оригинального master-mobile:
/// квадратное фото 1:1, поверх — rating chip (top-right), verified-badge,
/// online-dot. Под фото — имя, категория, кол-во отзывов.
///
/// Используется в Home (recommended grid) и в MastersListPage.
class MasterCard extends StatelessWidget {
  const MasterCard({super.key, required this.master, required this.onTap});

  final MasterListItem master;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cat = master.categories.isNotEmpty
        ? master.categories.first.name
        : null;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: AppColors.border2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _Photo(url: master.avatarUrl),
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: _RatingChip(
                        rating: master.ratingAvg,
                        count: master.ratingCount,
                      ),
                    ),
                    if (master.isActiveNow)
                      Positioned(
                        top: 8.h,
                        left: 8.w,
                        child: _StatusDot(
                          color: AppColors.success,
                          label: 'онлайн',
                        ),
                      ),
                    if (master.isVerified)
                      Positioned(
                        bottom: 8.h,
                        left: 8.w,
                        child: const _VerifiedBadge(),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      master.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      cat == null
                          ? '${master.experienceYears} лет опыта'
                          : '$cat · ${master.experienceYears} л.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text4,
                      ),
                    ),
                    if (master.completedOrders > 0) ...[
                      SizedBox(height: 6.h),
                      Text(
                        '${master.completedOrders} заказ.',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text5,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        color: AppColors.surface2,
        alignment: Alignment.center,
        child: Icon(Icons.person, color: AppColors.text5, size: 64.r),
      );
    }
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: AppColors.surface2),
      errorWidget: (_, __, ___) =>
          Container(color: AppColors.surface2),
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.rating, required this.count});
  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xCC000000),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: AppColors.accent, size: 12.r),
          SizedBox(width: 3.w),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          if (count > 0) ...[
            SizedBox(width: 4.w),
            Text(
              '($count)',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.text4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xCC000000),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.r,
            height: 6.r,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: AppColors.black, size: 10.r),
          SizedBox(width: 3.w),
          Text(
            'verified',
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
