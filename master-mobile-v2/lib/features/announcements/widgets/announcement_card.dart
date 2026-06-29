import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/features/orders/models/order_model.dart';
import 'package:itez_mobile/features/orders/models/order_status.dart';

/// Карточка объявления (публичного заказа) для ленты Announcements.
/// Отличается от OrderCard: всегда `searching_master`, нет приватных полей
/// (адрес сокращён до района, телефона нет, имя клиента + аватар).
class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  final OrderModel order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(AppSpacing.md.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.cardLarge),
            border: Border.all(color: AppColors.border2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (order.urgency == OrderUrgency.urgent) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flash_on_rounded,
                              size: 11.r, color: AppColors.white),
                          SizedBox(width: 2.w),
                          Text(
                            'СРОЧНО',
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                  ],
                  Expanded(
                    child: Text(
                      order.categoryName ?? 'Заказ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text3,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  if (order.createdAt != null)
                    Text(
                      _ago(order.createdAt!),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text5,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8.h),
              if (order.description != null && order.description!.isNotEmpty)
                Text(
                  order.description!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                    height: 1.4,
                    letterSpacing: -0.1,
                  ),
                ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  if (order.fullAddress != null) ...[
                    Icon(Icons.place_outlined,
                        size: 14.r, color: AppColors.text4),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        order.fullAddress!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text4,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (order.estimatedBudget != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '${order.estimatedBudget!.toStringAsFixed(0)} ₼',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ago(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return 'сейчас';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин';
    if (diff.inHours < 24) return '${diff.inHours} ч';
    if (diff.inDays < 7) return '${diff.inDays} д';
    return '${ts.day}.${ts.month.toString().padLeft(2, '0')}';
  }
}
