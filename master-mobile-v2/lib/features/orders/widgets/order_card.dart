import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/features/orders/models/order_model.dart';
import 'package:itez_mobile/features/orders/widgets/order_status_badge.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onTap});

  final OrderModel order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.categoryName ?? 'Заказ #${order.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  OrderStatusBadge(status: order.status),
                ],
              ),
              SizedBox(height: 6.h),
              if (order.description != null) ...[
                Text(
                  order.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                SizedBox(height: 8.h),
              ],
              Row(
                children: [
                  if (order.fullAddress != null) ...[
                    Icon(Icons.place_outlined,
                        size: 14.r,
                        color: Theme.of(context).hintColor),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        order.fullAddress!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (order.estimatedBudget != null)
                    Text(
                      '${order.estimatedBudget!.toStringAsFixed(0)} ₼',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
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
}
