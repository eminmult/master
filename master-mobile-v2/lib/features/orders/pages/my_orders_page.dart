import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itez_mobile/app/app_router.dart';
import 'package:itez_mobile/app/di_container.dart';
import 'package:itez_mobile/common/widgets/hm_icon_button.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/core/i18n/l10n_ext.dart';
import 'package:itez_mobile/features/applications/models/order_application.dart';
import 'package:itez_mobile/features/applications/repositories/application_repository.dart';
import 'package:itez_mobile/features/auth/bloc/auth_bloc.dart';
import 'package:itez_mobile/features/auth/models/user_role.dart';
import 'package:itez_mobile/features/orders/bloc/my_orders_bloc.dart';
import 'package:itez_mobile/features/orders/models/order_model.dart';
import 'package:itez_mobile/features/orders/models/order_status.dart';
import 'package:itez_mobile/features/orders/repositories/order_repository.dart';

/// Страница "Заказы" — порт `MyOrdersPage` из master-mobile.
///
/// Два таба верхнего уровня (Активные / История), внутри active —
/// role-aware секции (Внимание / Активные / Мои отклики / Доступные).
/// История — flat reverse-chronological.
@RoutePage()
class MyOrdersPage extends StatefulWidget implements AutoRouteWrapper {
  const MyOrdersPage({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (_) => MyOrdersBloc(
        orders: locator<OrderRepository>(),
        applications: locator<ApplicationRepository>(),
      )..add(MyOrdersRequested(
          isMaster: context.read<AuthBloc>().state.user?.role.isMaster ?? false,
        )),
      child: this,
    );
  }

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final isMaster = auth.user?.role.isMaster ?? false;
    final l = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _Header(title: l.my_orders_title),
                _TopTabs(
                  activeLabel: l.my_orders_filter_active,
                  historyLabel: l.my_orders_filter_completed,
                ),
                const SizedBox(height: 4),
                Expanded(child: _Body(isMaster: isMaster)),
              ],
            ),
          ),
          if (!isMaster)
            Positioned(
              right: 24,
              bottom: 100,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.fabAccent,
                ),
                child: FloatingActionButton(
                  onPressed: () =>
                      context.router.push(CreateOrderRoute()),
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.black,
                  child: const Icon(Icons.add_rounded),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          HmIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            small: true,
            flat: true,
            onTap: () => context.router.canPop()
                ? context.router.maybePop()
                : context.router.replaceAll([const HomeRoute()]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopTabs extends StatelessWidget {
  const _TopTabs({required this.activeLabel, required this.historyLabel});
  final String activeLabel;
  final String historyLabel;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyOrdersBloc, MyOrdersState>(
      buildWhen: (p, c) => p.showHistory != c.showHistory,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.border2),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _tab(context, activeLabel, !state.showHistory, () => context
                    .read<MyOrdersBloc>()
                    .add(const MyOrdersTabChanged(false))),
                _tab(context, historyLabel, state.showHistory, () => context
                    .read<MyOrdersBloc>()
                    .add(const MyOrdersTabChanged(true))),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tab(
    BuildContext context,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppColors.accent : AppColors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: active ? AppColors.black : AppColors.text3,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.isMaster});
  final bool isMaster;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyOrdersBloc, MyOrdersState>(
      builder: (context, state) {
        if (state.loading && state.orders.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 2.4,
            ),
          );
        }
        if (state.error != null && state.orders.isEmpty) {
          return _ErrorState(
            message: state.error!,
            onRetry: () => context
                .read<MyOrdersBloc>()
                .add(MyOrdersRequested(isMaster: isMaster)),
          );
        }
        final sections = context
            .read<MyOrdersBloc>()
            .categorise(isMaster: isMaster)
            .where((s) => !s.isEmpty)
            .toList();
        if (sections.isEmpty) {
          return _EmptyState(
            isMaster: isMaster,
            isHistory: state.showHistory,
          );
        }
        return RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          onRefresh: () async => context
              .read<MyOrdersBloc>()
              .add(MyOrdersRefreshed(isMaster: isMaster)),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
            itemCount: sections.length,
            itemBuilder: (_, i) => _SectionView(
              section: sections[i],
              isMaster: isMaster,
            ),
          ),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 36, color: AppColors.text4),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.text3, fontSize: 14),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
                onPressed: onRetry, child: Text(context.l10n.notif_retry)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isMaster, required this.isHistory});
  final bool isMaster;
  final bool isHistory;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isHistory
                  ? Icons.history_rounded
                  : Icons.inbox_outlined,
              size: 48,
              color: AppColors.text4,
            ),
            const SizedBox(height: 12),
            Text(
              isHistory
                  ? l.my_orders_empty_history
                  : (isMaster
                      ? l.my_orders_empty_master
                      : l.my_orders_empty_client),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.text3, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionView extends StatelessWidget {
  const _SectionView({required this.section, required this.isMaster});
  final MyOrdersSection section;
  final bool isMaster;

  @override
  Widget build(BuildContext context) {
    if (section.isEmpty) return const SizedBox.shrink();
    final l = context.l10n;
    final palette = _palette(section.kind);
    final label = switch (section.kind) {
      SectionKind.attention => l.orders_section_attention,
      SectionKind.active => l.orders_section_active,
      SectionKind.applications => l.orders_section_my_applications,
      SectionKind.applicationsClosed => l.orders_section_apps_closed,
      SectionKind.available => l.orders_section_available,
      SectionKind.history => l.orders_section_history,
    };

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header: dot + UPPERCASE + count
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: palette.fg,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: palette.fg,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    color: palette.bg,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: palette.border),
                  ),
                  child: Text(
                    '${section.count}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: palette.fg,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < section.orders.length; i++) ...[
            _OrderCardItem(order: section.orders[i]),
            if (i < section.orders.length - 1) const SizedBox(height: 10),
          ],
          for (var i = 0; i < section.applications.length; i++) ...[
            _ApplicationCardItem(application: section.applications[i]),
            if (i < section.applications.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  ({Color bg, Color border, Color fg}) _palette(SectionKind k) => switch (k) {
        SectionKind.attention => (
            bg: const Color(0x1FEF4444),
            border: const Color(0x4DEF4444),
            fg: AppColors.danger,
          ),
        SectionKind.active => (
            bg: const Color(0x1F22C55E),
            border: const Color(0x4D22C55E),
            fg: AppColors.success,
          ),
        SectionKind.applications ||
        SectionKind.available =>
          (
            bg: AppColors.accentSoft,
            border: AppColors.accent,
            fg: AppColors.accent,
          ),
        SectionKind.applicationsClosed ||
        SectionKind.history =>
          (
            bg: AppColors.surface2,
            border: AppColors.border,
            fg: AppColors.text4,
          ),
      };
}

class _OrderCardItem extends StatelessWidget {
  const _OrderCardItem({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.router.push(OrderDetailRoute(id: order.id)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusPill(status: order.status),
                  const Spacer(),
                  Text(
                    '#${order.id}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.text5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                order.categoryName ?? '—',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: AppColors.text,
                ),
              ),
              if (order.description != null &&
                  order.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  order.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.text4,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (order.fullAddress != null) ...[
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: AppColors.text5),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.fullAddress!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.text5,
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  if (order.estimatedBudget != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '${order.estimatedBudget!.toStringAsFixed(0)} AZN',
                        style: const TextStyle(
                          fontSize: 12,
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
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Color _color(OrderStatus s) {
    if (s.isCanceled || s == OrderStatus.disputed) return AppColors.danger;
    if (s.isFinished) return AppColors.success;
    if (s == OrderStatus.pendingPayment) return AppColors.warning;
    if (s == OrderStatus.unknown) return AppColors.text4;
    return AppColors.accent;
  }
}

class _ApplicationCardItem extends StatelessWidget {
  const _ApplicationCardItem({required this.application});
  final OrderApplication application;

  @override
  Widget build(BuildContext context) {
    final order = application.order;
    final cat = order?['category'];
    final categoryName = cat is Map ? cat['name']?.toString() : null;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            context.router.push(OrderDetailRoute(id: application.orderId)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius:
                          BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.accent),
                    ),
                    child: Text(
                      _statusLabel(context, application.status),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '#${application.orderId}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.text5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                categoryName ?? '—',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              if (application.message != null &&
                  application.message!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  application.message!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.text4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (application.proposedPrice != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${application.proposedPrice!.toStringAsFixed(0)} AZN',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(BuildContext context, ApplicationStatus s) {
    final l = context.l10n;
    return switch (s) {
      ApplicationStatus.pending => l.app_status_applied,
      ApplicationStatus.discussing => l.app_status_discussing,
      ApplicationStatus.proposed => l.app_status_proposed,
      ApplicationStatus.accepted => l.app_status_accepted,
      ApplicationStatus.rejected => l.app_status_rejected,
      ApplicationStatus.withdrawn => l.app_status_withdrawn,
      ApplicationStatus.unknown => '—',
    };
  }
}
