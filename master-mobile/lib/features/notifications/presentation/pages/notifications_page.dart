import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/auth/auth_controller.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/notifications/data/notifications_providers.dart';
import 'package:master_mobile/features/notifications/data/notifications_repository.dart';
import 'package:master_mobile/shared/widgets/hm_icon_button.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(notificationsListProvider);
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    final unread = ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;
    final loc = context.l10n;

    return Scaffold(
      backgroundColor: HmColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: loc.notif_title,
              unread: unread,
              markAllLabel: loc.notif_mark_all_read,
              onMarkAll: unread == 0
                  ? null
                  : () async {
                      await ref.read(notificationsRepositoryProvider).markAllRead();
                      ref.invalidate(notificationsListProvider);
                      ref.invalidate(unreadNotificationsCountProvider);
                    },
            ),
            Expanded(
              child: asyncList.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: HmColors.accent, strokeWidth: 2.4),
                ),
                error: (_, __) => _EmptyOrError(
                  icon: Icons.error_outline_rounded,
                  title: loc.home_load_error,
                  onRetry: () => ref.invalidate(notificationsListProvider),
                  retryLabel: loc.notif_retry,
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return _EmptyOrError(
                      icon: Icons.notifications_off_outlined,
                      title: loc.notif_empty,
                      subtitle: loc.notif_empty_subtitle,
                    );
                  }
                  final groups = _group(items);
                  return RefreshIndicator(
                    color: HmColors.accent,
                    backgroundColor: HmColors.surface,
                    onRefresh: () async {
                      ref.invalidate(notificationsListProvider);
                      ref.invalidate(unreadNotificationsCountProvider);
                      await ref.read(notificationsListProvider.future);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: groups.length,
                      itemBuilder: (_, gi) {
                        final g = groups[gi];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                              child: Text(
                                _groupLabel(g.bucket, loc),
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: HmColors.text5,
                                    letterSpacing: 1.0),
                              ),
                            ),
                            for (final n in g.items) ...[
                              _NotificationTile(
                                notification: n,
                                locale: localeCode,
                                relTime: _relTime(n.createdAt, loc),
                                onTap: () => _handleTap(context, ref, n),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref, AppNotification n) async {
    if (!n.isRead) {
      await ref.read(notificationsRepositoryProvider).markRead(n.id);
      ref.invalidate(notificationsListProvider);
      ref.invalidate(unreadNotificationsCountProvider);
    }
    if (!context.mounted) return;
    final route = _routeFor(n);
    if (route != null) context.push(route);
  }

  /// Maps a notification type + payload to an in-app route. Falls back to
  /// the order detail when there's only an `order_id`, then the chat when
  /// there's only an `application_id`, then no nav.
  String? _routeFor(AppNotification n) {
    final orderId = n.data['order_id'];
    final appId = n.data['application_id'];
    final masterId = n.data['master_id'];

    switch (n.type) {
      case 'new_message':
        if (appId != null) return '/chat/application/$appId';
        break;
      case 'new_review':
        if (masterId != null) return '/master/$masterId';
        return '/profile';
      case 'order_created':
      case 'order_accepted':
      case 'order_assigned':
      case 'order_canceled':
      case 'order_expired':
      case 'order_completed':
      case 'master_on_the_way':
      case 'master_arrived':
      case 'proposal_received':
      case 'proposal_accepted':
      case 'application_received':
      case 'application_accepted':
      case 'dispute_opened':
        if (orderId != null) return '/order/$orderId';
        break;
    }
    if (orderId != null) return '/order/$orderId';
    if (appId != null) return '/chat/application/$appId';
    return null;
  }

  // --- Grouping helpers -----------------------------------------------------

  List<_NotifGroup> _group(List<AppNotification> items) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final yesterday = start.subtract(const Duration(days: 1));
    final weekStart = start.subtract(const Duration(days: 7));

    final t = <AppNotification>[];
    final y = <AppNotification>[];
    final w = <AppNotification>[];
    final older = <AppNotification>[];

    for (final n in items) {
      final d = n.createdAt.toLocal();
      if (!d.isBefore(start)) {
        t.add(n);
      } else if (!d.isBefore(yesterday)) {
        y.add(n);
      } else if (!d.isBefore(weekStart)) {
        w.add(n);
      } else {
        older.add(n);
      }
    }

    return [
      if (t.isNotEmpty) _NotifGroup(_Bucket.today, t),
      if (y.isNotEmpty) _NotifGroup(_Bucket.yesterday, y),
      if (w.isNotEmpty) _NotifGroup(_Bucket.thisWeek, w),
      if (older.isNotEmpty) _NotifGroup(_Bucket.older, older),
    ];
  }

  String _groupLabel(_Bucket b, dynamic loc) => switch (b) {
        _Bucket.today => loc.notif_group_today,
        _Bucket.yesterday => loc.notif_group_yesterday,
        _Bucket.thisWeek => loc.notif_group_this_week,
        _Bucket.older => loc.notif_group_older,
      };

  String _relTime(DateTime d, dynamic loc) {
    final diff = DateTime.now().difference(d.toLocal());
    if (diff.inMinutes < 1) return loc.notif_now;
    if (diff.inMinutes < 60) return loc.notif_min_ago(diff.inMinutes);
    if (diff.inHours < 24) return loc.notif_hour_ago(diff.inHours);
    if (diff.inDays < 7) return loc.notif_day_ago(diff.inDays);
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }
}

enum _Bucket { today, yesterday, thisWeek, older }

class _NotifGroup {
  _NotifGroup(this.bucket, this.items);
  final _Bucket bucket;
  final List<AppNotification> items;
}

// --- Header --------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.unread,
    required this.markAllLabel,
    required this.onMarkAll,
  });

  final String title;
  final int unread;
  final String markAllLabel;
  final VoidCallback? onMarkAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          HmIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            small: true,
            flat: true,
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Row(
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                if (unread > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: HmColors.accent,
                      borderRadius: BorderRadius.circular(HmRadius.pill),
                    ),
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black, height: 1.1),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onMarkAll != null)
            TextButton.icon(
              onPressed: onMarkAll,
              icon: const Icon(Icons.done_all_rounded, size: 14, color: HmColors.accent),
              label: Text(markAllLabel,
                  style: const TextStyle(color: HmColors.accent, fontSize: 12, fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}

// --- Empty / error -------------------------------------------------------

class _EmptyOrError extends StatelessWidget {
  const _EmptyOrError({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onRetry,
    this.retryLabel,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: HmColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: HmColors.border2),
              ),
              child: Icon(icon, color: HmColors.text5, size: 32),
            ),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: HmColors.text)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: HmColors.text5, height: 1.4)),
            ],
            if (onRetry != null && retryLabel != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: HmColors.accent,
                  foregroundColor: Colors.black,
                  shape: const StadiumBorder(),
                ),
                child: Text(retryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- Tile ----------------------------------------------------------------

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.locale,
    required this.relTime,
    required this.onTap,
  });
  final AppNotification notification;
  final String locale;
  final String relTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    final palette = _palette(notification.type);

    return Material(
      color: unread ? HmColors.accentSoft.withOpacity(0.35) : HmColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unread ? HmColors.accentBorder : HmColors.border2,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Accent strip on the left for unread items.
                Container(
                  width: 3,
                  color: unread ? HmColors.accent : Colors.transparent,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: palette.bg,
                            shape: BoxShape.circle,
                            border: Border.all(color: palette.border),
                          ),
                          child: Icon(
                            _iconFor(notification.type),
                            color: palette.fg,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notification.localized(locale),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
                                        color: HmColors.text,
                                        height: 1.2,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                  ),
                                  if (unread) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: HmColors.accent,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification.bodyLocalized(locale),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    color: HmColors.text3,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 6),
                              Row(children: [
                                const Icon(Icons.access_time_rounded,
                                    size: 11, color: HmColors.text5),
                                const SizedBox(width: 4),
                                Text(
                                  relTime,
                                  style: const TextStyle(
                                      fontSize: 11, color: HmColors.text5, fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                Icon(Icons.chevron_right_rounded,
                                    size: 16, color: HmColors.text5),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String type) => switch (type) {
        'order_created' || 'order_accepted' || 'order_assigned' =>
          Icons.shopping_bag_rounded,
        'proposal_received' ||
        'proposal_accepted' ||
        'application_received' ||
        'application_accepted' =>
          Icons.handshake_rounded,
        'master_on_the_way' => Icons.directions_run_rounded,
        'master_arrived' => Icons.location_on_rounded,
        'order_completed' => Icons.check_circle_rounded,
        'order_canceled' || 'order_expired' => Icons.cancel_rounded,
        'new_message' => Icons.chat_bubble_rounded,
        'new_review' => Icons.star_rounded,
        'dispute_opened' => Icons.report_problem_rounded,
        _ => Icons.notifications_rounded,
      };

  _Palette _palette(String type) {
    if (type == 'order_completed' || type == 'application_accepted' || type == 'proposal_accepted') {
      return const _Palette(
        bg: Color(0x1F22C55E),
        border: Color(0x4D22C55E),
        fg: HmColors.success,
      );
    }
    if (type == 'order_canceled' ||
        type == 'order_expired' ||
        type == 'dispute_opened') {
      return const _Palette(
        bg: Color(0x1FEF4444),
        border: Color(0x4DEF4444),
        fg: HmColors.danger,
      );
    }
    if (type == 'new_message') {
      return const _Palette(
        bg: Color(0x14CBD5E1),
        border: Color(0x33CBD5E1),
        fg: HmColors.text2,
      );
    }
    return const _Palette(
      bg: HmColors.accentSoft,
      border: HmColors.accentBorder,
      fg: HmColors.accent,
    );
  }
}

class _Palette {
  const _Palette({required this.bg, required this.border, required this.fg});
  final Color bg;
  final Color border;
  final Color fg;
}
