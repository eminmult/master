import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/features/orders/models/order_status.dart';

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _color(OrderStatus s) {
    if (s.isCanceled || s == OrderStatus.disputed) return AppColors.danger;
    if (s.isFinished) return AppColors.success;
    if (s == OrderStatus.pendingPayment) return AppColors.warning;
    if (s == OrderStatus.unknown) return AppColors.textMutedLight;
    return AppColors.brandPrimary;
  }
}
