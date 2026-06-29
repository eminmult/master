import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/features/categories/models/category_model.dart';

class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.category, required this.onTap});

  final CategoryModel category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Theme.of(context).dividerColor),
          color: Theme.of(context).cardTheme.color,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Icon(url: category.iconUrl),
            const Spacer(),
            Text(
              category.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              '${category.mastersCount} мастеров',
              style: TextStyle(
                fontSize: 11.sp,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Icon extends StatelessWidget {
  const _Icon({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        width: 40.r,
        height: 40.r,
        decoration: BoxDecoration(
          color: AppColors.brandPrimary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(Icons.category_rounded,
            size: 22.r, color: AppColors.brandPrimary),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: CachedNetworkImage(
        imageUrl: url!,
        width: 40.r,
        height: 40.r,
        fit: BoxFit.cover,
      ),
    );
  }
}
