import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:master_mobile/core/api/api_exception.dart';
import 'package:master_mobile/core/auth/auth_controller.dart';
import 'package:master_mobile/core/i18n/category_helpers.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/i18n/order_helpers.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/applications/data/applications_repository.dart';
import 'package:master_mobile/features/calls/data/call_service.dart';
import 'package:master_mobile/features/realtime/sse_client.dart';
import 'package:master_mobile/features/wallet/presentation/callout_fee_sheet.dart';
import 'package:master_mobile/features/applications/data/models/application.dart';
import 'package:master_mobile/features/categories/data/categories_repository.dart';
import 'package:master_mobile/features/orders/data/models/order.dart';
import 'package:master_mobile/features/orders/data/orders_repository.dart';
import 'package:master_mobile/shared/widgets/hm_avatar.dart';
import 'package:master_mobile/shared/widgets/hm_icon_button.dart';
import 'package:url_launcher/url_launcher.dart';

// === Provider lifecycle ====================================================

final _orderProvider = FutureProvider.autoDispose.family<Order, int>((ref, id) async {
  return ref.watch(ordersRepositoryProvider).show(id);
});

final _applicationsProvider =
    FutureProvider.autoDispose.family<List<OrderApplication>, int>((ref, id) async {
  return ref.watch(applicationsRepositoryProvider).forOrder(id);
});

// === Status sets ==========================================================

/// In-app call enabled — only during the active work window.
/// Phone numbers are NEVER shown to either party; voice calls go through the
/// in-app WebRTC channel instead.
const _callAvailableStatuses = <OrderStatus>{
  OrderStatus.confirmed,
  OrderStatus.accepted,
  OrderStatus.onTheWay,
  OrderStatus.arrived,
  OrderStatus.inProgress,
  OrderStatus.awaitingCompletion,
  OrderStatus.awaitingReview,
};

/// Build-route — master heading to the client.
const _routeVisibleStatuses = <OrderStatus>{
  OrderStatus.confirmed,
  OrderStatus.accepted,
  OrderStatus.onTheWay,
};

/// Order chat is open in these states (mirrors site `chatStatuses`).
const _chatActiveStatuses = <OrderStatus>{
  OrderStatus.discussion,
  OrderStatus.pendingClient,
  OrderStatus.confirmed,
  OrderStatus.accepted,
  OrderStatus.onTheWay,
  OrderStatus.arrived,
  OrderStatus.inProgress,
};

/// Map visibility window. From the moment the callout fee is paid (status
/// `confirmed`) the address + map are useful — the client wants to see the
/// destination, and the master needs to know where to go. The live tracker
/// kicks in once `on_the_way` is set; before that only the destination pin
/// is rendered.
const _liveMapStatuses = <OrderStatus>{
  OrderStatus.confirmed,
  OrderStatus.accepted,
  OrderStatus.onTheWay,
  OrderStatus.arrived,
  OrderStatus.inProgress,
};

// === Page ==================================================================

/// Chat-first order detail. The whole screen acts like a Telegram-style
/// conversation:
///   compact header → status-aware action prompt → message stream → input.
/// Tap the floating "Detallar" FAB to slide up a bottom sheet with the
/// full order info (photos, address, timeline, counterparty profile).
///
/// Master action buttons (Discuss/Decline, Confirm work, Mark on-the-way…)
/// live INSIDE the sticky action prompt under the header — never hidden,
/// never requires a tab swap. System events (proposal sent, master arrived,
/// work started…) render as rich inline cards in the message stream.
class OrderDetailPage extends ConsumerStatefulWidget {
  const OrderDetailPage({super.key, required this.orderId});
  final int orderId;
  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  final _msgCtrl = TextEditingController();
  final _scroll = ScrollController();
  Timer? _poll;
  Timer? _gpsTimer;
  StreamSubscription<Position>? _gpsSub;
  List<Map<String, dynamic>> _messages = [];
  bool _sending = false;
  bool _gpsActive = false;

  @override
  void initState() {
    super.initState();
    // Kick off the first chat fetch as soon as the order Future resolves —
    // before, history only appeared after the next polling tick (up to 5s
    // wait because the initial fetch bailed out on a null order).
    Future.microtask(() async {
      try {
        await ref.read(_orderProvider(widget.orderId).future);
      } catch (_) {}
      if (mounted) _refreshChatIncremental();
    });
    // SSE = primary realtime channel; the poll below is just a safety net for
    // missed events on a dropped stream the SSE client hasn't reconnected yet.
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindSse());
    _poll = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      _refreshChatIncremental();
    });
    _statusPoll = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      ref.invalidate(_orderProvider(widget.orderId));
      ref.invalidate(_applicationsProvider(widget.orderId));
      _maybeToggleGpsTracking();
    });
  }

  Timer? _statusPoll;
  StreamSubscription<Map<String, dynamic>>? _sseSub;

  void _bindSse() {
    final sse = ref.read(sseClientProvider);
    _sseSub = sse.events.listen((e) {
      if (!mounted) return;
      if (e['type'] != 'chat.message') return;
      final scope = e['scope']?.toString();
      final scopeId = (e['scope_id'] as num?)?.toInt();
      if (scope == 'order' && scopeId == widget.orderId) {
        _refreshChatIncremental();
      }
    });
  }

  /// First-load + incremental refresh. The full pull only runs once (when
  /// `_messages` is empty); subsequent polls hit the server with `since=<id>`
  /// and append anything new. Both pre-empt themselves if the chat isn't
  /// open for this order's status.
  Future<void> _refreshChatIncremental() async {
    if (!mounted) return;
    final order = ref.read(_orderProvider(widget.orderId)).valueOrNull;
    if (order == null || !_chatActiveStatuses.contains(order.status)) return;
    try {
      if (_messages.isEmpty) {
        final list = await ref.read(ordersRepositoryProvider).messages(widget.orderId);
        if (!mounted) return;
        setState(() => _messages = list);
        _scrollToBottom();
        return;
      }
      final lastId = _messages
          .map((m) => (m['id'] as num?)?.toInt() ?? 0)
          .fold<int>(0, (a, b) => a > b ? a : b);
      final list = await ref.read(ordersRepositoryProvider)
          .messages(widget.orderId, since: lastId);
      if (list.isEmpty) return;
      final existing = _messages.map((m) => (m['id'] as num?)?.toInt() ?? 0).toSet();
      final fresh = list.where((m) => !existing.contains((m['id'] as num?)?.toInt() ?? 0)).toList();
      if (fresh.isEmpty) return;
      if (!mounted) return;
      setState(() => _messages = [..._messages, ...fresh]);
      _scrollToBottom();
    } catch (_) {/* keep last good state */}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
      }
    });
  }

  /// Master-side GPS streaming. Activates when the user is the assigned
  /// master AND the order is in a status where the live map is visible
  /// (on_the_way / arrived). Stops as soon as we leave that window.
  void _maybeToggleGpsTracking() {
    final order = ref.read(_orderProvider(widget.orderId)).valueOrNull;
    final auth = ref.read(authStateProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    if (order == null || user == null) return;
    final isMaster = user.id == order.masterId;
    final shouldTrack = isMaster && _liveMapStatuses.contains(order.status);
    if (shouldTrack && !_gpsActive) {
      _startGpsTracking();
    } else if (!shouldTrack && _gpsActive) {
      _stopGpsTracking();
    }
  }

  Future<void> _startGpsTracking() async {
    if (_gpsActive) return;
    try {
      // Permission flow — geolocator handles iOS, Android, and web (browser
      // prompt). If the user declines we silently keep the map without a
      // master pin; the client just sees the destination.
      final servicesOk = await Geolocator.isLocationServiceEnabled();
      if (!servicesOk) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        return;
      }
      _gpsActive = true;

      // Push an initial position immediately so the map updates fast,
      // then stream updates with a 30 m distance filter to spare battery.
      try {
        final p = await Geolocator.getCurrentPosition();
        await _pushLocation(p.latitude, p.longitude);
      } catch (_) {/* keep streaming */}

      _gpsSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 30,
        ),
      ).listen((p) async {
        await _pushLocation(p.latitude, p.longitude);
      }, onError: (_) {/* swallow */});

      // Belt-and-braces uplink — even when the device is stationary the
      // backend likes a heartbeat so the marker doesn't go stale.
      _gpsTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
        try {
          final p = await Geolocator.getCurrentPosition();
          await _pushLocation(p.latitude, p.longitude);
        } catch (_) {/* ignore */}
      });
    } catch (_) {
      _gpsActive = false;
    }
  }

  Future<void> _pushLocation(double lat, double lng) async {
    try {
      await ref.read(ordersRepositoryProvider).updateMyLocation(lat, lng);
    } catch (_) {/* network errors are fine, next tick will retry */}
  }

  void _stopGpsTracking() {
    _gpsActive = false;
    _gpsTimer?.cancel();
    _gpsTimer = null;
    _gpsSub?.cancel();
    _gpsSub = null;
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scroll.dispose();
    _poll?.cancel();
    _statusPoll?.cancel();
    _sseSub?.cancel();
    _stopGpsTracking();
    super.dispose();
  }

  /// Legacy entry — kept as a thin alias so existing callers (send / build
  /// listener) keep working. The 1-second poll loop calls
  /// [_refreshChatIncremental] directly.
  Future<void> _refreshChat() => _refreshChatIncremental();

  Future<void> _send({String? photoBase64}) async {
    final t = _msgCtrl.text.trim();
    if (t.isEmpty && photoBase64 == null) return;
    if (_sending) return;
    setState(() => _sending = true);
    _msgCtrl.clear();
    try {
      await ref.read(ordersRepositoryProvider).sendMessage(
        widget.orderId,
        text: t.isEmpty ? null : t,
        photoBase64: photoBase64,
      );
      await _refreshChat();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message), backgroundColor: HmColors.danger));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Attach handler — bottom sheet offering Camera (native picker shoots
  /// straight) or Gallery, then base64-encodes and pipes through `_send`.
  Future<void> _attachPhoto() async {
    final src = await showModalBottomSheet<ImageSource?>(
      context: context,
      backgroundColor: HmColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(HmRadius.cardLarge)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 38, height: 4,
              decoration: BoxDecoration(color: HmColors.border2, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded, color: HmColors.accent),
              title: Text(context.l10n.chat_attach_camera),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: HmColors.accent),
              title: Text(context.l10n.chat_attach_gallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ]),
        ),
      ),
    );
    if (src == null) return;
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: src,
        maxWidth: 1600,
        imageQuality: 75,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 8 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.l10n.chat_photo_too_big),
            backgroundColor: HmColors.danger,
          ));
        }
        return;
      }
      final mime = file.mimeType ?? _guessMime(file.name);
      final b64 = base64Encode(bytes);
      await _send(photoBase64: 'data:$mime;base64,$b64');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l10n.chat_photo_failed),
          backgroundColor: HmColors.danger,
        ));
      }
    }
  }

  String _guessMime(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final asyncOrder = ref.watch(_orderProvider(widget.orderId));
    final auth = ref.watch(authStateProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    // Read the cached value even while a poll-driven refetch is in flight —
    // that's what gives us flicker-free real-time updates instead of the
    // "spinner every 5 seconds" you'd get with `asyncOrder.when(loading:)`.
    final order = asyncOrder.valueOrNull;

    return Scaffold(
      backgroundColor: HmColors.bg,
      body: SafeArea(
        child: order != null
            ? _Body(
                order: order,
                user: user,
                messages: _messages,
                scrollCtrl: _scroll,
                msgCtrl: _msgCtrl,
                sending: _sending,
                onSend: () => _send(),
                onAttach: _attachPhoto,
                onAction: () => _refreshAfterAction(),
                onShowDetails: () => _showDetailsSheet(order, user),
              )
            : asyncOrder.when(
                data: (_) => const SizedBox.shrink(),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: HmColors.accent, strokeWidth: 2.4),
                ),
                error: (_, __) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline_rounded, size: 32, color: HmColors.danger),
                      const SizedBox(height: 12),
                      Text(loc.auth_failed_to_load,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: HmColors.text3)),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref.invalidate(_orderProvider(widget.orderId)),
                        style: FilledButton.styleFrom(
                          backgroundColor: HmColors.accent, foregroundColor: Colors.black,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(loc.notif_retry),
                      ),
                    ]),
                  ),
                ),
              ),
      ),
    );
  }

  void _refreshAfterAction() {
    ref.invalidate(_orderProvider(widget.orderId));
    ref.invalidate(_applicationsProvider(widget.orderId));
    _refreshChat();
  }

  void _showDetailsSheet(Order order, dynamic user) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: HmColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(HmRadius.cardLarge)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => _DetailsSheet(
          order: order,
          user: user,
          orderId: widget.orderId,
          scrollCtrl: scrollCtrl,
          onAction: _refreshAfterAction,
        ),
      ),
    );
  }
}

// === Body — header + prompt + messages + input =============================

class _Body extends ConsumerWidget {
  const _Body({
    required this.order,
    required this.user,
    required this.messages,
    required this.scrollCtrl,
    required this.msgCtrl,
    required this.sending,
    required this.onSend,
    required this.onAttach,
    required this.onAction,
    required this.onShowDetails,
  });
  final Order order;
  final dynamic user;
  final List<Map<String, dynamic>> messages;
  final ScrollController scrollCtrl;
  final TextEditingController msgCtrl;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onAction;
  final VoidCallback onShowDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.l10n;
    final isClient = user?.id == order.clientId;

    // The order is "fully closed" from THIS user's perspective when either
    // the order itself reached a terminal state (closed / canceled_*) OR they
    // already left their review on a completed order. In both cases we hide
    // the chat-first UI and show a clean summary page — chat is no longer
    // useful at that point and the static layout reads better.
    final fullyClosed = order.isTerminal ||
        ((order.status == OrderStatus.completed ||
                order.status == OrderStatus.awaitingReview) &&
            (isClient ? order.clientReviewed : order.masterReviewed));

    if (fullyClosed) {
      return _TerminalBody(order: order, user: user, onAction: onAction);
    }

    final chatOpen = _chatActiveStatuses.contains(order.status);
    // Open announcement (status=searching_master): no per-order chat exists
    // — communication happens inside each application thread. Show the
    // applications inbox inline so the client can pick a master without
    // reaching for the "Details" sheet.
    final showInbox = isClient && order.status == OrderStatus.searching;
    // Post-payment inversion: once the callout fee is paid (confirmed and
    // onwards) the work-execution phase begins — at that point the details
    // (address, map, counterparty, photos) are what the user looks at, and
    // chat becomes a side affordance. Before payment (discussion / pending)
    // chat is the primary surface — users are negotiating.
    final inPostPayment = _callAvailableStatuses.contains(order.status);
    final detailsPrimary = chatOpen && inPostPayment;

    return Stack(children: [
      Column(children: [
        _Header(order: order, isClient: isClient),
        _ActionPrompt(
          order: order,
          isClient: isClient,
          ref: ref,
          onAction: onAction,
        ),
        // Live map for on_the_way / arrived stays in the main column so it's
        // always pinned at the top regardless of which body is primary.
        if (_liveMapStatuses.contains(order.status))
          _LiveMapCard(order: order),
        Expanded(
          child: detailsPrimary
              ? _DetailsSheet(
                  order: order,
                  user: user,
                  orderId: order.id,
                  scrollCtrl: scrollCtrl,
                  onAction: onAction,
                  showDragHandle: false,
                )
              : chatOpen
                  ? _MessageStream(
                      order: order,
                      isClient: isClient,
                      user: user,
                      messages: messages,
                      scrollCtrl: scrollCtrl,
                    )
                  : showInbox
                      ? _ApplicationsInbox(orderId: order.id, onAction: onAction)
                      : _DetailsSheet(
                          order: order,
                          user: user,
                          orderId: order.id,
                          scrollCtrl: scrollCtrl,
                          onAction: onAction,
                          showDragHandle: false,
                        ),
        ),
        // Composer renders only when chat is the primary surface — in the
        // post-payment inversion the chat lives behind a floating action.
        if (chatOpen && !detailsPrimary)
          _ChatInput(
            ctrl: msgCtrl,
            sending: sending,
            onSend: onSend,
            onAttach: onAttach,
          ),
      ]),
      // Floating action: chat shortcut in post-payment mode (details inline),
      // details shortcut in pre-payment chat mode (chat inline). No FAB when
      // the body is already showing details by default (no-chat statuses).
      if (detailsPrimary)
        Positioned(
          right: 14,
          bottom: 14,
          child: FloatingActionButton.extended(
            onPressed: () => context.push('/chat/order/${order.id}'),
            backgroundColor: HmColors.accent,
            foregroundColor: Colors.black,
            elevation: 0,
            shape: const StadiumBorder(),
            icon: const Icon(Icons.chat_rounded, size: 16, color: Colors.black),
            label: Text(loc.order_action_discuss,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black)),
          ),
        )
      else if (chatOpen)
        Positioned(
          right: 14,
          bottom: 78,
          child: FloatingActionButton.extended(
            onPressed: onShowDetails,
            backgroundColor: HmColors.surface,
            foregroundColor: HmColors.text,
            elevation: 0,
            shape: StadiumBorder(side: BorderSide(color: HmColors.border2, width: 1)),
            icon: const Icon(Icons.list_alt_rounded, size: 16, color: HmColors.accent),
            label: Text(loc.order_details_btn,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800, color: HmColors.text)),
          ),
        ),
    ]);
  }
}

// === Applications inbox (searching_master, client view) ====================

class _ApplicationsInbox extends ConsumerWidget {
  const _ApplicationsInbox({required this.orderId, required this.onAction});
  final int orderId;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.l10n;
    final asyncApps = ref.watch(_applicationsProvider(orderId));
    return asyncApps.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: HmColors.accent, strokeWidth: 2.4)),
      error: (_, __) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(loc.auth_failed_to_load,
              style: const TextStyle(color: HmColors.danger)),
        ),
      ),
      data: (apps) {
        if (apps.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.inbox_outlined,
                    size: 32, color: HmColors.text5),
                const SizedBox(height: 10),
                Text(loc.order_applications_waiting,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13.5,
                        color: HmColors.text4,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 92),
          itemCount: apps.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: Text(loc.order_applications_title.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 11,
                        color: HmColors.text4,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6)),
              );
            }
            final a = apps[i - 1];
            // Accept is gated on a formal proposal — that's the moment the
            // announcement closes and the client commits to a single master.
            // Until then the inbox card shows only the chat affordance so
            // multiple masters can keep negotiating in parallel.
            final canAccept = a.status == ApplicationStatus.proposed;
            return _AppCard(
              application: a,
              onChat: () => context.push('/chat/application/${a.id}'),
              onAccept: canAccept
                  ? () async {
                      try {
                        await ref
                            .read(applicationsRepositoryProvider)
                            .acceptProposal(a.id);
                        onAction();
                      } on ApiException catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(e.message),
                            backgroundColor: HmColors.danger,
                          ));
                        }
                      }
                    }
                  : null,
            );
          },
        );
      },
    );
  }
}

// === Terminal body (closed / canceled / reviewed orders) ===================

class _TerminalBody extends ConsumerWidget {
  const _TerminalBody({
    required this.order,
    required this.user,
    required this.onAction,
  });
  final Order order;
  final dynamic user;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.l10n;
    final isClient = user?.id == order.clientId;
    final isCanceled = order.status == OrderStatus.canceledByClient ||
        order.status == OrderStatus.canceledByMaster ||
        order.status == OrderStatus.canceledBySystem;
    final myReviewLeft = isClient ? order.clientReviewed : order.masterReviewed;
    final theirReviewLeft = isClient ? order.masterReviewed : order.clientReviewed;
    final canReview = !isCanceled && !myReviewLeft;

    String categoryTitle = loc.order_request_fallback;
    final cat = order.category;
    if (cat is Map<String, dynamic> && cat['slug'] != null) {
      categoryTitle = localizedCategoryName(loc, ServiceCategory.fromJson(cat));
    }

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
        child: Row(children: [
          HmIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            small: true, flat: true,
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go('/orders'),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              isClient ? loc.order_kv_master : loc.order_kv_client,
              style: const TextStyle(
                  fontSize: 13, color: HmColors.text5, letterSpacing: 1.2),
            ),
          ),
          Text('#${order.id}',
              style: const TextStyle(
                  fontSize: 12, color: HmColors.text5,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 28),
          children: [
            _TerminalHero(order: order, isCanceled: isCanceled),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(categoryTitle,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4)),
            ),
            if (order.description != null && order.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(order.description!,
                    style: const TextStyle(
                        fontSize: 14, color: HmColors.text3, height: 1.5)),
              ),
            ],
            if (order.photos.isNotEmpty) ...[
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _Section(title: loc.order_photos_label),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _PhotosGallery(photos: order.photos),
              ),
            ],
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _Section(title: loc.order_kv_address),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _AddressCard(order: order, isClient: isClient),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _Section(
                  title: isClient ? loc.order_kv_master : loc.order_kv_client),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _CounterpartyCard(order: order, isClient: isClient),
            ),
            if (order.agreedPrice != null) ...[
              const SizedBox(height: 18),
              _PriceCard(price: order.agreedPrice!),
            ],
            if (isCanceled && order.cancelReason != null &&
                order.cancelReason!.trim().isNotEmpty) ...[
              const SizedBox(height: 18),
              _CancelReasonCard(reason: order.cancelReason!),
            ],
            if (!isCanceled) ...[
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _Section(title: loc.order_review_section),
              ),
              const SizedBox(height: 8),
              _ReviewSummaryCard(
                myReviewLeft: myReviewLeft,
                theirReviewLeft: theirReviewLeft,
                isClient: isClient,
                canReview: canReview,
                onLeaveReview: () =>
                    context.push('/order/${order.id}/review'),
              ),
            ],
            if (order.statusHistory.isNotEmpty) ...[
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _Section(title: loc.order_timeline_title),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _StatusTimeline(history: order.statusHistory),
              ),
            ],
            if (isClient && order.status == OrderStatus.closed) ...[
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity, height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/order/create'),
                    icon: const Icon(Icons.refresh_rounded,
                        size: 16, color: HmColors.accent),
                    label: Text(loc.order_reorder_btn,
                        style: const TextStyle(
                            color: HmColors.accent,
                            fontWeight: FontWeight.w800)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: HmColors.accentBorder),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ]);
  }
}

class _TerminalHero extends StatelessWidget {
  const _TerminalHero({required this.order, required this.isCanceled});
  final Order order;
  final bool isCanceled;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final color = isCanceled ? HmColors.danger : HmColors.success;
    final bg = isCanceled
        ? const Color(0x14EF4444)
        : const Color(0x1422C55E);
    final border = isCanceled
        ? const Color(0x4DEF4444)
        : const Color(0x4D22C55E);
    final icon = isCanceled
        ? Icons.cancel_rounded
        : (order.status == OrderStatus.closed
            ? Icons.task_alt_rounded
            : Icons.check_circle_rounded);
    final title = isCanceled
        ? loc.order_canceled
        : (order.status == OrderStatus.closed
            ? loc.order_closed_title
            : loc.order_completed_title);
    final at = order.closedAt ?? order.canceledAt ?? order.completedAt;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(HmRadius.cardLarge),
          border: Border.all(color: border),
        ),
        child: Column(children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.18),
            ),
            child: Icon(icon, size: 36, color: color),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: -0.3)),
          if (at != null) ...[
            const SizedBox(height: 4),
            Text(_fmtDate(at),
                style: const TextStyle(
                    fontSize: 12, color: HmColors.text4,
                    fontWeight: FontWeight.w600)),
          ],
        ]),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mn = d.minute.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}, $hh:$mn';
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.price});
  final double price;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
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
          borderRadius: BorderRadius.circular(HmRadius.cardLarge),
          border: Border.all(color: HmColors.accentBorder),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: HmColors.accentSoft),
            child: const Icon(Icons.payments_rounded,
                size: 18, color: HmColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(loc.order_final_price,
                    style: const TextStyle(
                        fontSize: 11,
                        color: HmColors.text4,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0)),
                const SizedBox(height: 2),
                Text('${price.toStringAsFixed(0)} ₼',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: HmColors.accent,
                        letterSpacing: -0.4)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _CancelReasonCard extends StatelessWidget {
  const _CancelReasonCard({required this.reason});
  final String reason;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0x14EF4444),
          borderRadius: BorderRadius.circular(HmRadius.card),
          border: Border.all(color: const Color(0x4DEF4444)),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.order_cancel_reason_label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: HmColors.danger,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0)),
              const SizedBox(height: 4),
              Text(reason,
                  style: const TextStyle(
                      fontSize: 13.5,
                      color: HmColors.text2,
                      height: 1.45)),
            ]),
      ),
    );
  }
}

class _ReviewSummaryCard extends StatelessWidget {
  const _ReviewSummaryCard({
    required this.myReviewLeft,
    required this.theirReviewLeft,
    required this.isClient,
    required this.canReview,
    required this.onLeaveReview,
  });
  final bool myReviewLeft;
  final bool theirReviewLeft;
  final bool isClient;
  final bool canReview;
  final VoidCallback onLeaveReview;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: HmColors.surface,
          borderRadius: BorderRadius.circular(HmRadius.cardLarge),
          border: Border.all(color: HmColors.border2),
        ),
        child: Column(children: [
          _ReviewLine(
            label: loc.order_review_yours,
            done: myReviewLeft,
          ),
          const SizedBox(height: 10),
          _ReviewLine(
            label: isClient
                ? loc.order_review_master
                : loc.order_review_client,
            done: theirReviewLeft,
          ),
          if (canReview) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 46,
              child: FilledButton.icon(
                onPressed: onLeaveReview,
                icon: const Icon(Icons.star_rounded,
                    size: 16, color: Colors.black),
                label: Text(loc.review_leave,
                    style: const TextStyle(color: Colors.black)),
                style: FilledButton.styleFrom(
                  backgroundColor: HmColors.accent,
                  foregroundColor: Colors.black,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({required this.label, required this.done});
  final String label;
  final bool done;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return Row(children: [
      Icon(
        done
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        size: 18,
        color: done ? HmColors.success : HmColors.text5,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(label,
            style: const TextStyle(
                fontSize: 13.5,
                color: HmColors.text2,
                fontWeight: FontWeight.w700)),
      ),
      Text(
        done ? loc.order_review_done : loc.order_review_pending,
        style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: done ? HmColors.success : HmColors.text5),
      ),
    ]);
  }
}

// === Header ================================================================

class _Header extends ConsumerWidget {
  const _Header({required this.order, required this.isClient});
  final Order order;
  final bool isClient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final party = isClient ? order.master : order.client;
    final fn = (party?['first_name'] ?? '').toString();
    final ln = (party?['last_name'] ?? '').toString();
    final name = '$fn $ln'.trim();
    final avatar = party?['avatar_url']?.toString();
    final rating = isClient ? double.tryParse(party?['rating_avg']?.toString() ?? '') : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 10),
      decoration: const BoxDecoration(
        color: HmColors.bg,
        border: Border(bottom: BorderSide(color: HmColors.border2)),
      ),
      child: Row(children: [
        HmIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          small: true,
          flat: true,
          onPressed: () => context.canPop() ? context.pop() : context.go('/orders'),
        ),
        const SizedBox(width: 4),
        if (avatar != null && avatar.isNotEmpty)
          HmAvatar(url: avatar, size: 36, ring: false)
        else
          Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: HmColors.surface2),
            child: const Icon(Icons.person_rounded, size: 18, color: HmColors.text4),
          ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name.isEmpty ? '#${order.id}' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
              const SizedBox(height: 1),
              Row(children: [
                Text('#${order.id}',
                    style: const TextStyle(fontSize: 11, color: HmColors.text5, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                _StatusDot(status: order.status),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    orderStatusLabel(context.l10n, order.status),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: HmColors.text4, fontWeight: FontWeight.w700),
                  ),
                ),
              ]),
            ],
          ),
        ),
        if (rating != null && rating > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: HmColors.accentSoft,
              borderRadius: BorderRadius.circular(HmRadius.pill),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star_rounded, size: 11, color: HmColors.accent),
              const SizedBox(width: 2),
              Text(rating.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w900, color: HmColors.accent)),
            ]),
          ),
        ],
        // In-app call button — shown once the order reaches a callable
        // status (confirmed and later). Phone numbers are never exposed; the
        // call routes through the platform's WebRTC channel.
        if (_callAvailableStatuses.contains(order.status) && party != null) ...[
          const SizedBox(width: 6),
          Material(
            color: HmColors.success,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                final calleeId = (party['id'] as num?)?.toInt();
                if (calleeId == null) return;
                ref.read(callServiceProvider).startOutgoing(
                      orderId: order.id,
                      calleeId: calleeId,
                      calleeName: name.isEmpty ? null : name,
                      calleeAvatar: avatar,
                    );
              },
              child: const SizedBox(
                width: 36, height: 36,
                child: Icon(Icons.phone_rounded, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final OrderStatus status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      OrderStatus.completed || OrderStatus.confirmed || OrderStatus.accepted ||
      OrderStatus.onTheWay || OrderStatus.arrived || OrderStatus.inProgress ||
      OrderStatus.awaitingCompletion => HmColors.success,
      OrderStatus.canceledByClient || OrderStatus.canceledByMaster ||
      OrderStatus.canceledBySystem || OrderStatus.disputed => HmColors.danger,
      _ => HmColors.accent,
    };
    return Container(
      width: 6, height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// === Sticky action prompt =================================================

class _ActionPrompt extends StatelessWidget {
  const _ActionPrompt({
    required this.order,
    required this.isClient,
    required this.ref,
    required this.onAction,
  });
  final Order order;
  final bool isClient;
  final WidgetRef ref;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final body = _buildBody(context, loc);
    final showCancel = _canCancel();
    if (body == null && !showCancel) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: const BoxDecoration(
        color: HmColors.bg,
        border: Border(bottom: BorderSide(color: HmColors.border2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (body != null) body,
          if (showCancel) ...[
            if (body != null) const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () => _cancel(context),
                icon: const Icon(Icons.close_rounded, size: 13, color: HmColors.danger),
                label: Text(loc.order_cancel_btn,
                    style: const TextStyle(
                      fontSize: 12,
                      color: HmColors.danger,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0x55EF4444),
                    )),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Cancel is allowed for both sides during the negotiation and active
  /// work phases. Terminal statuses (completed/closed/canceled_*) and the
  /// master's pending_master state (covered by Decline) are excluded.
  bool _canCancel() {
    if (order.isTerminal) return false;
    if (!isClient && order.status == OrderStatus.pendingMaster) return false;
    return true;
  }

  Future<void> _cancel(BuildContext context) async {
    final reason = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: HmColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(HmRadius.cardLarge)),
      ),
      builder: (_) => const _CancelSheet(),
    );
    if (reason == null) return;
    try {
      await ref.read(ordersRepositoryProvider).cancel(order.id,
          reason: reason.isEmpty ? null : reason);
      onAction();
    } on ApiException catch (e) {
      if (context.mounted) _err(context, e.message);
    }
  }

  Widget? _buildBody(BuildContext context, dynamic loc) {
    // pending_master / searching_master — 24h auto-cancel warning + actions
    if (order.status == OrderStatus.pendingMaster ||
        order.status == OrderStatus.searching) {
      return _PromptStack([
        _Warn24h(isClient: isClient),
        if (!isClient && order.status == OrderStatus.pendingMaster) ...[
          const SizedBox(height: 10),
          _MasterPendingButtons(
            onAccept: () => _masterAccept(context),
            onDecline: () => _masterDecline(context),
          ),
        ],
      ]);
    }
    if (order.status == OrderStatus.discussion) {
      if (isClient) return _Banner(loc.order_banner_discussion);
      return _PrimaryAction(
        icon: Icons.handshake_rounded,
        label: loc.order_action_confirm_work,
        onTap: () => _masterConfirmWork(context),
      );
    }
    if (order.status == OrderStatus.pendingClient) {
      if (!isClient) return _Banner(loc.order_banner_pending_client_master);
      return _ClientProposalPrompt(
        order: order,
        onAccept: () => _clientAcceptProposal(context),
        onReject: () => _clientRejectProposal(context),
      );
    }
    if (order.isInProgress) {
      if (isClient) {
        if (order.status == OrderStatus.awaitingCompletion) {
          return _PrimaryAction(
            icon: Icons.check_circle_rounded,
            label: loc.order_action_mark_complete,
            onTap: () => _updateStatus(context, 'completed'),
            success: true,
          );
        }
        return _Banner(_clientWaitingMessage(order.status, loc));
      }
      // master in_progress steps
      return _MasterAdvanceButtons(
        order: order,
        onAdvance: (next) => _updateStatus(context, next),
      );
    }
    if (order.status == OrderStatus.completed ||
        order.status == OrderStatus.awaitingReview) {
      return _PrimaryAction(
        icon: Icons.star_rounded,
        label: loc.order_leave_review,
        onTap: () => context.push('/order/${order.id}/review'),
      );
    }
    if (order.status == OrderStatus.canceledByClient ||
        order.status == OrderStatus.canceledByMaster ||
        order.status == OrderStatus.canceledBySystem) {
      return _Banner(loc.order_banner_canceled, danger: true);
    }
    return null;
  }

  String _clientWaitingMessage(OrderStatus s, dynamic loc) {
    return switch (s) {
      OrderStatus.confirmed => loc.order_banner_confirmed,
      OrderStatus.accepted => loc.order_banner_confirmed,
      OrderStatus.onTheWay => loc.order_banner_on_the_way_client,
      OrderStatus.arrived => loc.order_banner_arrived,
      OrderStatus.inProgress => loc.order_banner_in_progress,
      _ => loc.order_banner_confirmed,
    };
  }

  // === Action handlers ===

  Future<void> _masterAccept(BuildContext context) async {
    try {
      await ref.read(ordersRepositoryProvider).accept(order.id);
      onAction();
      // After accepting, the master should land in the chat — that's the
      // explicit user request ("after Accept → chat opens"). The order
      // detail page stays one back-press away if they need to propose an
      // arrival time later via the time-picker.
      if (context.mounted) context.push('/chat/order/${order.id}');
    } on ApiException catch (e) {
      if (context.mounted) _err(context, e.message);
    }
  }

  Future<void> _masterDecline(BuildContext context) async {
    final reason = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: HmColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(HmRadius.cardLarge)),
      ),
      builder: (_) => const _CancelSheet(),
    );
    if (reason == null) return;
    try {
      await ref.read(ordersRepositoryProvider).decline(order.id,
          reason: reason.isEmpty ? null : reason);
      onAction();
    } on ApiException catch (e) {
      if (context.mounted) _err(context, e.message);
    }
  }

  Future<void> _masterConfirmWork(BuildContext context) async {
    // The sheet returns a record `({DateTime date})` after the recent
    // price-removal refactor — the caller's signature has to match exactly,
    // otherwise the runtime cast fails silently and `result` is null, which
    // is the exact symptom the master sees ("nothing happens after submit").
    final result = await showModalBottomSheet<({DateTime date})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: HmColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(HmRadius.cardLarge)),
      ),
      builder: (_) => const _ConfirmWorkSheet(),
    );
    if (result == null) return;
    try {
      await ref.read(ordersRepositoryProvider).confirm(order.id,
          agreedDate: result.date);
      onAction();
    } on ApiException catch (e) {
      if (context.mounted) _err(context, e.message);
    }
  }

  Future<void> _clientAcceptProposal(BuildContext context) async {
    // Client confirmation now requires paying the callout fee — show the
    // bottom sheet with card picker. On success the order moves straight to
    // confirmed (no payment-less /confirm path).
    final paid = await showCalloutFeeSheet(context, orderId: order.id);
    if (paid) onAction();
  }

  Future<void> _clientRejectProposal(BuildContext context) async {
    try {
      await ref.read(ordersRepositoryProvider).rejectProposal(order.id);
      onAction();
    } on ApiException catch (e) {
      if (context.mounted) _err(context, e.message);
    }
  }

  Future<void> _updateStatus(BuildContext context, String next) async {
    try {
      await ref.read(ordersRepositoryProvider).updateStatus(order.id, next);
      onAction();
    } on ApiException catch (e) {
      if (context.mounted) _err(context, e.message);
    }
  }

  void _err(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: HmColors.danger));
  }
}

// === Action-prompt building blocks =========================================

class _PromptStack extends StatelessWidget {
  const _PromptStack(this.children);
  final List<Widget> children;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
}

class _Warn24h extends StatelessWidget {
  const _Warn24h({required this.isClient});
  final bool isClient;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0x1FEF4444),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x4DEF4444)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.timer_outlined, size: 14, color: HmColors.danger),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isClient
                ? loc.order_pending_master_24h_warning_client
                : loc.order_pending_master_24h_warning,
            style: const TextStyle(
                fontSize: 11.5, color: HmColors.danger, height: 1.35, fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner(this.text, {this.danger = false});
  final String text;
  final bool danger;
  @override
  Widget build(BuildContext context) {
    final fg = danger ? HmColors.danger : HmColors.accent;
    final bg = danger ? const Color(0x1FEF4444) : HmColors.accentSoft;
    final border = danger ? const Color(0x4DEF4444) : HmColors.accentBorder;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(danger ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            size: 14, color: fg),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 12, color: fg, height: 1.4, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.success = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool success;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: success ? Colors.white : Colors.black),
        label: Text(label,
            style: TextStyle(color: success ? Colors.white : Colors.black)),
        style: FilledButton.styleFrom(
          backgroundColor: success ? HmColors.success : HmColors.accent,
          foregroundColor: success ? Colors.white : Colors.black,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _MasterPendingButtons extends StatelessWidget {
  const _MasterPendingButtons({required this.onAccept, required this.onDecline});
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return Row(children: [
      Expanded(child: SizedBox(
        height: 42,
        child: FilledButton.icon(
          onPressed: onAccept,
          // The user explicitly wanted "Принять" here — after accepting, the
          // discussion phase renders the dedicated "Обсудить" CTA that opens
          // the chat. Conflating the two on one button buried the chat step.
          icon: const Icon(Icons.check_rounded, size: 14, color: Colors.black),
          label: Text(loc.order_action_accept,
              style: const TextStyle(color: Colors.black)),
          style: FilledButton.styleFrom(
            backgroundColor: HmColors.accent,
            foregroundColor: Colors.black,
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
      )),
      const SizedBox(width: 8),
      Expanded(child: SizedBox(
        height: 42,
        child: OutlinedButton.icon(
          onPressed: onDecline,
          icon: const Icon(Icons.close_rounded, size: 14, color: HmColors.danger),
          label: Text(loc.order_action_decline,
              style: const TextStyle(
                  color: HmColors.danger, fontWeight: FontWeight.w800, fontSize: 12)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0x33EF4444)),
            shape: const StadiumBorder(),
          ),
        ),
      )),
    ]);
  }
}

class _ClientProposalPrompt extends StatelessWidget {
  const _ClientProposalPrompt({
    required this.order,
    required this.onAccept,
    required this.onReject,
  });
  final Order order;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: HmColors.accentSoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: HmColors.accentBorder),
        ),
        child: Row(children: [
          const Icon(Icons.handshake_rounded, size: 14, color: HmColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(loc.order_proposal_title,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w900,
                    color: HmColors.accent, letterSpacing: 0.6)),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      Row(children: [
        if (order.agreedPrice != null)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.payments_outlined, size: 14, color: HmColors.text4),
              const SizedBox(width: 4),
              Text('${order.agreedPrice!.toStringAsFixed(0)} AZN',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: HmColors.text)),
            ]),
          ),
        if (order.agreedDate != null)
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.event_rounded, size: 14, color: HmColors.text4),
            const SizedBox(width: 4),
            Text(_formatDate(order.agreedDate!),
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700, color: HmColors.text)),
          ]),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: SizedBox(
          height: 42,
          child: FilledButton.icon(
            onPressed: onAccept,
            icon: const Icon(Icons.check_rounded, size: 14, color: Colors.black),
            label: Text(loc.order_action_accept_proposal,
                style: const TextStyle(color: Colors.black)),
            style: FilledButton.styleFrom(
              backgroundColor: HmColors.accent,
              foregroundColor: Colors.black,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        )),
        const SizedBox(width: 8),
        Expanded(child: SizedBox(
          height: 42,
          child: OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.close_rounded, size: 14, color: HmColors.danger),
            label: Text(loc.order_action_reject_proposal,
                style: const TextStyle(
                    color: HmColors.danger, fontWeight: FontWeight.w800, fontSize: 12)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0x33EF4444)),
              shape: const StadiumBorder(),
            ),
          ),
        )),
      ]),
    ]);
  }
}

class _MasterAdvanceButtons extends StatelessWidget {
  const _MasterAdvanceButtons({required this.order, required this.onAdvance});
  final Order order;
  final void Function(String nextStatus) onAdvance;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final next = switch (order.status) {
      OrderStatus.confirmed || OrderStatus.accepted =>
          ('on_the_way', loc.order_action_on_the_way, false),
      OrderStatus.onTheWay => ('arrived', loc.order_action_arrived, false),
      OrderStatus.arrived => ('in_progress', loc.order_action_start_work, false),
      OrderStatus.inProgress => ('completed', loc.order_action_mark_complete, true),
      OrderStatus.awaitingCompletion =>
          (null, loc.order_banner_awaiting_completion_master, false),
      _ => (null, '', false),
    };

    final showRoute = _routeVisibleStatuses.contains(order.status);
    final showStatusBtn = next.$1 != null;

    if (!showRoute && !showStatusBtn) {
      return _Banner(next.$2);
    }

    return Column(children: [
      if (showRoute) ...[
        SizedBox(
          width: double.infinity,
          height: 42,
          child: OutlinedButton.icon(
            onPressed: () => _showNavigators(context, order),
            icon: const Icon(Icons.navigation_rounded, size: 14, color: HmColors.success),
            label: Text(loc.order_build_route,
                style: const TextStyle(color: HmColors.success, fontWeight: FontWeight.w800, fontSize: 12)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0x4D22C55E)),
              shape: const StadiumBorder(),
            ),
          ),
        ),
        if (showStatusBtn) const SizedBox(height: 8),
      ],
      if (showStatusBtn)
        SizedBox(
          width: double.infinity,
          height: 44,
          child: FilledButton.icon(
            onPressed: () => onAdvance(next.$1!),
            icon: Icon(_iconFor(next.$1!), size: 16,
                color: next.$3 ? Colors.white : Colors.black),
            label: Text(next.$2,
                style: TextStyle(color: next.$3 ? Colors.white : Colors.black)),
            style: FilledButton.styleFrom(
              backgroundColor: next.$3 ? HmColors.success : HmColors.accent,
              foregroundColor: next.$3 ? Colors.white : Colors.black,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ),
    ]);
  }

  IconData _iconFor(String s) => switch (s) {
    'on_the_way' => Icons.directions_run_rounded,
    'arrived' => Icons.location_on_rounded,
    'in_progress' => Icons.play_arrow_rounded,
    'completed' => Icons.check_circle_rounded,
    _ => Icons.arrow_forward_rounded,
  };

  void _showNavigators(BuildContext context, Order order) async {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    if (isAndroid) {
      final lat = order.latitude;
      final lng = order.longitude;
      final addr = order.fullAddress ?? order.address ?? '';
      final geoUri = (lat != null && lng != null)
          ? 'geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(addr)})'
          : 'geo:0,0?q=${Uri.encodeComponent(addr)}';
      try {
        if (await launchUrl(Uri.parse(geoUri), mode: LaunchMode.externalApplication)) return;
      } catch (_) {}
    }
    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: HmColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(HmRadius.cardLarge)),
      ),
      builder: (_) => _NavigationSheet(order: order),
    );
  }
}

// === Message stream =======================================================

class _MessageStream extends StatelessWidget {
  const _MessageStream({
    required this.order,
    required this.isClient,
    required this.user,
    required this.messages,
    required this.scrollCtrl,
  });
  final Order order;
  final bool isClient;
  final dynamic user;
  final List<Map<String, dynamic>> messages;
  final ScrollController scrollCtrl;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.chat_bubble_outline_rounded, size: 28, color: HmColors.text5),
            const SizedBox(height: 10),
            Text(loc.chat_empty_title,
                style: const TextStyle(
                    fontSize: 13, color: HmColors.text4, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
    }
    final myId = user?.id ?? -1;
    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final m = messages[i];
        final senderId = (m['sender_id'] as num?)?.toInt() ?? 0;
        final mine = senderId == myId;
        final text = m['text']?.toString() ?? '';
        final photo = m['photo_url']?.toString();
        final thumb = m['photo_thumb_url']?.toString() ?? photo;
        final created = DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now();
        final sys = _parseSystem(text);
        if (sys != null) return _SystemCard(payload: sys, time: created);
        return _Bubble(
          text: text,
          mine: mine,
          time: created,
          photoUrl: photo,
          photoThumbUrl: thumb,
        );
      },
    );
  }

  /// Site sends rich events as JSON-encoded text:
  /// `{"_type":"work_started","duration":120,"end_time":"15:30"}`
  Map<String, dynamic>? _parseSystem(String text) {
    if (!text.startsWith('{')) return null;
    try {
      final decoded = const JsonDecoder().convert(text);
      if (decoded is Map<String, dynamic> && decoded['_type'] != null) return decoded;
    } catch (_) {}
    return null;
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.mine,
    required this.time,
    this.photoUrl,
    this.photoThumbUrl,
  });
  final String text;
  final bool mine;
  final DateTime time;
  final String? photoUrl;
  final String? photoThumbUrl;
  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final hasText = text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
              decoration: BoxDecoration(
                color: mine ? HmColors.accent : HmColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(mine ? 16 : 4),
                  bottomRight: Radius.circular(mine ? 4 : 16),
                ),
                border: mine ? null : Border.all(color: HmColors.border2),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasPhoto)
                    GestureDetector(
                      onTap: () => _openPhoto(context, photoUrl!),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 240, minWidth: 200),
                        child: Image.network(
                          _resolveUrl(photoThumbUrl ?? photoUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 120,
                            color: HmColors.surface2,
                            alignment: Alignment.center,
                            child: const Icon(Icons.image_not_supported_outlined,
                                color: HmColors.text5, size: 24),
                          ),
                        ),
                      ),
                    ),
                  if (hasText || !hasPhoto)
                    Padding(
                      padding: EdgeInsets.fromLTRB(12, hasPhoto ? 8 : 8, 12, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasText)
                            Text(text,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: mine ? Colors.black : HmColors.text2,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                )),
                          if (hasText) const SizedBox(height: 2),
                          Text(_formatTime(time),
                              style: TextStyle(
                                  fontSize: 9.5,
                                  color: mine ? Colors.black54 : HmColors.text5,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(HmRadius.pill),
                        ),
                        child: Text(_formatTime(time),
                            style: const TextStyle(
                                fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPhoto(BuildContext context, String url) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _ChatPhotoLightbox(url: _resolveUrl(url)),
    ));
  }
}

class _ChatPhotoLightbox extends StatelessWidget {
  const _ChatPhotoLightbox({required this.url});
  final String url;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        InteractiveViewer(
          child: Center(
            child: Image.network(url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_rounded, size: 64, color: Colors.white24)),
          ),
        ),
        Positioned(
          top: 12, left: 12,
          child: SafeArea(
            child: HmIconButton(
              icon: Icons.close_rounded,
              small: true,
              flat: true,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ]),
    );
  }
}

String _resolveUrl(String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  if (url.startsWith('/')) return 'https://itez.app$url';
  return url;
}

// === Live tracking map =====================================================

/// Map card shown to BOTH sides while the master is on_the_way / arrived.
/// Renders the destination as a yellow pin and the master's current position
/// (from `master.master_profile.current_lat/lng`) as a green marker. The
/// outer order polling refreshes the master's coordinates every 5 s, so the
/// pin moves on its own — no extra plumbing here, just a re-render on data
/// change.
class _LiveMapCard extends StatelessWidget {
  const _LiveMapCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final dest = _destination(order);
    final master = _masterPos(order);

    if (dest == null && master == null) {
      // Nothing to show — both sides lack coordinates. Quiet fallback.
      return const SizedBox.shrink();
    }

    final center = master ?? dest!;
    final markers = <Marker>[
      if (dest != null)
        Marker(
          point: dest,
          width: 36, height: 36,
          alignment: Alignment.topCenter,
          child: const Icon(Icons.location_on_rounded,
              color: HmColors.accent, size: 30,
              shadows: [Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 2))]),
        ),
      if (master != null)
        Marker(
          point: master,
          width: 32, height: 32,
          alignment: Alignment.center,
          child: Container(
            decoration: BoxDecoration(
              color: HmColors.success,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(color: Color(0x6622C55E), blurRadius: 12, spreadRadius: 2),
              ],
            ),
            child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 14),
          ),
        ),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      height: 200,
      decoration: BoxDecoration(
        color: HmColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HmColors.border2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: master != null && dest != null
                ? _zoomForBounds(master, dest)
                : 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'az.gasimov.master',
              maxZoom: 18,
            ),
            // Straight line so it's obvious how far the master is.
            if (master != null && dest != null)
              PolylineLayer(polylines: [
                Polyline(
                  points: [master, dest],
                  color: HmColors.accent.withOpacity(0.8),
                  strokeWidth: 3,
                  pattern: StrokePattern.dashed(segments: const [10, 6]),
                ),
              ]),
            MarkerLayer(markers: markers),
          ],
        ),
        // Status strip top-left
        Positioned(
          top: 8, left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(HmRadius.pill),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                    color: HmColors.success, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                order.status == OrderStatus.arrived
                    ? loc.order_live_map_arrived
                    : loc.order_live_map_on_the_way,
                style: const TextStyle(
                    fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.6),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  LatLng? _destination(Order o) {
    if (o.latitude != null && o.longitude != null) {
      return LatLng(o.latitude!, o.longitude!);
    }
    return null;
  }

  LatLng? _masterPos(Order o) {
    final mp = o.master?['master_profile'];
    if (mp is Map<String, dynamic>) {
      final lat = double.tryParse(mp['current_lat']?.toString() ?? '');
      final lng = double.tryParse(mp['current_lng']?.toString() ?? '');
      if (lat != null && lng != null) return LatLng(lat, lng);
    }
    return null;
  }

  /// Crude bounds-zoom heuristic — enough to show both pins comfortably
  /// without dragging in a second package just for fitBounds.
  double _zoomForBounds(LatLng a, LatLng b) {
    final dLat = (a.latitude - b.latitude).abs();
    final dLng = (a.longitude - b.longitude).abs();
    final span = dLat > dLng ? dLat : dLng;
    if (span < 0.005) return 16;
    if (span < 0.02) return 14;
    if (span < 0.05) return 13;
    if (span < 0.1) return 12;
    if (span < 0.3) return 11;
    return 10;
  }
}

class _SystemCard extends StatelessWidget {
  const _SystemCard({required this.payload, required this.time});
  final Map<String, dynamic> payload;
  final DateTime time;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final type = payload['_type']?.toString() ?? '';
    final (icon, label, info) = _render(type, payload, loc);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: HmColors.accentSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HmColors.accentBorder),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: HmColors.accent),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w800, color: HmColors.accent)),
                if (info != null && info.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(info,
                      style: const TextStyle(
                          fontSize: 11, color: HmColors.text2, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
            const SizedBox(width: 6),
            Text(_formatTime(time),
                style: const TextStyle(
                    fontSize: 9.5, color: HmColors.text5, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  (IconData, String, String?) _render(String type, Map<String, dynamic> p, dynamic loc) {
    switch (type) {
      case 'proposal':
        final price = p['price'];
        final date = p['date'];
        final info = [
          if (price != null) '$price AZN',
          if (date != null) date.toString(),
        ].join(' · ');
        return (Icons.handshake_rounded, loc.chat_sys_proposal, info);
      case 'confirmed':
        return (Icons.check_circle_rounded, loc.chat_sys_confirmed, null);
      case 'rejected':
        return (Icons.refresh_rounded, loc.chat_sys_rejected, null);
      case 'work_started':
        final dur = p['duration'];
        return (Icons.construction_rounded, loc.chat_sys_work_started,
            dur != null ? '~$dur min' : null);
      case 'callout_paid':
        final amount = p['amount'];
        final currency = p['currency']?.toString() ?? 'AZN';
        return (Icons.payments_rounded, loc.chat_sys_callout_paid,
            amount != null ? '$amount $currency' : null);
      default:
        // Don't leak the raw `_type` to users — show a generic system label.
        return (Icons.info_outline_rounded, loc.chat_sys_default, null);
    }
  }
}

class _ChatLockedPlaceholder extends StatelessWidget {
  const _ChatLockedPlaceholder({required this.order, required this.isClient});
  final Order order;
  final bool isClient;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_outline_rounded, size: 28, color: HmColors.text5),
          const SizedBox(height: 10),
          Text(
            order.isTerminal ? loc.chat_closed : loc.chat_locked,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: HmColors.text4, fontWeight: FontWeight.w600),
          ),
        ]),
      ),
    );
  }
}

// === Chat input ============================================================

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.ctrl,
    required this.sending,
    required this.onSend,
    required this.onAttach,
  });
  final TextEditingController ctrl;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return Container(
      padding: EdgeInsets.fromLTRB(10, 8, 10, 8 + MediaQuery.of(context).viewInsets.bottom * 0),
      decoration: const BoxDecoration(
        color: HmColors.bg,
        border: Border(top: BorderSide(color: HmColors.border2)),
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          Material(
            color: HmColors.surface,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: sending ? null : onAttach,
              customBorder: const CircleBorder(),
              child: Container(
                width: 42, height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: HmColors.border2),
                ),
                child: const Icon(Icons.add_photo_alternate_outlined,
                    size: 18, color: HmColors.accent),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: HmColors.surface,
                borderRadius: BorderRadius.circular(HmRadius.pill),
                border: Border.all(color: HmColors.border2),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: TextField(
                controller: ctrl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                minLines: 1,
                maxLines: 4,
                style: const TextStyle(fontSize: 14, color: HmColors.text),
                decoration: InputDecoration(
                  hintText: loc.chat_placeholder,
                  hintStyle: const TextStyle(color: HmColors.text5, fontSize: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: HmColors.accent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: sending ? null : onSend,
              customBorder: const CircleBorder(),
              child: Container(
                width: 42, height: 42,
                alignment: Alignment.center,
                child: sending
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.black),
                      )
                    : const Icon(Icons.arrow_upward_rounded,
                        color: Colors.black, size: 18),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// === Details bottom-sheet =================================================

class _DetailsSheet extends ConsumerWidget {
  const _DetailsSheet({
    required this.order,
    required this.user,
    required this.orderId,
    required this.scrollCtrl,
    required this.onAction,
    this.showDragHandle = true,
  });
  final Order order;
  final dynamic user;
  final int orderId;
  final ScrollController scrollCtrl;
  final VoidCallback onAction;
  /// `true` for the bottom-sheet variant (drag handle on top); `false` when the
  /// same body is rendered inline inside the order page (no handle needed).
  final bool showDragHandle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.l10n;
    final isClient = user?.id == order.clientId;
    final asyncApps = ref.watch(_applicationsProvider(orderId));

    String categoryTitle = loc.order_request_fallback;
    final cat = order.category;
    if (cat is Map<String, dynamic> && cat['slug'] != null) {
      categoryTitle = localizedCategoryName(loc, ServiceCategory.fromJson(cat));
    }

    return Column(children: [
      if (showDragHandle)
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Container(
            width: 38, height: 4,
            decoration: BoxDecoration(color: HmColors.border2, borderRadius: BorderRadius.circular(2)),
          ),
        ),
      Expanded(
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text(categoryTitle,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
            if (order.description != null && order.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(order.description!,
                  style: const TextStyle(fontSize: 14, color: HmColors.text3, height: 1.5)),
            ],
            if (order.photos.isNotEmpty) ...[
              const SizedBox(height: 18),
              _Section(title: loc.order_photos_label),
              const SizedBox(height: 8),
              _PhotosGallery(photos: order.photos),
            ],
            const SizedBox(height: 18),
            _Section(title: loc.order_kv_address),
            const SizedBox(height: 8),
            _AddressCard(order: order, isClient: isClient),
            if (_callAvailableStatuses.contains(order.status)) ...[
              const SizedBox(height: 12),
              _InAppCallRow(order: order, isClient: isClient),
            ],
            const SizedBox(height: 18),
            _Section(title: isClient ? loc.order_kv_master : loc.order_kv_client),
            const SizedBox(height: 8),
            _CounterpartyCard(order: order, isClient: isClient),
            // Applications panel — client view, before a master is picked.
            if (isClient && order.isOpenAnnouncement) ...[
              const SizedBox(height: 18),
              _Section(title: loc.order_applications_title),
              asyncApps.when(
                data: (apps) {
                  if (apps.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(loc.order_applications_waiting,
                            style: const TextStyle(color: HmColors.text5, fontSize: 12.5)),
                      ),
                    );
                  }
                  return Column(
                    children: apps
                        .map((a) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: _AppCard(
                                application: a,
                                onChat: () => context.push('/chat/application/${a.id}'),
                                onAccept: a.status == ApplicationStatus.proposed
                                    ? () => _acceptProposal(context, ref, a.id)
                                    : null,
                              ),
                            ))
                        .toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(color: HmColors.accent)),
                ),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(loc.auth_failed_to_load,
                      style: const TextStyle(color: HmColors.danger)),
                ),
              ),
            ],
            // Cancel CTA
            if ((order.isOpenAnnouncement || order.isInProgress) &&
                !(!isClient && order.status == OrderStatus.pendingMaster)) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () => _cancel(context, ref),
                  icon: const Icon(Icons.cancel_outlined, size: 14, color: HmColors.danger),
                  label: Text(loc.order_cancel_btn,
                      style: const TextStyle(
                          color: HmColors.danger, fontWeight: FontWeight.w800)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0x33EF4444)),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ],
            // Status timeline
            if (order.statusHistory.isNotEmpty) ...[
              const SizedBox(height: 22),
              _Section(title: loc.order_timeline_title),
              const SizedBox(height: 8),
              _StatusTimeline(history: order.statusHistory),
            ],
          ],
        ),
      ),
    ]);
  }

  Future<void> _acceptProposal(BuildContext context, WidgetRef ref, int applicationId) async {
    try {
      await ref.read(applicationsRepositoryProvider).acceptProposal(applicationId);
      onAction();
      if (context.mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: HmColors.danger));
      }
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final reason = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: HmColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(HmRadius.cardLarge)),
      ),
      builder: (_) => const _CancelSheet(),
    );
    if (reason == null) return;
    try {
      await ref.read(ordersRepositoryProvider).cancel(orderId,
          reason: reason.isEmpty ? null : reason);
      onAction();
      if (context.mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: HmColors.danger));
      }
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Text(title.toUpperCase(),
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w900, color: HmColors.text4, letterSpacing: 1.2));
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.order, required this.isClient});
  final Order order;
  final bool isClient;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final addr = order.fullAddress ?? order.address ?? '—';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: HmColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HmColors.border2),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.location_on_rounded, size: 16, color: HmColors.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(addr,
              style: const TextStyle(
                  fontSize: 13.5, color: HmColors.text2, height: 1.4, fontWeight: FontWeight.w600)),
        ),
        if (!isClient)
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.copy_rounded, size: 14, color: HmColors.text4),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: addr));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(loc.order_address_copied),
                duration: const Duration(seconds: 2),
              ));
            },
          ),
      ]),
    );
  }
}

class _InAppCallRow extends ConsumerWidget {
  const _InAppCallRow({required this.order, required this.isClient});
  final Order order;
  final bool isClient;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.l10n;
    final party = isClient ? order.master : order.client;
    if (party == null) return const SizedBox.shrink();
    final fn = (party['first_name'] ?? '').toString();
    final ln = (party['last_name'] ?? '').toString();
    final name = '$fn $ln'.trim();
    final calleeId = (party['id'] as num?)?.toInt();
    if (calleeId == null) return const SizedBox.shrink();
    return Material(
      color: HmColors.success,
      borderRadius: BorderRadius.circular(HmRadius.pill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ref.read(callServiceProvider).startOutgoing(
              orderId: order.id,
              calleeId: calleeId,
              calleeName: name,
              calleeAvatar: party['avatar_url']?.toString(),
            ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.phone_in_talk_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              name.isNotEmpty ? '${loc.order_phone_call} · $name' : loc.order_phone_call,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ]),
        ),
      ),
    );
  }
}

class _CounterpartyCard extends StatelessWidget {
  const _CounterpartyCard({required this.order, required this.isClient});
  final Order order;
  final bool isClient;
  @override
  Widget build(BuildContext context) {
    final party = isClient ? order.master : order.client;
    if (party == null) return const SizedBox.shrink();
    final fn = (party['first_name'] ?? '').toString();
    final ln = (party['last_name'] ?? '').toString();
    final name = '$fn $ln'.trim();
    final avatar = party['avatar_url']?.toString();
    final rating = isClient ? double.tryParse(party['rating_avg']?.toString() ?? '') : null;
    final partyId = (party['id'] as num?)?.toInt();
    final route = partyId == null ? null : (isClient ? '/master/$partyId' : '/user/$partyId');

    return Material(
      color: HmColors.bg,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: route == null ? null : () => context.push(route),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HmColors.border2),
          ),
          child: Row(children: [
            if (avatar != null && avatar.isNotEmpty)
              HmAvatar(url: avatar, size: 44, ring: true)
            else
              Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: HmColors.surface2),
                child: Icon(
                    isClient ? Icons.person_rounded : Icons.person_outline_rounded,
                    color: HmColors.text4, size: 20),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name.isEmpty ? '—' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: HmColors.text)),
            ),
            if (rating != null && rating > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: HmColors.accentSoft,
                  borderRadius: BorderRadius.circular(HmRadius.pill),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.star_rounded, size: 11, color: HmColors.accent),
                  const SizedBox(width: 3),
                  Text(rating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w900, color: HmColors.accent)),
                ]),
              ),
            if (route != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 16, color: HmColors.text5),
            ],
          ]),
        ),
      ),
    );
  }
}

class _PhotosGallery extends StatelessWidget {
  const _PhotosGallery({required this.photos});
  final List<Map<String, dynamic>> photos;
  @override
  Widget build(BuildContext context) {
    final urls = photos
        .map((p) => p['url']?.toString())
        .whereType<String>()
        .toList();
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
            child: Image.network(urls[i], width: 96, height: 96, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 96, height: 96, color: HmColors.surface2,
                  child: const Icon(Icons.image_not_supported_outlined,
                      size: 18, color: HmColors.text5),
                )),
          ),
        ),
      ),
    );
  }

  void _openLightbox(BuildContext context, List<String> urls, int startIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _PhotoLightbox(urls: urls, initialIndex: startIndex),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }
}

/// Full-screen swipeable photo viewer. Pinch / double-tap to zoom, horizontal
/// swipe between photos, swipe-down or tap the close icon to dismiss.
class _PhotoLightbox extends StatefulWidget {
  const _PhotoLightbox({required this.urls, required this.initialIndex});
  final List<String> urls;
  final int initialIndex;
  @override
  State<_PhotoLightbox> createState() => _PhotoLightboxState();
}

class _PhotoLightboxState extends State<_PhotoLightbox> {
  late final PageController _ctrl = PageController(initialPage: widget.initialIndex);
  late int _current = widget.initialIndex;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Stack(children: [
          // Photo pager
          GestureDetector(
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0).abs() > 600) Navigator.of(context).pop();
            },
            child: PageView.builder(
              controller: _ctrl,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) => InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    widget.urls[i],
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64),
                    loadingBuilder: (_, child, p) {
                      if (p == null) return child;
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    },
                  ),
                ),
              ),
            ),
          ),
          // Top bar: counter + close
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0xCC000000), Color(0x00000000)],
                ),
              ),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                if (widget.urls.length > 1)
                  Text('${_current + 1} / ${widget.urls.length}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  const _AppCard({required this.application, required this.onChat, this.onAccept});
  final OrderApplication application;
  final VoidCallback onChat;
  final VoidCallback? onAccept;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final master = application.master;
    // Build the display name from first_name + last_name; fall back to
    // full_name if the API returned the accessor explicitly. Never show
    // the literal word "Master" — better empty than impersonal.
    final fn = master?['first_name']?.toString() ?? '';
    final ln = master?['last_name']?.toString() ?? '';
    final composedName = '$fn $ln'.trim();
    final name = composedName.isNotEmpty
        ? composedName
        : (master?['full_name']?.toString() ?? '');
    final avatar = master?['avatar_url']?.toString();
    final rating = master?['rating_avg']?.toString() ?? '0.0';
    final cats = (master?['categories'] as List?) ?? const [];
    final specialties = cats
        .map((c) => (c as Map?)?['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .join(' · ');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HmColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HmColors.border2),
      ),
      child: Column(children: [
        Row(children: [
          HmAvatar(url: avatar, size: 36, ring: true),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name.isEmpty ? '#${application.masterId}' : name,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
              if (specialties.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(specialties,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: HmColors.text4, fontWeight: FontWeight.w600)),
              ],
              Row(children: [
                const Icon(Icons.star_rounded, size: 11, color: HmColors.accent),
                const SizedBox(width: 3),
                Text(rating,
                    style: const TextStyle(
                        fontSize: 11, color: HmColors.accent, fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
                Text(applicationStatusLabel(loc, application.status),
                    style: const TextStyle(fontSize: 10.5, color: HmColors.text5)),
              ]),
            ]),
          ),
          if (application.proposedPrice != null)
            Text('${application.proposedPrice!.toStringAsFixed(0)} AZN',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w900, color: HmColors.accent)),
        ]),
        if (application.message != null && application.message!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(application.message!,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: HmColors.text3, height: 1.4)),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onChat,
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 12),
              label: Text(loc.order_chat_btn, style: const TextStyle(fontSize: 11.5)),
              style: OutlinedButton.styleFrom(
                foregroundColor: HmColors.text,
                side: const BorderSide(color: HmColors.border2),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          if (onAccept != null) ...[
            const SizedBox(width: 6),
            Expanded(
              child: FilledButton.icon(
                onPressed: onAccept,
                icon: const Icon(Icons.check_rounded, size: 12, color: Colors.black),
                label: Text(loc.order_accept_btn,
                    style: const TextStyle(color: Colors.black, fontSize: 11.5)),
                style: FilledButton.styleFrom(
                  backgroundColor: HmColors.accent,
                  foregroundColor: Colors.black,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.history});
  final List<Map<String, dynamic>> history;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final items = [...history];
    // Sort by the auto-increment id when available — it's monotonic, so it
    // breaks ties when two transitions land in the same created_at second
    // (which happens during the callout-fee flow). Falls back to created_at
    // for legacy rows that don't carry an id.
    items.sort((a, b) {
      final ia = (a['id'] as num?)?.toInt() ?? 0;
      final ib = (b['id'] as num?)?.toInt() ?? 0;
      if (ia != ib) return ib.compareTo(ia);
      final da = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(0);
      final db = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(0);
      return db.compareTo(da);
    });
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      decoration: BoxDecoration(
        color: HmColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HmColors.border2),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final i = e.key;
          final entry = e.value;
          final statusKey = entry['status']?.toString();
          final note = entry['note']?.toString();
          final created = DateTime.tryParse(entry['created_at']?.toString() ?? '');
          final status = _statusFromKey(statusKey);
          // `pending_payment` in history is shown as "payment received" — by
          // the time the row is rendered the transition has already been
          // followed by either `confirmed` (success) or `pending_client`
          // (timeout rollback), so it's not ambiguous to label it as the
          // actual money-movement event.
          final label = statusKey == 'pending_payment'
              ? loc.order_timeline_payment_received
              : (status != null ? orderStatusLabel(loc, status) : (statusKey ?? '—'));
          return IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(children: [
                Container(
                  width: 8, height: 8, margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                      color: HmColors.accent, shape: BoxShape.circle),
                ),
                if (i < items.length - 1)
                  Container(
                    width: 2,
                    constraints: const BoxConstraints(minHeight: 22),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: HmColors.border2,
                  ),
              ]),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(label,
                              style: const TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w800)),
                        ),
                        if (created != null)
                          Text(_formatShort(created),
                              style: const TextStyle(
                                  fontSize: 10.5, color: HmColors.text5, fontWeight: FontWeight.w600)),
                      ]),
                      if (note != null && note.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(note,
                            style: const TextStyle(fontSize: 11, color: HmColors.text4)),
                      ],
                    ],
                  ),
                ),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }

  OrderStatus? _statusFromKey(String? key) {
    if (key == null) return null;
    return switch (key) {
      'draft' => OrderStatus.draft,
      'new' => OrderStatus.newOrder,
      'searching_master' => OrderStatus.searching,
      'pending_master' => OrderStatus.pendingMaster,
      'discussion' => OrderStatus.discussion,
      'pending_client' => OrderStatus.pendingClient,
      'pending_payment' => OrderStatus.pendingPayment,
      'confirmed' => OrderStatus.confirmed,
      'accepted' => OrderStatus.accepted,
      'on_the_way' => OrderStatus.onTheWay,
      'arrived' => OrderStatus.arrived,
      'in_progress' => OrderStatus.inProgress,
      'awaiting_completion' => OrderStatus.awaitingCompletion,
      'completed' => OrderStatus.completed,
      'awaiting_review' => OrderStatus.awaitingReview,
      'canceled_by_client' => OrderStatus.canceledByClient,
      'canceled_by_master' => OrderStatus.canceledByMaster,
      'canceled_by_system' => OrderStatus.canceledBySystem,
      'disputed' => OrderStatus.disputed,
      'closed' => OrderStatus.closed,
      _ => null,
    };
  }
}

// === Cancel sheet =========================================================

class _CancelSheet extends StatefulWidget {
  const _CancelSheet();
  @override
  State<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<_CancelSheet> {
  final _ctrl = TextEditingController();
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Container(
          width: 38, height: 4,
          decoration: BoxDecoration(color: HmColors.border2, borderRadius: BorderRadius.circular(2)),
        )),
        const SizedBox(height: 14),
        Row(children: [
          const Icon(Icons.cancel_outlined, size: 20, color: HmColors.danger),
          const SizedBox(width: 8),
          Text(loc.order_cancel_confirm_title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
        ]),
        const SizedBox(height: 6),
        Text(loc.order_cancel_confirm_body,
            style: const TextStyle(fontSize: 13, color: HmColors.text4, height: 1.4)),
        const SizedBox(height: 14),
        TextField(
          controller: _ctrl,
          minLines: 3, maxLines: 5, maxLength: 500,
          decoration: InputDecoration(
            labelText: loc.order_cancel_reason,
            hintText: loc.order_cancel_reason_hint,
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: HmColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: HmColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: HmColors.accentBorder, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, null),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: HmColors.border2),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(loc.order_cancel_keep,
                  style: const TextStyle(color: HmColors.text3, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
              icon: const Icon(Icons.cancel_rounded, size: 16, color: Colors.white),
              label: Text(loc.order_cancel_btn, style: const TextStyle(color: Colors.white)),
              style: FilledButton.styleFrom(
                backgroundColor: HmColors.danger, foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

// === Confirm work sheet ===================================================

class _ConfirmWorkSheet extends StatefulWidget {
  const _ConfirmWorkSheet();
  @override
  State<_ConfirmWorkSheet> createState() => _ConfirmWorkSheetState();
}

class _ConfirmWorkSheetState extends State<_ConfirmWorkSheet> {
  DateTime? _date;
  TimeOfDay? _time;
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: HmColors.accent,
            onPrimary: Colors.black,
            surface: HmColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: HmColors.accent,
            onPrimary: Colors.black,
            surface: HmColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final ready = _date != null && _time != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Container(
          width: 38, height: 4,
          decoration: BoxDecoration(color: HmColors.border2, borderRadius: BorderRadius.circular(2)),
        )),
        const SizedBox(height: 14),
        Row(children: [
          const Icon(Icons.handshake_rounded, size: 18, color: HmColors.accent),
          const SizedBox(width: 8),
          Text(loc.order_action_confirm_work,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
        ]),
        const SizedBox(height: 6),
        Text(loc.order_confirm_work_hint,
            style: const TextStyle(fontSize: 12.5, color: HmColors.text4, height: 1.4)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _PickerTile(icon: Icons.event_rounded, label: loc.order_confirm_work_date,
              value: _date == null ? '—' : '${_date!.day}.${_date!.month}.${_date!.year}',
              onTap: _pickDate)),
          const SizedBox(width: 8),
          Expanded(child: _PickerTile(icon: Icons.access_time_rounded, label: loc.order_confirm_work_time,
              value: _time == null ? '—' : _time!.format(context), onTap: _pickTime)),
        ]),
        const SizedBox(height: 10),
        // Цена работ обсуждается в чате — платформа не запрашивает её здесь.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: HmColors.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HmColors.border),
          ),
          child: Row(children: [
            const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: HmColors.text4),
            const SizedBox(width: 8),
            Expanded(
              child: Text(loc.order_price_via_chat_hint,
                  style: const TextStyle(fontSize: 12.5, color: HmColors.text4, height: 1.35)),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, height: 48,
          child: FilledButton.icon(
            onPressed: !ready ? null : () {
              final dt = DateTime(_date!.year, _date!.month, _date!.day,
                  _time!.hour, _time!.minute);
              Navigator.pop(context, (date: dt));
            },
            icon: const Icon(Icons.check_rounded, size: 16, color: Colors.black),
            label: Text(loc.order_confirm_work_send,
                style: const TextStyle(color: Colors.black)),
            style: FilledButton.styleFrom(
              backgroundColor: HmColors.accent, foregroundColor: Colors.black,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              disabledBackgroundColor: HmColors.surface2,
              disabledForegroundColor: HmColors.text5,
            ),
          ),
        ),
      ]),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon, required this.label, required this.value, required this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: HmColors.surface2,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HmColors.border),
          ),
          child: Row(children: [
            Icon(icon, size: 16, color: HmColors.text4),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: HmColors.text5, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                const SizedBox(height: 1),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w800, color: HmColors.text)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// === Navigation sheet ======================================================

class _NavigationSheet extends StatelessWidget {
  const _NavigationSheet({required this.order});
  final Order order;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final lat = order.latitude;
    final lng = order.longitude;
    final addr = order.fullAddress ?? order.address ?? '';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(
            width: 38, height: 4,
            decoration: BoxDecoration(color: HmColors.border2, borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 14),
          Row(children: [
            const Icon(Icons.navigation_rounded, size: 18, color: HmColors.success),
            const SizedBox(width: 8),
            Text(loc.order_build_route_sheet_title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 6),
          Text(addr,
              style: const TextStyle(fontSize: 12.5, color: HmColors.text4)),
          const SizedBox(height: 16),
          _NavApp(label: 'Google Maps', icon: Icons.map_rounded,
              iconBg: const Color(0xFFE8F5E9), iconFg: const Color(0xFF1A73E8),
              url: _googleUrl(lat, lng, addr)),
          const SizedBox(height: 8),
          _NavApp(label: 'Yandex Maps', icon: Icons.location_on_rounded,
              iconBg: const Color(0xFFFFF3E0), iconFg: const Color(0xFFFC3F1D),
              url: _yandexUrl(lat, lng, addr)),
          const SizedBox(height: 8),
          _NavApp(label: 'Waze', icon: Icons.navigation_rounded,
              iconBg: const Color(0xFFE0F7FA), iconFg: const Color(0xFF33CCFF),
              url: _wazeUrl(lat, lng, addr)),
          const SizedBox(height: 8),
          _NavApp(label: 'Apple Maps', icon: Icons.apple_rounded,
              iconBg: const Color(0x14FFFFFF), iconFg: HmColors.text2,
              url: _appleUrl(lat, lng, addr)),
        ]),
      ),
    );
  }
  String _googleUrl(double? lat, double? lng, String addr) {
    if (lat != null && lng != null) {
      return 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
    }
    return 'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(addr)}';
  }
  String _yandexUrl(double? lat, double? lng, String addr) {
    if (lat != null && lng != null) return 'https://yandex.com/maps/?rtext=~$lat,$lng&rtt=auto';
    return 'https://yandex.com/maps/?text=${Uri.encodeComponent(addr)}';
  }
  String _wazeUrl(double? lat, double? lng, String addr) {
    if (lat != null && lng != null) return 'https://www.waze.com/ul?ll=$lat%2C$lng&navigate=yes';
    return 'https://www.waze.com/ul?q=${Uri.encodeComponent(addr)}&navigate=yes';
  }
  String _appleUrl(double? lat, double? lng, String addr) {
    if (lat != null && lng != null) return 'https://maps.apple.com/?daddr=$lat,$lng&dirflg=d';
    return 'https://maps.apple.com/?daddr=${Uri.encodeComponent(addr)}';
  }
}

class _NavApp extends StatelessWidget {
  const _NavApp({
    required this.label, required this.icon, required this.iconBg,
    required this.iconFg, required this.url,
  });
  final String label;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String url;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: HmColors.surface2,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          if (context.mounted) Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 11, 14, 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HmColors.border2),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: iconFg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800, color: HmColors.text)),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: HmColors.text5),
          ]),
        ),
      ),
    );
  }
}

// === Helpers ===============================================================

String _formatTime(DateTime d) {
  final dt = d.toLocal();
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _formatDate(DateTime d) {
  final dt = d.toLocal();
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} $h:$m';
}

String _formatShort(DateTime d) {
  final dt = d.toLocal();
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} $h:$m';
}
// poke 1778327999
