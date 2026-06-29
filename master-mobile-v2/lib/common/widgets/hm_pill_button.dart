import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';

/// Маленькая pill-кнопка-таб для фильтров: "Все / Срочно / Установка / Ремонт".
/// В отличие от Material `ChoiceChip` не имеет лишних индикаторов и
/// рисуется в один stadium с уверенной типографикой.
class HmPillButton extends StatelessWidget {
  const HmPillButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.accent : AppColors.surface2;
    final fg = selected ? AppColors.black : AppColors.text;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14.r, color: fg),
                SizedBox(width: 6.w),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
