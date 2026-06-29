import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itez_mobile/app/app_router.dart';
import 'package:itez_mobile/app/di_container.dart';
import 'package:itez_mobile/common/widgets/app_error_view.dart';
import 'package:itez_mobile/features/auth/bloc/auth_bloc.dart';
import 'package:itez_mobile/features/auth/models/user_role.dart';
import 'package:itez_mobile/features/orders/bloc/orders_bloc.dart';
import 'package:itez_mobile/features/orders/repositories/order_repository.dart';
import 'package:itez_mobile/features/orders/widgets/order_card.dart';

@RoutePage()
class OrdersPage extends StatelessWidget implements AutoRouteWrapper {
  const OrdersPage({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (_) => OrdersBloc(locator<OrderRepository>()),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final user = auth.user;
    final isMaster = user?.role.isMaster ?? false;

    return DefaultTabController(
      length: isMaster ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Заказы'),
          bottom: isMaster
              ? const TabBar(tabs: [
                  Tab(text: 'Мои'),
                  Tab(text: 'Доступные'),
                ])
              : null,
          actions: [
            if (!isMaster)
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () =>
                    context.router.push(CreateOrderRoute()),
              ),
          ],
        ),
        body: isMaster
            ? const TabBarView(children: [
                _OrdersList(scope: OrdersScope.my),
                _OrdersList(scope: OrdersScope.available),
              ])
            : const _OrdersList(scope: OrdersScope.my),
      ),
    );
  }
}

class _OrdersList extends StatefulWidget {
  const _OrdersList({required this.scope});
  final OrdersScope scope;

  @override
  State<_OrdersList> createState() => _OrdersListState();
}

class _OrdersListState extends State<_OrdersList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    context.read<OrdersBloc>().add(OrdersRequested(widget.scope));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) => switch (state) {
        OrdersInitial() ||
        OrdersLoading() =>
          const Center(child: CircularProgressIndicator()),
        OrdersFailed(:final message) => AppErrorView(
            message: message,
            onRetry: () =>
                context.read<OrdersBloc>().add(const OrdersRefreshed()),
          ),
        OrdersLoaded(:final items) when items.isEmpty =>
          const AppErrorView(message: 'Пока пусто'),
        OrdersLoaded(:final items) => RefreshIndicator(
            onRefresh: () async =>
                context.read<OrdersBloc>().add(const OrdersRefreshed()),
            child: ListView.separated(
              padding: EdgeInsets.all(16.w),
              itemCount: items.length,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (_, i) => OrderCard(
                order: items[i],
                onTap: () => context.router.push(
                  OrderDetailRoute(id: items[i].id),
                ),
              ),
            ),
          ),
      },
    );
  }
}
