import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/app/app_router.dart';
import 'package:itez_mobile/common/widgets/app_error_view.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/features/notifications/bloc/notifications_bloc.dart';
import 'package:itez_mobile/features/notifications/models/notification_model.dart';

@RoutePage()
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsBloc>().add(const NotificationsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          TextButton(
            onPressed: () => context
                .read<NotificationsBloc>()
                .add(const NotificationsAllRead()),
            child: const Text('Прочитать все'),
          ),
        ],
      ),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          if (state.loading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null && state.items.isEmpty) {
            return AppErrorView(
              message: state.error!,
              onRetry: () => context
                  .read<NotificationsBloc>()
                  .add(const NotificationsRequested()),
            );
          }
          if (state.items.isEmpty) {
            return const AppErrorView(message: 'Уведомлений пока нет');
          }
          return RefreshIndicator(
            onRefresh: () async => context
                .read<NotificationsBloc>()
                .add(const NotificationsRequested()),
            child: ListView.separated(
              padding: EdgeInsets.all(16.w),
              itemCount: state.items.length,
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (_, i) => _Tile(notification: state.items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.notification});
  final NotificationModel notification;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () {
          context.read<NotificationsBloc>().add(NotificationRead(n.id));
          final orderId = n.orderId;
          if (orderId != null) {
            context.router.push(OrderDetailRoute(id: orderId));
          }
        },
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Row(
            children: [
              Container(
                width: 8.r,
                height: 8.r,
                margin: EdgeInsets.only(top: 6.h, right: 10.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: n.isUnread
                      ? AppColors.brandPrimary
                      : Colors.transparent,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (n.message.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        n.message,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                    if (n.createdAt != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        n.createdAt!.toLocal().toString().substring(0, 16),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Theme.of(context).hintColor,
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
