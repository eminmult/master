import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/api/api_exception.dart';
import 'package:master_mobile/core/auth/auth_controller.dart';
import 'package:master_mobile/core/i18n/category_helpers.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/i18n/order_helpers.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/applications/data/applications_repository.dart';
import 'package:master_mobile/features/applications/data/models/application.dart';
import 'package:master_mobile/features/categories/data/categories_repository.dart';
import 'package:master_mobile/features/orders/data/models/order.dart';
import 'package:master_mobile/features/orders/data/orders_repository.dart';
import 'package:master_mobile/shared/widgets/hm_avatar.dart';
import 'package:master_mobile/shared/widgets/hm_bottom_nav.dart';
import 'package:master_mobile/shared/widgets/hm_icon_button.dart';

// --- Data providers --------------------------------------------------------

final _myOrdersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  return ref.watch(ordersRepositoryProvider).myOrders();
});

final _availableOrdersProvider =
    FutureProvider.autoDispose<List<Order>>((ref) async {
  final auth = ref.watch(authStateProvider);
  if (auth is! AuthAuthenticated || !auth.user.isMaster) return const [];
  return ref.watch(ordersRepositoryProvider).available();
});

final _myApplicationsProvider =
    FutureProvider.autoDispose<List<OrderApplication>>((ref) async {
  final auth = ref.watch(authStateProvider);
  if (auth is! AuthAuthenticated || !auth.user.isMaster) return const [];
  final res = await ref.watch(applicationsRepositoryProvider).mine();
  return res.items;
});

// --- Page ------------------------------------------------------------------

/// Smart-sections orders page. Two top-level tabs (Aktiv / Tarixçə) keep
/// "current pipeline" separated from "old work". Inside the active tab,
/// role-aware sections (Diqqət / Aktiv / Müraciətlərim / Mövcud) order
/// items by urgency. The history tab is a flat reverse-chronological list.
class MyOrdersPage extends ConsumerStatefulWidget {
  const MyOrdersPage({super.key});
  @override
  ConsumerState<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends ConsumerState<MyOrdersPage> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final auth = ref.watch(authStateProvider);
    final isMaster = auth is AuthAuthenticated && auth.user.isMaster;

    final asyncOrders = ref.watch(_myOrdersProvider);
    final asyncAvailable = ref.watch(_availableOrdersProvider);
    final asyncApps = ref.watch(_myApplicationsProvider);

    return Scaffold(
      backgroundColor: HmColors.bg,
      body: Stack(children: [
        SafeArea(
          child: Column(children: [
            _Header(title: loc.my_orders_title),
            _TopTabs(
              activeLabel: loc.my_orders_filter_active,
              historyLabel: loc.my_orders_filter_completed,
              showHistory: _showHistory,
              onChange: (v) => setState(() => _showHistory = v),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: _buildBody(
                context, ref,
                isMaster: isMaster,
                asyncOrders: asyncOrders,
                asyncAvailable: asyncAvailable,
                asyncApps: asyncApps,
              ),
            ),
          ]),
        ),
        if (!isMaster)
          Positioned(
            right: 24,
            bottom: 100,
            child: Container(
              decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: HmShadows.fabAccent),
              child: FloatingActionButton(
                onPressed: () => context.push('/order/create'),
                backgroundColor: HmColors.accent,
                foregroundColor: Colors.black,
                child: const Icon(Icons.add_rounded),
              ),
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: HmBottomNav(
            active: HmTab.bookings,
            onChanged: (t) => _onTab(context, t),
          ),
        ),
      ]),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref, {
    required bool isMaster,
    required AsyncValue<List<Order>> asyncOrders,
    required AsyncValue<List<Order>> asyncAvailable,
    required AsyncValue<List<OrderApplication>> asyncApps,
  }) {
    final loc = context.l10n;

    // Combined error if all three streams failed (only ones we depend on).
    final everythingErrored = asyncOrders.hasError &&
        (!isMaster || (asyncAvailable.hasError && asyncApps.hasError));
    if (everythingErrored) {
      return _ErrorState(
        title: loc.auth_failed_to_load,
        retryLabel: loc.notif_retry,
        onRetry: () {
          ref.invalidate(_myOrdersProvider);
          ref.invalidate(_availableOrdersProvider);
          ref.invalidate(_myApplicationsProvider);
        },
      );
    }
    // Show spinner only on truly first load.
    final stillLoading = asyncOrders.isLoading &&
        (!isMaster || (asyncAvailable.isLoading && asyncApps.isLoading));
    if (stillLoading) {
      return const Center(
        child: CircularProgressIndicator(color: HmColors.accent, strokeWidth: 2.4),
      );
    }

    final orders = asyncOrders.valueOrNull ?? const <Order>[];
    final available = asyncAvailable.valueOrNull ?? const <Order>[];
    final applications = asyncApps.valueOrNull ?? const <OrderApplication>[];

    final sections = _categorise(orders, applications, available, isMaster, _showHistory);
    if (sections.every((s) => s.isEmpty)) {
      return _EmptyState(isMaster: isMaster, isHistory: _showHistory);
    }

    return RefreshIndicator(
      color: HmColors.accent,
      backgroundColor: HmColors.surface,
      onRefresh: () async {
        ref.invalidate(_myOrdersProvider);
        ref.invalidate(_availableOrdersProvider);
        ref.invalidate(_myApplicationsProvider);
        await Future.wait([
          ref.read(_myOrdersProvider.future),
          if (isMaster) ref.read(_availableOrdersProvider.future),
          if (isMaster) ref.read(_myApplicationsProvider.future),
        ]);
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
        itemCount: sections.length,
        itemBuilder: (_, i) => _SectionWidget(
          section: sections[i],
          ref: ref,
          isMaster: isMaster,
          onUpdateStatus: (id, next) => _updateStatus(context, ref, id, next),
          onAcceptAvailable: (id) => _acceptAvailable(context, ref, id),
          onWithdraw: (id) => _withdrawApp(context, ref, id),
        ),
      ),
    );
  }

  // --- Categorisation ------------------------------------------------------

  List<_Section> _categorise(
    List<Order> orders,
    List<OrderApplication> applications,
    List<Order> available,
    bool isMaster,
    bool isHistory,
  ) {
    // History tab — show ONLY terminal orders (and rejected/withdrawn apps
    // for masters). Active tab — everything except history.
    if (isHistory) {
      final history = orders.where((o) => o.isTerminal).toList()..sort(_byUpdated);
      final closedApps = applications.where((a) =>
          a.status == ApplicationStatus.rejected ||
          a.status == ApplicationStatus.withdrawn).toList();
      return [
        _Section.orders(_BucketKind.history, history),
        if (isMaster && closedApps.isNotEmpty)
          _Section.applications(_BucketKind.applicationsClosed, closedApps),
      ];
    }

    if (isMaster) {
      // Master mental model:
      //  - DİQQƏT — orders where YOU must advance the status next
      //  - AKTIV  — orders moving forward but you don't need to act now
      //  - MÜRACİƏTLƏRIM — open applications waiting on the client
      //  - MÖVCUD — public pool you can claim
      //  - TARIXÇƏ — finished work
      const diqqetSet = {
        OrderStatus.accepted,
        OrderStatus.arrived,
        OrderStatus.inProgress,
      };
      const activeSet = {
        OrderStatus.confirmed,
        OrderStatus.onTheWay,
        OrderStatus.awaitingCompletion,
        OrderStatus.awaitingReview,
        OrderStatus.discussion,
        OrderStatus.pendingClient,
      };
      final diqqet = orders.where((o) => diqqetSet.contains(o.status)).toList();
      final active = orders.where((o) => activeSet.contains(o.status)).toList();

      final openApps = applications.where((a) =>
          a.status == ApplicationStatus.pending ||
          a.status == ApplicationStatus.discussing ||
          a.status == ApplicationStatus.proposed).toList();

      return [
        _Section.orders(_BucketKind.diqqet, diqqet),
        _Section.orders(_BucketKind.active, active),
        _Section.applications(_BucketKind.applications, openApps),
        _Section.orders(_BucketKind.available, available.take(10).toList()),
      ];
    }

    // Client mental model:
    //  - DİQQƏT — proposal awaiting your accept; work finished, confirm
    //  - AKTIV  — order in motion, no action needed yet
    //  - TARIXÇƏ — finished or canceled
    const diqqetSet = {
      OrderStatus.pendingClient,
      OrderStatus.awaitingCompletion,
    };
    const activeSet = {
      OrderStatus.newOrder,
      OrderStatus.searching,
      OrderStatus.pendingMaster,
      OrderStatus.discussion,
      OrderStatus.confirmed,
      OrderStatus.accepted,
      OrderStatus.onTheWay,
      OrderStatus.arrived,
      OrderStatus.inProgress,
      OrderStatus.awaitingReview,
    };
    final diqqet = orders.where((o) => diqqetSet.contains(o.status)).toList();
    final active = orders.where((o) => activeSet.contains(o.status)).toList();

    return [
      _Section.orders(_BucketKind.diqqet, diqqet),
      _Section.orders(_BucketKind.active, active),
    ];
  }

  // --- Actions -------------------------------------------------------------

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, int id, String status) async {
    final loc = context.l10n;
    try {
      await ref.read(ordersRepositoryProvider).updateStatus(id, status);
      ref.invalidate(_myOrdersProvider);
    } on ApiException catch (e) {
      if (context.mounted) _toast(context, e.message, isError: true);
    } catch (_) {
      if (context.mounted) _toast(context, loc.auth_error_occurred, isError: true);
    }
  }

  Future<void> _acceptAvailable(BuildContext context, WidgetRef ref, int orderId) async {
    final loc = context.l10n;
    try {
      await ref.read(ordersRepositoryProvider).accept(orderId);
      ref.invalidate(_myOrdersProvider);
      ref.invalidate(_availableOrdersProvider);
      if (context.mounted) {
        _toast(context, loc.master_order_accepted);
        context.push('/order/$orderId');
      }
    } on ApiException catch (e) {
      if (context.mounted) _toast(context, e.message, isError: true);
    }
  }

  Future<void> _withdrawApp(BuildContext context, WidgetRef ref, int id) async {
    final loc = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: HmColors.surface,
        title: Text(loc.master_apps_withdraw_confirm_title),
        content: Text(loc.master_apps_withdraw_confirm_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.order_cancel_keep,
                style: const TextStyle(color: HmColors.text4)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: HmColors.danger, foregroundColor: Colors.white),
            child: Text(loc.master_apps_withdraw_btn),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(applicationsRepositoryProvider).withdraw(id);
      ref.invalidate(_myApplicationsProvider);
    } on ApiException catch (e) {
      if (context.mounted) _toast(context, e.message, isError: true);
    }
  }

  void _toast(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? HmColors.danger : HmColors.success,
    ));
  }

  void _onTab(BuildContext context, HmTab tab) {
    switch (tab) {
      case HmTab.home: context.go('/home'); break;
      case HmTab.bookings: break;
      case HmTab.announcements: context.go('/announcements'); break;
      case HmTab.profile: context.go('/profile'); break;
    }
  }
}

int _byUpdated(Order a, Order b) {
  final da = a.completedAt ?? a.canceledAt ?? a.createdAt ?? DateTime(0);
  final db = b.completedAt ?? b.canceledAt ?? b.createdAt ?? DateTime(0);
  return db.compareTo(da);
}

// --- Section types ---------------------------------------------------------

enum _BucketKind {
  diqqet,
  active,
  applications,
  applicationsClosed,
  available,
  history,
}

class _Section {
  _Section.orders(this.kind, this.orders) : applications = const [];
  _Section.applications(this.kind, this.applications) : orders = const [];

  final _BucketKind kind;
  final List<Order> orders;
  final List<OrderApplication> applications;

  bool get isEmpty => orders.isEmpty && applications.isEmpty;
  int get count => orders.length + applications.length;
}

// --- Header ---------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(children: [
        HmIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          small: true,
          flat: true,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
        ),
      ]),
    );
  }
}

// --- Section widget --------------------------------------------------------

class _SectionWidget extends StatelessWidget {
  const _SectionWidget({
    required this.section,
    required this.ref,
    required this.isMaster,
    required this.onUpdateStatus,
    required this.onAcceptAvailable,
    required this.onWithdraw,
  });
  final _Section section;
  final WidgetRef ref;
  final bool isMaster;
  final void Function(int id, String nextStatus) onUpdateStatus;
  final void Function(int id) onAcceptAvailable;
  final void Function(int id) onWithdraw;

  @override
  Widget build(BuildContext context) {
    if (section.isEmpty) return const SizedBox.shrink();
    final loc = context.l10n;
    final palette = _palette(section.kind);
    final label = _label(section.kind, loc);

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header — uppercase label + count badge.
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
            child: Row(children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(color: palette.fg, shape: BoxShape.circle),
              ),
              Text(label,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: palette.fg,
                      letterSpacing: 1.2)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: palette.bg,
                  borderRadius: BorderRadius.circular(HmRadius.pill),
                  border: Border.all(color: palette.border),
                ),
                child: Text('${section.count}',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: palette.fg,
                        height: 1.1)),
              ),
            ]),
          ),
          // Cards.
          for (var i = 0; i < section.orders.length; i++) ...[
            _OrderCard(
              order: section.orders[i],
              isMaster: isMaster,
              kind: section.kind,
              onTap: () => context.push('/order/${section.orders[i].id}'),
              onAdvance: (next) => onUpdateStatus(section.orders[i].id, next),
              onAccept: section.kind == _BucketKind.available
                  ? () => onAcceptAvailable(section.orders[i].id)
                  : null,
            ),
            if (i < section.orders.length - 1) const SizedBox(height: 10),
          ],
          for (var i = 0; i < section.applications.length; i++) ...[
            _ApplicationListCard(
              application: section.applications[i],
              // Pre-acceptance the master isn't yet `master_id` on the order,
              // so /order/:id returns 403. Drive both the card tap and the
              // chat button to the per-application thread — that's where the
              // master's view of the deal lives until acceptance. The chat
              // page itself shows the order details expanded by default so
              // the master sees description + photos immediately.
              onTap: () =>
                  context.push('/chat/application/${section.applications[i].id}'),
              onChat: () =>
                  context.push('/chat/application/${section.applications[i].id}'),
              onWithdraw: () => onWithdraw(section.applications[i].id),
            ),
            if (i < section.applications.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  String _label(_BucketKind k, dynamic loc) => switch (k) {
        _BucketKind.diqqet => loc.orders_section_attention,
        _BucketKind.active => loc.orders_section_active,
        _BucketKind.applications => loc.orders_section_my_applications,
        _BucketKind.applicationsClosed => loc.orders_section_apps_closed,
        _BucketKind.available => loc.orders_section_available,
        _BucketKind.history => loc.orders_section_history,
      };

  ({Color bg, Color border, Color fg}) _palette(_BucketKind k) => switch (k) {
        _BucketKind.diqqet => (
            bg: const Color(0x1FEF4444),
            border: const Color(0x4DEF4444),
            fg: HmColors.danger,
          ),
        _BucketKind.active => (
            bg: const Color(0x1F22C55E),
            border: const Color(0x4D22C55E),
            fg: HmColors.success,
          ),
        _BucketKind.applications ||
        _BucketKind.available => (
            bg: HmColors.accentSoft,
            border: HmColors.accentBorder,
            fg: HmColors.accent,
          ),
        _BucketKind.applicationsClosed ||
        _BucketKind.history => (
            bg: HmColors.surface2,
            border: HmColors.border,
            fg: HmColors.text4,
          ),
      };
}

// --- Order card ------------------------------------------------------------

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.isMaster,
    required this.kind,
    required this.onTap,
    required this.onAdvance,
    this.onAccept,
  });

  final Order order;
  final bool isMaster;
  final _BucketKind kind;
  final VoidCallback onTap;
  final void Function(String nextStatus) onAdvance;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final s = _statusVis(order.status);
    final statusLabel = orderStatusLabel(loc, order.status);

    String categoryName = loc.order_service_fallback;
    final cat = order.category;
    if (cat is Map<String, dynamic> && cat['slug'] != null) {
      categoryName = localizedCategoryName(loc, ServiceCategory.fromJson(cat));
    } else if (cat is Map<String, dynamic> && cat['name'] != null) {
      categoryName = cat['name'].toString();
    }
    final hasMasterAdvance = isMaster && _nextActionFor(order.status) != null;

    return Material(
      color: HmColors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: HmColors.border2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top strip — status + ID
              Row(children: [
                _Pill(text: statusLabel, fg: s.fg, bg: s.bg, border: s.fg.withOpacity(0.3)),
                const Spacer(),
                Text('#${order.id}',
                    style: const TextStyle(
                        fontSize: 11, color: HmColors.text5, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
              ]),
              const SizedBox(height: 10),
              Text(categoryName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
              if (order.description != null && order.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(order.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: HmColors.text4, height: 1.4, fontWeight: FontWeight.w500)),
              ],
              const SizedBox(height: 12),
              Row(children: [
                if (order.fullAddress != null || order.address != null) ...[
                  const Icon(Icons.location_on_outlined, size: 13, color: HmColors.text5),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.fullAddress ?? order.address ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: HmColors.text5),
                    ),
                  ),
                ] else
                  const Spacer(),
                if (order.agreedPrice != null)
                  _PricePill(
                    text: '${order.agreedPrice!.toStringAsFixed(0)} AZN',
                    accent: true,
                  )
                else if (order.estimatedBudget != null)
                  Text(
                    '~${order.estimatedBudget!.toStringAsFixed(0)} AZN',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: HmColors.text4),
                  ),
              ]),
              // Counterparty hint — show client to master, master to client.
              if (isMaster && order.client != null)
                _CounterpartyMini.client(order.client!),
              if (!isMaster && order.master != null)
                _CounterpartyMini.master(order.master!),
              // Action button when master advances or accepts.
              if (onAccept != null) ...[
                const SizedBox(height: 12),
                _ActionButton(
                  label: loc.order_accept_btn,
                  icon: Icons.check_rounded,
                  onTap: onAccept!,
                ),
              ] else if (hasMasterAdvance) ...[
                const SizedBox(height: 12),
                _AdvanceButton(
                  status: order.status,
                  onTap: () => onAdvance(_nextActionFor(order.status)!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String? _nextActionFor(OrderStatus s) => switch (s) {
        OrderStatus.accepted => 'on_the_way',
        OrderStatus.onTheWay => 'arrived',
        OrderStatus.arrived => 'in_progress',
        OrderStatus.inProgress => 'completed',
        _ => null,
      };

  ({Color bg, Color fg}) _statusVis(OrderStatus status) {
    switch (status) {
      case OrderStatus.searching:
      case OrderStatus.pendingMaster:
      case OrderStatus.discussion:
      case OrderStatus.pendingClient:
        return (bg: HmColors.accentSoft, fg: HmColors.accent);
      case OrderStatus.confirmed:
      case OrderStatus.accepted:
      case OrderStatus.onTheWay:
      case OrderStatus.arrived:
      case OrderStatus.inProgress:
      case OrderStatus.awaitingCompletion:
      case OrderStatus.awaitingReview:
      case OrderStatus.completed:
      case OrderStatus.closed:
        return (bg: const Color(0x1F22C55E), fg: HmColors.success);
      case OrderStatus.canceledByClient:
      case OrderStatus.canceledByMaster:
      case OrderStatus.canceledBySystem:
      case OrderStatus.disputed:
        return (bg: const Color(0x1FEF4444), fg: HmColors.danger);
      default:
        return (bg: HmColors.surface2, fg: HmColors.text4);
    }
  }
}

// --- Application card ------------------------------------------------------

class _ApplicationListCard extends StatelessWidget {
  const _ApplicationListCard({
    required this.application,
    required this.onTap,
    required this.onChat,
    required this.onWithdraw,
  });
  final OrderApplication application;
  final VoidCallback onTap;
  final VoidCallback onChat;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final order = application.order ?? const <String, dynamic>{};
    String categoryName = loc.order_service_fallback;
    final cat = order['category'];
    if (cat is Map<String, dynamic> && cat['slug'] != null) {
      categoryName = localizedCategoryName(loc, ServiceCategory.fromJson(cat));
    } else if (cat is Map<String, dynamic> && cat['name'] != null) {
      categoryName = cat['name'].toString();
    }
    final desc = order['description']?.toString();
    final addr = (order['full_address'] ?? order['address'])?.toString();

    return Material(
      color: HmColors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: HmColors.border2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _Pill(
                  text: applicationStatusLabel(loc, application.status),
                  fg: HmColors.accent,
                  bg: HmColors.accentSoft,
                  border: HmColors.accentBorder,
                ),
                const Spacer(),
                if (application.proposedPrice != null)
                  Text('${application.proposedPrice!.toStringAsFixed(0)} AZN',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w900, color: HmColors.accent)),
              ]),
              const SizedBox(height: 10),
              Text(categoryName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              if (desc != null && desc.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: HmColors.text4, height: 1.4, fontWeight: FontWeight.w500)),
              ],
              if (addr != null && addr.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 12, color: HmColors.text5),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(addr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: HmColors.text5)),
                  ),
                ]),
              ],
              if (application.message != null && application.message!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: HmColors.surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: HmColors.border),
                  ),
                  child: Text('“${application.message}”',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: HmColors.text3, height: 1.4, fontStyle: FontStyle.italic)),
                ),
              ],
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onChat,
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                    label: Text(loc.order_chat_btn),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: HmColors.text,
                      side: const BorderSide(color: HmColors.border2),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onWithdraw,
                    icon: const Icon(Icons.close_rounded, size: 14, color: HmColors.danger),
                    label: Text(loc.master_apps_withdraw_btn,
                        style: const TextStyle(color: HmColors.danger)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0x33EF4444)),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Helpers / atoms -------------------------------------------------------

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.fg, required this.bg, required this.border});
  final String text;
  final Color fg;
  final Color bg;
  final Color border;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(HmRadius.pill),
        border: Border.all(color: border),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
            fontSize: 9.5, fontWeight: FontWeight.w900, color: fg, letterSpacing: 0.7, height: 1.1),
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  const _PricePill({required this.text, this.accent = false});
  final String text;
  final bool accent;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent ? HmColors.accentSoft : HmColors.surface2,
        borderRadius: BorderRadius.circular(HmRadius.pill),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w900, color: accent ? HmColors.accent : HmColors.text3),
      ),
    );
  }
}

class _CounterpartyMini extends StatelessWidget {
  const _CounterpartyMini({
    required this.avatarUrl,
    required this.name,
    this.subtitle,
    this.rating,
    this.isMasterRole = false,
  });
  factory _CounterpartyMini.client(Map<String, dynamic> c) => _CounterpartyMini(
        avatarUrl: c['avatar_url']?.toString(),
        name: '${c['first_name'] ?? ''} ${c['last_name'] ?? ''}'.trim(),
        subtitle: c['phone']?.toString(),
      );
  factory _CounterpartyMini.master(Map<String, dynamic> m) => _CounterpartyMini(
        avatarUrl: m['avatar_url']?.toString(),
        name: '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'.trim(),
        rating: double.tryParse(m['rating_avg']?.toString() ?? ''),
        isMasterRole: true,
      );
  final String? avatarUrl;
  final String name;
  final String? subtitle;
  final double? rating;
  final bool isMasterRole;
  @override
  Widget build(BuildContext context) {
    if (name.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
        decoration: BoxDecoration(
          color: HmColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: HmColors.border),
        ),
        child: Row(children: [
          if (avatarUrl != null && avatarUrl!.isNotEmpty)
            HmAvatar(url: avatarUrl!, size: 24)
          else
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: HmColors.surface),
              child: Icon(
                isMasterRole ? Icons.person_rounded : Icons.person_outline_rounded,
                size: 12,
                color: HmColors.text4,
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subtitle != null && subtitle!.isNotEmpty ? '$name · $subtitle' : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: HmColors.text2),
            ),
          ),
          if (rating != null && rating! > 0) ...[
            const Icon(Icons.star_rounded, size: 12, color: HmColors.accent),
            const SizedBox(width: 2),
            Text(rating!.toStringAsFixed(1),
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800, color: HmColors.accent)),
          ],
        ]),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: Colors.black),
        label: Text(label, style: const TextStyle(color: Colors.black)),
        style: FilledButton.styleFrom(
          backgroundColor: HmColors.accent,
          foregroundColor: Colors.black,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _AdvanceButton extends StatelessWidget {
  const _AdvanceButton({required this.status, required this.onTap});
  final OrderStatus status;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final (label, icon, finish) = switch (status) {
      OrderStatus.accepted =>
        (loc.order_action_on_the_way, Icons.directions_run_rounded, false),
      OrderStatus.onTheWay =>
        (loc.order_action_arrived, Icons.location_on_rounded, false),
      OrderStatus.arrived =>
        (loc.order_action_start_work, Icons.play_arrow_rounded, false),
      OrderStatus.inProgress =>
        (loc.order_action_mark_complete, Icons.check_circle_rounded, true),
      _ => ('', Icons.arrow_forward_rounded, false),
    };
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: finish ? Colors.white : Colors.black),
        label: Text(label, style: TextStyle(color: finish ? Colors.white : Colors.black)),
        style: FilledButton.styleFrom(
          backgroundColor: finish ? HmColors.success : HmColors.accent,
          foregroundColor: finish ? Colors.white : Colors.black,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

// --- Empty / error --------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isMaster, required this.isHistory});
  final bool isMaster;
  final bool isHistory;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final title = isHistory
        ? loc.my_orders_empty_history
        : (isMaster ? loc.my_orders_empty_master : loc.my_orders_empty_client);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: HmColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: HmColors.border2),
            ),
            child: const Icon(Icons.inbox_outlined, color: HmColors.text5, size: 32),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: HmColors.text4, height: 1.4),
          ),
          if (!isMaster && !isHistory) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push('/order/create'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(loc.order_create_submit),
              style: FilledButton.styleFrom(
                backgroundColor: HmColors.accent,
                foregroundColor: Colors.black,
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

// --- Top tabs (Aktiv / Tarixçə) -------------------------------------------

class _TopTabs extends StatelessWidget {
  const _TopTabs({
    required this.activeLabel,
    required this.historyLabel,
    required this.showHistory,
    required this.onChange,
  });
  final String activeLabel;
  final String historyLabel;
  final bool showHistory;
  final ValueChanged<bool> onChange;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: HmColors.surface,
          borderRadius: BorderRadius.circular(HmRadius.pill),
          border: Border.all(color: HmColors.border2),
        ),
        child: Row(children: [
          Expanded(child: _TabBtn(label: activeLabel, active: !showHistory, onTap: () => onChange(false))),
          Expanded(child: _TabBtn(label: historyLabel, active: showHistory, onTap: () => onChange(true))),
        ]),
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  const _TabBtn({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? HmColors.accent : Colors.transparent,
      borderRadius: BorderRadius.circular(HmRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HmRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: active ? Colors.black : HmColors.text3,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.title, required this.retryLabel, required this.onRetry});
  final String title;
  final String retryLabel;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded, size: 32, color: HmColors.danger),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 14, color: HmColors.text3)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: HmColors.accent,
              foregroundColor: Colors.black,
              shape: const StadiumBorder(),
            ),
            child: Text(retryLabel),
          ),
        ]),
      ),
    );
  }
}
// poke 1778319143
