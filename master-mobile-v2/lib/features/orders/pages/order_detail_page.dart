import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itez_mobile/app/app_router.dart';
import 'package:itez_mobile/app/di_container.dart';
import 'package:itez_mobile/common/widgets/app_error_view.dart';
import 'package:itez_mobile/common/widgets/hm_avatar.dart';
import 'package:itez_mobile/common/widgets/hm_icon_button.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/core/i18n/l10n_ext.dart';
import 'package:itez_mobile/core/realtime/realtime_service.dart';
import 'package:itez_mobile/core/utils/json_parse.dart';
import 'package:itez_mobile/features/applications/repositories/application_repository.dart';
import 'package:itez_mobile/features/auth/bloc/auth_bloc.dart';
import 'package:itez_mobile/features/calls/bloc/call_bloc.dart';
import 'package:itez_mobile/features/orders/bloc/order_detail_bloc.dart';
import 'package:itez_mobile/features/orders/gps_tracking/gps_pusher.dart';
import 'package:itez_mobile/features/orders/live_tracking/live_tracking_bloc.dart';
import 'package:itez_mobile/features/orders/models/order_model.dart';
import 'package:itez_mobile/features/orders/models/order_status.dart';
import 'package:itez_mobile/features/orders/pages/order_detail_sheets/order_navigation_sheet.dart';
import 'package:itez_mobile/features/orders/pages/order_detail_widgets/live_map_card.dart';
import 'package:itez_mobile/features/orders/pages/order_detail_widgets/order_action_prompt.dart';
import 'package:itez_mobile/features/orders/pages/order_detail_widgets/order_applications_inbox.dart';
import 'package:itez_mobile/features/orders/pages/order_detail_widgets/order_messages_view.dart';
import 'package:itez_mobile/features/orders/pages/order_detail_widgets/order_terminal_body.dart';
import 'package:itez_mobile/features/orders/repositories/order_repository.dart';

/// Статусы, в которых открыт inline-чат заказа.
const _chatActiveStatuses = {
  OrderStatus.discussion,
  OrderStatus.pendingClient,
  OrderStatus.pendingPayment,
  OrderStatus.confirmed,
  OrderStatus.accepted,
  OrderStatus.onTheWay,
  OrderStatus.arrived,
  OrderStatus.inProgress,
  OrderStatus.awaitingCompletion,
};

/// Статусы, в которых можно звонить через in-app calls.
const _callAvailableStatuses = {
  OrderStatus.confirmed,
  OrderStatus.accepted,
  OrderStatus.onTheWay,
  OrderStatus.arrived,
  OrderStatus.inProgress,
  OrderStatus.awaitingCompletion,
};

/// OrderDetailPage — порт `order_detail_page.dart` из master-mobile.
///
/// Структура (скелет, без чата/карты/sheets — добавится отдельным проходом):
///   _Header — back-кнопка + аватар counterparty + name + #id + dot + status
///   _PriceCard — если есть agreed_price (для completed/closed заказа)
///   _CounterpartyCard — avatar 44 + name + rating + chevron
///   _AddressCard — icon + адрес + copy-кнопка
///   _PhotosGallery — горизонтальный scroll 96×96 thumbnails
///   _StatusTimeline — вертикальные шаги статусов
///   _Actions — контекстные кнопки (cancel/confirm/accept/decline)
@RoutePage()
class OrderDetailPage extends StatelessWidget implements AutoRouteWrapper {
  const OrderDetailPage({
    super.key,
    @PathParam('id') required this.id,
  });
  final int id;

  @override
  Widget wrappedRoute(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => OrderDetailBloc(
            orders: locator<OrderRepository>(),
            applications: locator<ApplicationRepository>(),
          )..add(OrderDetailRequested(id, publicFallback: true)),
        ),
        BlocProvider(
          create: (_) =>
              LiveTrackingBloc(realtime: locator<RealtimeService>())
                ..add(LiveTrackingStarted(id)),
        ),
      ],
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: BlocConsumer<OrderDetailBloc, OrderDetailState>(
        listenWhen: (p, c) =>
            (p.mutationError != c.mutationError && c.mutationError != null) ||
            (p.lastActionSucceeded != c.lastActionSucceeded &&
                c.lastActionSucceeded),
        listener: (context, state) {
          final err = state.mutationError;
          if (err != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(err),
                backgroundColor: AppColors.danger,
              ),
            );
          } else if (state.lastActionSucceeded) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.common_done),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.order == null && state.error == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }
          if (state.error != null && state.order == null) {
            return SafeArea(
              child: Column(
                children: [
                  _Header(order: null, onBack: () => _back(context)),
                  Expanded(
                    child: AppErrorView(
                      message: state.error!,
                      onRetry: () => context.read<OrderDetailBloc>().add(
                            OrderDetailRequested(id, publicFallback: true),
                          ),
                    ),
                  ),
                ],
              ),
            );
          }
          final order = state.order!;
          return _GpsGate(
            order: order,
            child: SafeArea(
              child: Column(
                children: [
                  _Header(order: order, onBack: () => _back(context)),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.accent,
                      backgroundColor: AppColors.surface,
                      onRefresh: () async => context
                          .read<OrderDetailBloc>()
                          .add(OrderDetailRequested(id, publicFallback: true)),
                      child: _Body(order: order, mutating: state.mutating),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _back(BuildContext context) {
    if (context.router.canPop()) {
      context.router.maybePop();
    } else {
      context.router.replaceAll([const OrdersRoute()]);
    }
  }
}

/// Хост-виджет страницы заказа: при master + live-map статусе включает
/// GPS-стрим (через [GpsPusher]). Выключает при уходе со страницы или
/// смене статуса.
class _GpsGate extends StatefulWidget {
  const _GpsGate({required this.order, required this.child});
  final OrderModel order;
  final Widget child;

  @override
  State<_GpsGate> createState() => _GpsGateState();
}

class _GpsGateState extends State<_GpsGate> {
  static const _trackingStatuses = {
    OrderStatus.onTheWay,
    OrderStatus.arrived,
    OrderStatus.inProgress,
    OrderStatus.awaitingCompletion,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _GpsGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final auth = context.read<AuthBloc>().state;
    final user = auth.user;
    final order = widget.order;
    final isMaster = user != null && user.id == order.masterId;
    final shouldTrack =
        isMaster && _trackingStatuses.contains(order.status);
    final pusher = locator<GpsPusher>();
    if (shouldTrack && !pusher.isActive) {
      pusher.start(order.id);
    } else if (!shouldTrack && pusher.isActive) {
      pusher.stop();
    }
  }

  @override
  void dispose() {
    locator<GpsPusher>().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ─────────────────────────── Header ───────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.order, required this.onBack});
  final OrderModel? order;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final user = auth.user;
    final order = this.order;
    final isClient = order != null &&
        user != null &&
        user.id == order.clientId;
    final party = order == null
        ? null
        : (isClient ? order.master : order.client);

    final name = party?.displayName ?? '';
    final avatar = party?.avatarUrl;
    final rating = isClient ? (party?.ratingAvg ?? 0) : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 10),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.border2)),
      ),
      child: Row(
        children: [
          HmIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            small: true,
            flat: true,
            onTap: onBack,
          ),
          const SizedBox(width: 4),
          if (avatar != null && avatar.isNotEmpty)
            HmAvatar(url: avatar, size: 36)
          else
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface2,
              ),
              child: const Icon(Icons.person_rounded,
                  size: 18, color: AppColors.text4),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? (order == null ? '—' : '#${order.id}') : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 1),
                if (order != null)
                  Row(children: [
                    Text(
                      '#${order.id}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.text5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusDot(status: order.status),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        order.status.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.text4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ]),
              ],
            ),
          ),
          if (rating > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded,
                      size: 11, color: AppColors.accent),
                  const SizedBox(width: 2),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // In-app call: показываем только в "callable" статусах (после оплаты
          // call-out fee). Номера телефонов нигде не светим — звонок идёт
          // через WebRTC channel внутри приложения.
          if (order != null &&
              party != null &&
              _callAvailableStatuses.contains(order.status)) ...[
            const SizedBox(width: 6),
            Material(
              color: AppColors.success,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  context.read<CallBloc>().add(CallOutgoingRequested(
                        calleeId: party.id,
                        orderId: order.id,
                      ));
                },
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(Icons.phone_rounded,
                      size: 16, color: AppColors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final OrderStatus status;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _color(status),
      ),
    );
  }

  Color _color(OrderStatus s) {
    if (s.isCanceled || s == OrderStatus.disputed) return AppColors.danger;
    if (s.isFinished) return AppColors.success;
    if (s == OrderStatus.pendingPayment) return AppColors.warning;
    return AppColors.accent;
  }
}

// ─────────────────────────── Body ───────────────────────────
class _Body extends StatelessWidget {
  const _Body({required this.order, required this.mutating});
  final OrderModel order;
  final bool mutating;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final user = auth.user;
    final isClient = user != null && user.id == order.clientId;

    // Terminal-статусы (canceled / closed / completed) → отдельный layout
    // с hero-плашкой и review summary.
    if (order.status.isCanceled || order.status.isFinished) {
      return OrderTerminalBody(order: order, isClient: isClient);
    }

    // Searching master + клиент → инлайн inbox откликов.
    if (isClient && order.status == OrderStatus.searching) {
      return Column(
        children: [
          OrderActionPrompt(
            order: order,
            isClient: isClient,
            mutating: mutating,
          ),
          Expanded(child: const OrderApplicationsInbox()),
        ],
      );
    }

    // Chat-active статусы → детали + кнопка-кнопка чата.
    final chatOpen = _chatActiveStatuses.contains(order.status);

    return Column(
      children: [
        OrderActionPrompt(
          order: order,
          isClient: isClient,
          mutating: mutating,
        ),
        Expanded(
          child: chatOpen
              ? _ChatTabbed(order: order, isClient: isClient, mutating: mutating)
              : _DetailsScroll(
                  order: order,
                  isClient: isClient,
                  mutating: mutating,
                ),
        ),
      ],
    );
  }
}

/// Скроллируемая «детали»-страница со всеми секциями: price, description,
/// photos, counterparty, address, timeline, optional cancel actions.
class _DetailsScroll extends StatelessWidget {
  const _DetailsScroll({
    required this.order,
    required this.isClient,
    required this.mutating,
  });
  final OrderModel order;
  final bool isClient;
  final bool mutating;

  @override
  Widget build(BuildContext context) {
    final agreedPrice = parseDoubleOrNull(order.raw['agreed_price']);
    final cancelReason = order.raw['cancel_reason']?.toString();
    final showMap = const {
      OrderStatus.onTheWay,
      OrderStatus.arrived,
      OrderStatus.inProgress,
      OrderStatus.awaitingCompletion,
    }.contains(order.status);

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
      children: [
        if (showMap) LiveMapCard(order: order),
        if (agreedPrice != null && agreedPrice > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PriceCard(
              price: agreedPrice,
              label: context.l10n.order_final_price,
            ),
          ),
        if (cancelReason != null && cancelReason.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CancelReasonCard(reason: cancelReason),
          ),
        if (order.description != null && order.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              order.description!,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.text,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (order.photos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _PhotosGallery(
                urls: order.photos.map((p) => p.url).toList()),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: _CounterpartyCard(order: order, isClient: isClient),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: _AddressCard(order: order, isClient: isClient),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _StatusTimeline(order: order, isClient: isClient),
        ),
        if (isClient && order.status.isActive) ...[
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _CancelTrigger(order: order, mutating: mutating),
          ),
        ],
      ],
    );
  }
}

/// Чат-приоритетный layout (chat-active статус). Сверху — детали (свёрнутые
/// в TabBar), снизу — full-height чат.
class _ChatTabbed extends StatelessWidget {
  const _ChatTabbed({
    required this.order,
    required this.isClient,
    required this.mutating,
  });
  final OrderModel order;
  final bool isClient;
  final bool mutating;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.border2),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              indicator: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              indicatorPadding: EdgeInsets.zero,
              dividerColor: AppColors.transparent,
              labelColor: AppColors.black,
              unselectedLabelColor: AppColors.text3,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              tabs: [
                Tab(text: l.order_tab_chat),
                Tab(text: l.order_tab_details),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: TabBarView(
              children: [
                const OrderMessagesView(),
                _DetailsScroll(
                  order: order,
                  isClient: isClient,
                  mutating: mutating,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Триггер cancel из деталей (отдельная outline кнопка снизу).
class _CancelTrigger extends StatelessWidget {
  const _CancelTrigger({required this.order, required this.mutating});
  final OrderModel order;
  final bool mutating;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: mutating
            ? null
            : () => showOrderCancelSheet(
                context, context.read<OrderDetailBloc>()),
        icon: const Icon(Icons.close_rounded, size: 16),
        label: Text(context.l10n.order_cancel_btn),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: Color(0x4DEF4444)),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ─────────────────────────── Sections ───────────────────────────
class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.price, required this.label});
  final double price;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x14FFFF00), Color(0x05FFFF00)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          border: Border.all(color: AppColors.accent),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentSoft,
              ),
              child: const Icon(Icons.payments_rounded,
                  size: 18, color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.text4,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${price.toStringAsFixed(0)} ₼',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CancelReasonCard extends StatelessWidget {
  const _CancelReasonCard({required this.reason});
  final String reason;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0x14EF4444),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: const Color(0x4DEF4444)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cancel_outlined,
                size: 16, color: AppColors.danger),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                reason,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.text2,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterpartyCard extends StatelessWidget {
  const _CounterpartyCard({required this.order, required this.isClient});
  final OrderModel order;
  final bool isClient;
  @override
  Widget build(BuildContext context) {
    final party = isClient ? order.master : order.client;
    if (party == null) return const SizedBox.shrink();
    final name = party.displayName;
    final avatar = party.avatarUrl;
    final rating = isClient ? (party.ratingAvg ?? 0) : 0.0;
    final partyId = party.id;
    final route = isClient ? MasterDetailRoute(idOrSlug: '$partyId') : null;

    return Material(
      color: AppColors.bg,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: route == null
            ? null
            : () => context.router.push(route),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border2),
          ),
          child: Row(
            children: [
              if (avatar != null && avatar.isNotEmpty)
                HmAvatar(url: avatar, size: 44, ring: true)
              else
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface2,
                  ),
                  child: Icon(
                    isClient
                        ? Icons.person_rounded
                        : Icons.person_outline_rounded,
                    color: AppColors.text4,
                    size: 20,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name.isEmpty ? '—' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ),
              if (rating > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 11, color: AppColors.accent),
                      const SizedBox(width: 3),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              if (route != null) ...[
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    size: 16, color: AppColors.text5),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.order, required this.isClient});
  final OrderModel order;
  final bool isClient;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final addr = order.fullAddress ?? '—';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_rounded,
              size: 16, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              addr,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.text2,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!isClient)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.copy_rounded,
                  size: 14, color: AppColors.text4),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: addr));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l.order_address_copied),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          if (order.lat != null && order.lng != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.directions_rounded,
                  size: 16, color: AppColors.accent),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useRootNavigator: true,
                backgroundColor: AppColors.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppRadius.cardLarge),
                  ),
                ),
                builder: (_) => OrderNavigationSheet(
                  lat: order.lat!,
                  lng: order.lng!,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotosGallery extends StatelessWidget {
  const _PhotosGallery({required this.urls});
  final List<String> urls;
  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) => InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _openLightbox(context, urls, i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: urls[i],
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 96,
                height: 96,
                color: AppColors.surface2,
                child: const Icon(Icons.image_not_supported_outlined,
                    size: 18, color: AppColors.text5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openLightbox(BuildContext context, List<String> urls, int startIndex) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) =>
            _PhotoLightbox(urls: urls, initialIndex: startIndex),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }
}

class _PhotoLightbox extends StatefulWidget {
  const _PhotoLightbox({required this.urls, required this.initialIndex});
  final List<String> urls;
  final int initialIndex;
  @override
  State<_PhotoLightbox> createState() => _PhotoLightboxState();
}

class _PhotoLightboxState extends State<_PhotoLightbox> {
  late final PageController _pc =
      PageController(initialPage: widget.initialIndex);
  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pc,
              itemCount: widget.urls.length,
              itemBuilder: (_, i) => InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.urls[i],
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.order, required this.isClient});
  final OrderModel order;
  final bool isClient;

  static const _stepsClient = [
    OrderStatus.newOrder,
    OrderStatus.searching,
    OrderStatus.discussion,
    OrderStatus.confirmed,
    OrderStatus.accepted,
    OrderStatus.onTheWay,
    OrderStatus.arrived,
    OrderStatus.inProgress,
    OrderStatus.awaitingCompletion,
    OrderStatus.completed,
    OrderStatus.closed,
  ];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // Текущий статус в списке шагов — всё выше уже пройдено.
    final currentIdx = _stepsClient.indexOf(order.status);
    if (order.status.isCanceled) {
      // Для отменённых отдельная маленькая плашка.
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x14EF4444),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x4DEF4444)),
        ),
        child: Row(
          children: [
            const Icon(Icons.block_rounded,
                color: AppColors.danger, size: 16),
            const SizedBox(width: 8),
            Text(
              order.status.label,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(color: AppColors.border2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.order_timeline_title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.text4,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < _stepsClient.length; i++)
            _StatusStep(
              label: _stepsClient[i].label,
              done: currentIdx >= 0 && i <= currentIdx,
              active: i == currentIdx,
              isLast: i == _stepsClient.length - 1,
            ),
        ],
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  const _StatusStep({
    required this.label,
    required this.done,
    required this.active,
    required this.isLast,
  });
  final String label;
  final bool done;
  final bool active;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = done
        ? (active ? AppColors.accent : AppColors.success)
        : AppColors.text5;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? color : AppColors.surface2,
                  border: Border.all(
                    color: done ? color : AppColors.border2,
                    width: 2,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: done ? color : AppColors.border2,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: done ? AppColors.text : AppColors.text4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// (Actions полностью заменены OrderActionPrompt + _CancelTrigger.)
