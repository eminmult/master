import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/api/api_exception.dart';
import 'package:master_mobile/core/auth/auth_controller.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/core/i18n/category_helpers.dart';
import 'package:master_mobile/features/applications/data/applications_repository.dart';
import 'package:master_mobile/features/calls/data/call_service.dart';
import 'package:master_mobile/features/calls/data/reverb_client.dart';
import 'package:master_mobile/features/categories/data/categories_repository.dart';
import 'package:master_mobile/features/orders/data/orders_repository.dart';
import 'package:master_mobile/features/realtime/sse_client.dart';
import 'package:master_mobile/shared/widgets/hm_avatar.dart';
import 'package:master_mobile/shared/widgets/hm_icon_button.dart';

/// Application detail (with parent order + counterparty) for showing the
/// "what is this about" summary above the chat composer when the user
/// opens it from notifications or the inbox.
final _appContextProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, id) async {
  return ref.watch(applicationsRepositoryProvider).show(id);
});

class _Msg {
  const _Msg({required this.id, required this.mine, required this.text, required this.time, this.read = false});
  final int id;
  final bool mine;
  final String text;
  final String time;
  final bool read;
}

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({
    super.key,
    this.applicationId,
    this.orderId,
    this.specialistImg,
  });

  /// One-of: when set, talks to `/order-applications/{id}/messages`. Used
  /// during the public-pool bidding phase when the master and client haven't
  /// committed to each other yet.
  final int? applicationId;

  /// One-of: when set, talks to `/orders/{id}/messages`. Used after the
  /// master accepts the assignment ("Discuss" on a `pending_master` order)
  /// and the client + master are negotiating terms inside a single order.
  final int? orderId;

  final String? specialistImg;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _typing = false;
  bool _loading = false;
  Timer? _poll;

  /// When applicationId == null we're in preview/mock mode (Handyman demo).
  /// Otherwise we hit the real /order-applications/:id/messages API and poll.
  List<_Msg> _messages = [];

  bool get _isLive => widget.applicationId != null || widget.orderId != null;
  bool get _isOrderChat => widget.orderId != null;

  /// Composer is hidden for the master when the application is still in
  /// PENDING status — the client hasn't started a discussion yet, so the
  /// master must wait. All other states (and the client side) get a live
  /// composer. Order chats are always unlocked.
  bool _composerEnabled() {
    if (widget.applicationId == null) return true;
    final asyncApp = ref.read(_appContextProvider(widget.applicationId!));
    final app = asyncApp.valueOrNull;
    final auth = ref.read(authStateProvider);
    final myId = auth is AuthAuthenticated ? auth.user.id : -1;
    // Decide who I am from the application payload — most authoritative.
    // While the request is in flight, lock conservatively for whoever isn't
    // unambiguously the client; a brief shadow of the lock is better than
    // showing the composer and yanking it away on the next frame.
    if (app == null) {
      return auth is AuthAuthenticated && auth.user.isClient;
    }
    final status = app['status']?.toString();
    final masterId = (app['master_id'] as num?)?.toInt();
    final clientId = ((app['order'] as Map?)?['client_id'] as num?)?.toInt();
    final iAmMaster = myId == masterId;
    final iAmClient = myId == clientId;
    if (iAmMaster && status == 'pending') return false;
    if (!iAmClient && !iAmMaster) return false; // admin / stranger
    return true;
  }

  StreamSubscription<ReverbEvent>? _rtSub;
  StreamSubscription<Map<String, dynamic>>? _sseSub;

  @override
  void initState() {
    super.initState();
    if (_isLive) {
      // First fetch is a full pull — pulls the whole window so the chat
      // history shows up before any deltas arrive.
      Future.microtask(() {
        if (mounted) _refresh();
      });
      // SSE is the primary realtime channel (works through CF Flexible SSL).
      // Keep a slow 10s polling tick as a safety net for missed events on a
      // dropped connection that the SSE reconnect logic hasn't caught yet.
      _poll = Timer.periodic(const Duration(seconds: 10), (_) => _refreshIncremental());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _bindRealtime();
        _bindSse();
      });
    }
  }

  void _bindSse() {
    final sse = ref.read(sseClientProvider);
    _sseSub = sse.events.listen(_onSseEvent);
  }

  void _onSseEvent(Map<String, dynamic> e) {
    if (!mounted) return;
    if (e['type'] != 'chat.message') return;
    final scope = e['scope']?.toString();
    final scopeId = (e['scope_id'] as num?)?.toInt();
    if (_isOrderChat) {
      if (scope == 'order' && scopeId == widget.orderId) _refreshIncremental();
    } else if (widget.applicationId != null) {
      if (scope == 'application' && scopeId == widget.applicationId) _refreshIncremental();
    }
  }

  void _bindRealtime() {
    final svc = ref.read(callServiceProvider);
    _rtSub = svc.reverbEvents.listen(_onRealtime);
  }

  void _onRealtime(ReverbEvent e) {
    if (!mounted || e.event != 'chat.message') return;
    final scope = e.data['scope']?.toString();
    final scopeId = (e.data['scope_id'] as num?)?.toInt();
    if (_isOrderChat) {
      if (scope == 'order' && scopeId == widget.orderId) _refresh();
    } else if (widget.applicationId != null) {
      if (scope == 'application' && scopeId == widget.applicationId) _refresh();
    }
  }

  /// Incremental refresh: pulls only messages newer than the last known id.
  /// Server short-circuits an empty response to ~200 bytes when nothing's new,
  /// keeping the 1Hz cadence cheap.
  Future<void> _refreshIncremental() async {
    if (!_isLive || _loading) return;
    final auth = ref.read(authStateProvider);
    final myId = auth is AuthAuthenticated ? auth.user.id : -1;
    final lastId = _messages.isEmpty
        ? 0
        : _messages
            .map((m) => m.id)
            .where((id) => id > 0)
            .fold<int>(0, (a, b) => a > b ? a : b);
    if (lastId == 0) {
      return _refresh();
    }
    try {
      final List<_Msg> incoming;
      if (_isOrderChat) {
        final list = await ref.read(ordersRepositoryProvider)
            .messages(widget.orderId!, since: lastId);
        if (list.isEmpty) return;
        incoming = list.map((m) {
          final sender = (m['sender_id'] as num?)?.toInt() ?? 0;
          final created = DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now();
          return _Msg(
            id: (m['id'] as num?)?.toInt() ?? 0,
            mine: sender == myId,
            text: m['text']?.toString() ?? '',
            time: _fmtTime(created),
            read: m['read_at'] != null,
          );
        }).toList();
      } else {
        final list = await ref.read(applicationsRepositoryProvider)
            .messages(widget.applicationId!, since: lastId);
        if (list.isEmpty) return;
        incoming = list.map((m) => _Msg(
          id: m.id,
          mine: m.senderId == myId,
          text: m.text,
          time: _fmtTime(m.createdAt),
          read: m.readAt != null,
        )).toList();
      }
      if (!mounted) return;
      // De-dupe against any optimistic pending bubbles and existing rows.
      final existing = _messages.map((m) => m.id).toSet();
      final fresh = incoming.where((m) => !existing.contains(m.id)).toList();
      if (fresh.isEmpty) return;
      setState(() => _messages = [..._messages, ...fresh]);
      _scrollToBottom();
    } on ApiException catch (_) {
      // ignore; next poll cycle retries
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _poll?.cancel();
    _rtSub?.cancel();
    _sseSub?.cancel();
    super.dispose();
  }

  String get _specialistImg =>
      widget.specialistImg ?? 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&q=80';

  Future<void> _refresh() async {
    if (!_isLive || _loading) return;
    final auth = ref.read(authStateProvider);
    final myId = auth is AuthAuthenticated ? auth.user.id : -1;
    // Pull a fresh application status alongside the messages so the
    // composer lock and the context bar both update on the same poll.
    if (widget.applicationId != null) {
      ref.invalidate(_appContextProvider(widget.applicationId!));
    }
    setState(() => _loading = true);
    try {
      final List<_Msg> mapped;
      if (_isOrderChat) {
        // Order-level chat — raw maps because the schema is a thin
        // {id, sender_id, text, created_at, read_at} record.
        final list = await ref.read(ordersRepositoryProvider).messages(widget.orderId!);
        mapped = list.map((m) {
          final sender = (m['sender_id'] as num?)?.toInt() ?? 0;
          final created = DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now();
          return _Msg(
            id: (m['id'] as num?)?.toInt() ?? 0,
            mine: sender == myId,
            text: m['text']?.toString() ?? '',
            time: _fmtTime(created),
            read: m['read_at'] != null,
          );
        }).toList();
      } else {
        final list = await ref.read(applicationsRepositoryProvider).messages(widget.applicationId!);
        mapped = list.map((m) => _Msg(
          id: m.id,
          mine: m.senderId == myId,
          text: m.text,
          time: _fmtTime(m.createdAt),
          read: m.readAt != null,
        )).toList();
      }
      if (!mounted) return;
      setState(() {
        _messages = mapped.reversed.toList(); // backend returns newest first
      });
      _scrollToBottom();
    } on ApiException catch (_) {
      // ignore; UI keeps last good state
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtTime(DateTime d) {
    // 24h format — locale-neutral, no AM/PM that would need translating.
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _send() async {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;

    if (!_isLive) return;
    _ctrl.clear();

    // Optimistic bubble — appears instantly with the local time. Tagged
    // with a temporary negative id so the server-confirmed row replaces it
    // when the next refresh / WS push arrives.
    final pendingId = -DateTime.now().millisecondsSinceEpoch;
    final optimistic = _Msg(
      id: pendingId,
      mine: true,
      text: t,
      time: _fmtTime(DateTime.now()),
      read: false,
    );
    if (mounted) {
      setState(() => _messages = [..._messages, optimistic]);
      _scrollToBottom();
    }

    try {
      if (_isOrderChat) {
        final m = await ref.read(ordersRepositoryProvider).sendMessage(widget.orderId!, text: t);
        _replaceOptimistic(pendingId, _orderMsgFromMap(m));
      } else {
        final m = await ref.read(applicationsRepositoryProvider).sendMessage(widget.applicationId!, t);
        _replaceOptimistic(pendingId, _Msg(
          id: m.id, mine: true, text: m.text,
          time: _fmtTime(m.createdAt), read: m.readAt != null,
        ));
      }
    } on ApiException catch (e) {
      // Drop the optimistic bubble — message didn't go through.
      if (mounted) {
        setState(() => _messages = _messages.where((x) => x.id != pendingId).toList());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: HmColors.danger),
        );
      }
    }
  }

  _Msg _orderMsgFromMap(Map<String, dynamic> m) {
    final created = DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now();
    return _Msg(
      id: (m['id'] as num?)?.toInt() ?? 0,
      mine: true,
      text: m['text']?.toString() ?? '',
      time: _fmtTime(created),
      read: m['read_at'] != null,
    );
  }

  void _replaceOptimistic(int pendingId, _Msg confirmed) {
    if (!mounted) return;
    setState(() {
      _messages = _messages.map((x) => x.id == pendingId ? confirmed : x).toList();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    // Subscribe to the application provider so composer lock state stays in
    // sync with status changes (e.g. once the client starts the discussion,
    // the master's composer should unlock immediately on the next poll).
    if (widget.applicationId != null) {
      ref.watch(_appContextProvider(widget.applicationId!));
    }
    return Scaffold(
      backgroundColor: HmColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: Color(0xD90A0A0A),
                border: Border(bottom: BorderSide(color: HmColors.border2)),
              ),
              child: Row(
                children: [
                  HmIconButton(icon: Icons.arrow_back_ios_new_rounded, small: true, flat: true,
                      onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
                  const SizedBox(width: 8),
                  if (widget.specialistImg != null)
                    HmAvatar(url: _specialistImg, size: 40, ring: true, online: true)
                  else
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: HmColors.surface2,
                        border: Border.all(color: HmColors.border),
                      ),
                      child: const Icon(Icons.chat_bubble_outline_rounded,
                          color: HmColors.accent, size: 18),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(loc.chat_title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                        if (_isLive)
                          Text(loc.chat_user_online,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: HmColors.text4)),
                      ],
                    ),
                  ),
                  // Order chats have no context bar — surface a "Details"
                  // shortcut in the header so the master can still review
                  // description / photos / address while chatting. For
                  // application chats the same info is in _AppContextBar
                  // directly below, so no button here.
                  if (_isOrderChat)
                    HmIconButton(
                      icon: Icons.list_alt_rounded,
                      small: true,
                      flat: true,
                      onPressed: () => context.push('/order/${widget.orderId}'),
                    ),
                ],
              ),
            ),
            if (widget.applicationId != null)
              _AppContextBar(applicationId: widget.applicationId!),
            // Messages
            Expanded(
              child: () {
                if (!_isLive && _messages.isEmpty) {
                  return _EmptyChat(message: loc.chat_select_conversation);
                }
                // First fetch in flight — surface a spinner so the user sees
                // that history is being pulled (instead of an apparently
                // empty thread for 30+ seconds on slow connections).
                if (_isLive && _messages.isEmpty && _loading) {
                  return const Center(
                    child: CircularProgressIndicator(color: HmColors.accent, strokeWidth: 2.4));
                }
                if (_isLive && _messages.isEmpty && !_loading) {
                  return _EmptyChat(message: loc.chat_no_messages);
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + 1 + (_typing ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == 0) return _DayChip(label: loc.chat_day_today);
                    final msgIdx = i - 1;
                    if (_typing && msgIdx == _messages.length) return _TypingBubble(avatar: _specialistImg);
                    return _MessageRow(msg: _messages[msgIdx], specialistImg: _specialistImg);
                  },
                );
              }(),
            ),
            // Composer (only in live mode — empty state hides it).
            // For application chats in PENDING status, the master's composer
            // is locked: they have to wait for the client to engage. The
            // client always has a live composer because their first message
            // is what unlocks the conversation for both sides.
            if (_isLive && !_composerEnabled())
              _LockedComposer(message: loc.chat_locked_master_pending),
            if (_isLive && _composerEnabled())
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: HmColors.bg,
                  border: Border(top: BorderSide(color: HmColors.border2)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: loc.chat_placeholder,
                            prefixIcon: const Icon(Icons.attach_file_rounded, size: 20, color: HmColors.text4),
                            suffixIcon: const Icon(Icons.sentiment_satisfied_alt_rounded, size: 20, color: HmColors.text4),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: HmShadows.accentGlow),
                        child: Material(
                          color: HmColors.accent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: _send,
                            customBorder: const CircleBorder(),
                            child: const SizedBox(
                              width: 48, height: 48,
                              child: Icon(Icons.send_rounded, color: Colors.black, size: 18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LockedComposer extends StatelessWidget {
  const _LockedComposer({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: HmColors.bg,
        border: Border(top: BorderSide(color: HmColors.border2)),
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          const Icon(Icons.lock_outline_rounded,
              size: 16, color: HmColors.text5),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 12.5,
                    color: HmColors.text4,
                    height: 1.4,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined, color: HmColors.text5, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(color: HmColors.text5, fontSize: 14, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: HmColors.surface2,
          borderRadius: BorderRadius.circular(HmRadius.pill),
        ),
        child: Text(label, style: const TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700, color: HmColors.text6, letterSpacing: 1.1,
        )),
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.msg, required this.specialistImg});
  final _Msg msg;
  final String specialistImg;

  @override
  Widget build(BuildContext context) {
    final me = msg.mine;
    final bubbleColor = me ? HmColors.accentSoft : HmColors.surface;
    final bubbleBorder = me ? HmColors.accentBorder : HmColors.border;
    final textColor = me ? HmColors.accent : HmColors.text3;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: me ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!me) ...[
            HmAvatar(url: specialistImg, size: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              child: Column(
                crossAxisAlignment: me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: me ? HmRadius.bubbleMine : HmRadius.bubbleTheirs,
                      border: Border.all(color: bubbleBorder),
                      boxShadow: me ? const [BoxShadow(color: Color(0x0DFFFF00), blurRadius: 20, offset: Offset(0, 4))] : null,
                    ),
                    child: Text(msg.text,
                        style: TextStyle(fontSize: 14, height: 1.5, color: textColor)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(msg.time, style: const TextStyle(fontSize: 10, color: HmColors.text4, fontWeight: FontWeight.w500)),
                        if (me) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.done_all_rounded, size: 12, color: HmColors.accent),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (me) ...[
            const SizedBox(width: 8),
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [HmColors.accent, HmColors.accentDark],
                ),
                border: Border.all(color: HmColors.accentBorder),
              ),
              child: const Center(
                child: Text('A', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble({required this.avatar});
  final String avatar;
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls = List.generate(3, (i) {
    final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    return c;
  });

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        HmAvatar(url: widget.avatar, size: 28),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: HmColors.surface,
            borderRadius: HmRadius.bubbleTheirs,
            border: Border.all(color: HmColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: AnimatedBuilder(
                  animation: _ctrls[i],
                  builder: (_, __) {
                    final t = (_ctrls[i].value + i * 0.18) % 1.0;
                    final bouncy = t < 0.3 ? t / 0.3 : (t < 0.6 ? 1 - (t - 0.3) / 0.3 : 0.0);
                    return Transform.translate(
                      offset: Offset(0, -4 * bouncy),
                      child: Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          color: HmColors.text4.withOpacity(0.4 + 0.6 * bouncy),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// === Order context bar shown on top of application chats ====================

class _AppContextBar extends ConsumerStatefulWidget {
  const _AppContextBar({required this.applicationId});
  final int applicationId;

  @override
  ConsumerState<_AppContextBar> createState() => _AppContextBarState();
}

class _AppContextBarState extends ConsumerState<_AppContextBar> {
  // Expanded by default — the master needs the description + photos visible
  // the moment they open the application chat. They can collapse it via the
  // chevron once they've read it.
  bool _expanded = true;
  bool _acting = false;

  Future<void> _withdraw() async {
    final loc = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: HmColors.surface,
        title: Text(loc.apps_withdraw_title),
        content: Text(loc.apps_withdraw_confirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc.common_cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: Text(loc.apps_withdraw, style: const TextStyle(color: HmColors.danger))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _acting = true);
    try {
      await ref.read(applicationsRepositoryProvider).withdraw(widget.applicationId);
      ref.invalidate(_appContextProvider(widget.applicationId));
      if (mounted) context.pop();
    } catch (_) {} finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _reject() async {
    final loc = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: HmColors.surface,
        title: Text(loc.apps_reject_title),
        content: Text(loc.apps_reject_confirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc.common_cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: Text(loc.apps_reject, style: const TextStyle(color: HmColors.danger))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _acting = true);
    try {
      await ref.read(applicationsRepositoryProvider).reject(widget.applicationId);
      ref.invalidate(_appContextProvider(widget.applicationId));
      if (mounted) context.pop();
    } catch (_) {} finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final asyncApp = ref.watch(_appContextProvider(widget.applicationId));
    return asyncApp.when(
      loading: () => const SizedBox(
        height: 64,
        child: Center(
            child: SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    color: HmColors.accent, strokeWidth: 2))),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (app) {
        final order = app['order'] as Map<String, dynamic>?;
        if (order == null) return const SizedBox.shrink();
        final authState = ref.watch(authStateProvider);
        final me = authState is AuthAuthenticated ? authState.user.id : null;
        final isMaster = me != null && me == (app['master_id'] as num?)?.toInt();
        final isClient = me != null && me == (order['client_id'] as num?)?.toInt();
        final appStatus = app['status']?.toString() ?? '';
        final canWithdraw = isMaster && ['pending', 'discussing', 'proposed'].contains(appStatus);
        final canReject = isClient && ['pending', 'discussing', 'proposed'].contains(appStatus);

        final cat = order['category'] as Map<String, dynamic>?;
        String catName = loc.order_request_fallback;
        if (cat != null && cat['slug'] != null) {
          catName = localizedCategoryName(loc, ServiceCategory.fromJson(cat));
        } else if (cat != null && cat['name'] != null) {
          catName = cat['name'].toString();
        }
        final desc = order['description']?.toString();
        final district = (order['full_address']?.toString() ?? '').split(',').first.trim();
        final photos = (order['photos'] as List?) ?? const [];
        final photoUrls = photos
            .whereType<Map>()
            .map((p) => p['url']?.toString())
            .whereType<String>()
            .toList();

        return Material(
          color: HmColors.surface3,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: HmColors.border2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                    child: Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: HmColors.accentSoft),
                        child: const Icon(Icons.receipt_long_rounded,
                            size: 18, color: HmColors.accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(catName,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                    color: HmColors.text)),
                            const SizedBox(height: 2),
                            Row(children: [
                              if (district.isNotEmpty) ...[
                                const Icon(Icons.location_on_outlined,
                                    size: 11, color: HmColors.text5),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(district,
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: HmColors.text4,
                                          fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (photoUrls.isNotEmpty) ...[
                                const Icon(Icons.photo_library_outlined,
                                    size: 11, color: HmColors.text5),
                                const SizedBox(width: 3),
                                Text('${photoUrls.length}',
                                    style: const TextStyle(
                                        fontSize: 11, color: HmColors.text4, fontWeight: FontWeight.w600)),
                              ],
                            ]),
                          ],
                        ),
                      ),
                      Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                          color: HmColors.text4, size: 22),
                    ]),
                  ),
                ),
                if (_expanded) Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (desc != null && desc.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(desc,
                            style: const TextStyle(
                                fontSize: 12.5, color: HmColors.text2, height: 1.4)),
                      ),
                    if (photoUrls.isNotEmpty)
                      SizedBox(
                        height: 84,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: photoUrls.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              photoUrls[i],
                              width: 84, height: 84, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 84, height: 84,
                                color: HmColors.surface2,
                                child: const Icon(Icons.broken_image_outlined, color: HmColors.text5, size: 18),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (canWithdraw || canReject) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: _acting ? null : (canWithdraw ? _withdraw : _reject),
                          icon: const Icon(Icons.close_rounded, size: 14, color: HmColors.danger),
                          label: Text(canWithdraw ? loc.apps_withdraw : loc.apps_reject,
                              style: const TextStyle(color: HmColors.danger, fontSize: 12, fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0x66EF4444)),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
