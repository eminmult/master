import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/api/api_exception.dart';
import 'package:master_mobile/core/auth/auth_controller.dart';
import 'package:master_mobile/core/i18n/category_helpers.dart';
import 'package:master_mobile/core/routing/tab_switcher.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/applications/data/applications_repository.dart';
import 'package:master_mobile/features/categories/data/categories_repository.dart';
import 'package:master_mobile/features/orders/data/models/public_order.dart';
import 'package:master_mobile/features/orders/data/orders_repository.dart';
import 'package:master_mobile/shared/widgets/hm_avatar.dart';
import 'package:master_mobile/shared/widgets/hm_icon_button.dart';

final _publicOrderProvider =
    FutureProvider.autoDispose.family<PublicOrderItem, int>((ref, id) async {
  return ref.watch(ordersRepositoryProvider).publicShow(id);
});

/// Side-channel: backend includes `my_application_id` for an authenticated
/// master who already has an active application on this announcement. We use
/// the raw payload because the freezed [PublicOrderItem] doesn't model the
/// field (regenerating freezed code mid-session is fragile).
final _myApplicationIdProvider =
    FutureProvider.autoDispose.family<int?, int>((ref, id) async {
  try {
    final raw = await ref.watch(ordersRepositoryProvider).publicShowRaw(id);
    return (raw['my_application_id'] as num?)?.toInt();
  } catch (_) {
    return null;
  }
});

class AnnouncementDetailPage extends ConsumerStatefulWidget {
  const AnnouncementDetailPage({
    super.key,
    required this.id,
    this.existingApplicationId,
  });
  final int id;

  /// When opened from the master's "my applications" list (or a notification
  /// linking back to their own application), pass the application id so the
  /// page shows the "Open chat" CTA instead of "Apply".
  final int? existingApplicationId;

  @override
  ConsumerState<AnnouncementDetailPage> createState() =>
      _AnnouncementDetailPageState();
}

class _AnnouncementDetailPageState
    extends ConsumerState<AnnouncementDetailPage> {
  bool _applying = false;
  int? _appliedApplicationId;

  @override
  void initState() {
    super.initState();
    _appliedApplicationId = widget.existingApplicationId;
  }

  /// Effective application id — prefers the locally-tracked one (set when the
  /// master applies in this session or via route param), falling back to the
  /// backend `my_application_id` side-channel for reopens after the app was
  /// already submitted.
  int? _effectiveApplicationId() {
    if (_appliedApplicationId != null) return _appliedApplicationId;
    return ref.read(_myApplicationIdProvider(widget.id)).value;
  }

  void _openChat() {
    final appId = _effectiveApplicationId();
    if (appId == null) return;
    context.push('/chat/application/$appId');
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    try {
      final app = await ref.read(applicationsRepositoryProvider).apply(widget.id);
      if (!mounted) return;
      setState(() => _appliedApplicationId = app.id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.l10n.ann_apply_sent),
        backgroundColor: HmColors.success,
      ));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message), backgroundColor: HmColors.danger,
      ));
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<void> _withdraw() async {
    final loc = context.l10n;
    final appId = _effectiveApplicationId();
    if (appId == null) return;
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
    try {
      await ref.read(applicationsRepositoryProvider).withdraw(appId);
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        // Withdrawing from a deep-link entry — fall through to the
        // Orders tab so the user lands on a familiar surface instead
        // of staring at an empty announcement detail.
        ref.switchTab(context, AppTab.orders);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message), backgroundColor: HmColors.danger,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final asyncOrder = ref.watch(_publicOrderProvider(widget.id));
    final asyncMyAppId = ref.watch(_myApplicationIdProvider(widget.id));
    final hasApp = _appliedApplicationId != null || asyncMyAppId.value != null;
    final auth = ref.watch(authStateProvider);
    final me = auth is AuthAuthenticated ? auth.user : null;

    return Scaffold(
      backgroundColor: HmColors.bg,
      body: SafeArea(
        child: asyncOrder.when(
          data: (o) {
            final isMaster = me?.isMaster ?? false;
            final isOwner = me != null && o.client?['id'] == me.id;
            // For an authenticated master who isn't the announcement's
            // author, surface a sticky "Apply" CTA. Public/guest viewers and
            // clients only see the read-only detail.
            final showApplyBar = isMaster && !isOwner;
            return Stack(children: [
              _content(context, o, bottomPadding: showApplyBar ? 96 : 16),
              if (showApplyBar) _ApplyBar(
                applying: _applying,
                applied: hasApp,
                onApply: _apply,
                onOpenChat: _openChat,
                onWithdraw: _withdraw,
                onLogin: () {/* already authed in this branch */},
              ),
            ]);
          },
          loading: () => const Center(
              child: CircularProgressIndicator(color: HmColors.accent)),
          error: (_, __) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(loc.auth_failed_to_load,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: HmColors.danger)),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () =>
                      ref.invalidate(_publicOrderProvider(widget.id)),
                  child: Text(loc.common_continue),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, PublicOrderItem o,
      {required double bottomPadding}) {
    final loc = context.l10n;
    final cat = o.category;
    String categoryName = loc.order_service_fallback;
    if (cat != null && cat['slug'] != null) {
      categoryName = localizedCategoryName(loc, ServiceCategory.fromJson(cat));
    } else if (cat != null && cat['name'] != null) {
      categoryName = cat['name'].toString();
    }

    final clientName = (o.client?['first_name'] ?? loc.common_user).toString();
    final clientAvatar = o.client?['avatar_url']?.toString();
    final clientRating = o.client?['rating_avg']?.toString();
    final clientRatingCount = (o.client?['rating_count'] as num?)?.toInt() ?? 0;

    return ListView(
      padding: EdgeInsets.only(bottom: bottomPadding),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(children: [
            HmIconButton(
                icon: Icons.arrow_back_ios_new_rounded, small: true, flat: true,
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go('/announcements')),
            const Spacer(),
            Text('#${o.id}',
                style: const TextStyle(
                    fontSize: 13,
                    color: HmColors.text4,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            const SizedBox(width: 32),
          ]),
        ),
        if (o.photos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: o.photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final url = o.photos[i]['url']?.toString();
                  if (url == null) return const SizedBox.shrink();
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 280,
                      child: Image.network(url, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: HmColors.surface2)),
                    ),
                  );
                },
              ),
            ),
          ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: HmColors.accentSoft,
                borderRadius: BorderRadius.circular(HmRadius.pill),
                border: Border.all(color: HmColors.accentBorder),
              ),
              child: Text(categoryName,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: HmColors.accent,
                      letterSpacing: 0.4)),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        if (o.description != null && o.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(o.description!,
                style: const TextStyle(
                    fontSize: 15, color: HmColors.text2, height: 1.55)),
          ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HmColors.surface,
              borderRadius: BorderRadius.circular(HmRadius.cardLarge),
              border: Border.all(color: HmColors.border),
            ),
            child: Column(
              children: [
                if (o.district != null)
                  _kv(Icons.location_on_rounded, loc.order_kv_address, o.district!),
                if (o.estimatedBudget != null && o.estimatedBudget!.isNotEmpty)
                  _kv(Icons.payments_rounded, loc.order_kv_budget,
                      '${o.estimatedBudget!} AZN', accent: true),
                if (o.scheduledAt != null)
                  _kv(Icons.event_rounded, loc.order_kv_agreed_date,
                      _fmtDate(o.scheduledAt!)),
                if (o.comment != null && o.comment!.isNotEmpty)
                  _kv(Icons.notes_rounded, loc.order_kv_address, o.comment!),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: HmColors.surface3,
              borderRadius: BorderRadius.circular(HmRadius.cardLarge),
              border: Border.all(color: HmColors.border2),
            ),
            child: Row(
              children: [
                if (clientAvatar != null)
                  HmAvatar(url: clientAvatar, size: 48, ring: true)
                else
                  Container(
                    width: 48, height: 48,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: HmColors.surface2),
                    child: const Icon(Icons.person_rounded,
                        color: HmColors.text5, size: 22),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(clientName,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      if (clientRating != null) ...[
                        const SizedBox(height: 2),
                        Row(children: [
                          const Icon(Icons.star_rounded,
                              color: HmColors.accent, size: 13),
                          const SizedBox(width: 4),
                          Text(clientRating,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: HmColors.accent)),
                          const SizedBox(width: 4),
                          Text(loc.list_reviews_n(clientRatingCount),
                              style: const TextStyle(
                                  fontSize: 11, color: HmColors.text5)),
                        ]),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _kv(IconData icon, String label, String value, {bool accent = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent ? HmColors.accent : HmColors.text4),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value,
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500,
                  color: accent ? HmColors.accent : HmColors.text2,
                  height: 1.4,
                )),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} $h:$m';
  }
}

class _ApplyBar extends StatelessWidget {
  const _ApplyBar({
    required this.applying,
    required this.applied,
    required this.onApply,
    required this.onOpenChat,
    required this.onWithdraw,
    required this.onLogin,
  });
  final bool applying;
  final bool applied;
  final VoidCallback onApply;
  final VoidCallback onOpenChat;
  final VoidCallback onWithdraw;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return Positioned(
      left: 0, right: 0, bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(
          color: HmColors.bg,
          border: Border(top: BorderSide(color: HmColors.border2)),
        ),
        // When applied the master gets two side-by-side actions: discuss
        // (primary, opens chat) and withdraw (outlined, cancels application).
        // Otherwise the single "Apply" CTA spans the bar.
        child: applied
            ? Row(children: [
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: onWithdraw,
                      icon: const Icon(Icons.close_rounded, size: 14, color: HmColors.danger),
                      label: Text(loc.apps_withdraw,
                          style: const TextStyle(color: HmColors.danger, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0x66EF4444)),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 6,
                  child: SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: onOpenChat,
                      icon: const Icon(Icons.chat_rounded, size: 16, color: Colors.black),
                      label: Text(loc.ann_discuss,
                          style: const TextStyle(color: Colors.black)),
                      style: FilledButton.styleFrom(
                        backgroundColor: HmColors.accent,
                        foregroundColor: Colors.black,
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ])
            : SizedBox(
                width: double.infinity, height: 52,
                child: FilledButton.icon(
                  onPressed: applying ? null : onApply,
                  icon: applying
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.black))
                      : const Icon(Icons.check_rounded,
                          size: 16, color: Colors.black),
                  label: Text(applying ? loc.ann_applying : loc.ann_apply_btn,
                      style: const TextStyle(color: Colors.black)),
                  style: FilledButton.styleFrom(
                    backgroundColor: HmColors.accent,
                    foregroundColor: Colors.black,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800),
                    disabledBackgroundColor: HmColors.surface2,
                  ),
                ),
              ),
      ),
    );
  }
}
