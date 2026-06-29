import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itez_mobile/app/app_router.dart';
import 'package:itez_mobile/common/widgets/hm_avatar.dart';
import 'package:itez_mobile/common/widgets/hm_icon_button.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';
import 'package:itez_mobile/core/i18n/l10n_ext.dart';
import 'package:itez_mobile/core/utils/json_parse.dart';
import 'package:itez_mobile/features/orders/bloc/order_detail_bloc.dart';
import 'package:itez_mobile/features/orders/models/order_model.dart';
import 'package:itez_mobile/features/orders/models/order_status.dart';
import 'package:itez_mobile/features/orders/pages/order_detail_sheets/order_navigation_sheet.dart';
import 'package:itez_mobile/features/orders/pages/order_detail_sheets/order_review_sheet.dart';

/// Layout для завершённых / отменённых / закрытых заказов — порт
/// `_TerminalBody` из master-mobile. Соответствует структуре:
///   header(back + role-label + #id) → hero(status icon + title + date)
///   → category title → description → photos → address → counterparty
///   → price card → cancel reason → review summary → status timeline
///   → reorder button (closed + client).
class OrderTerminalBody extends StatelessWidget {
  const OrderTerminalBody({
    super.key,
    required this.order,
    required this.isClient,
  });

  final OrderModel order;
  final bool isClient;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isCanceled = order.status.isCanceled;
    final clientReviewed = parseBool(order.raw['client_reviewed']);
    final masterReviewed = parseBool(order.raw['master_reviewed']);
    final myReviewLeft = isClient ? clientReviewed : masterReviewed;
    final theirReviewLeft = isClient ? masterReviewed : clientReviewed;
    final canReview = !isCanceled && !myReviewLeft;
    final agreedPrice = parseDoubleOrNull(order.raw['agreed_price']);
    final cancelReason = order.raw['cancel_reason']?.toString();
    final categoryTitle = order.subcategoryName ??
        order.categoryName ??
        l.order_request_fallback;
    final history = _statusHistory(order);

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 28),
      children: [
        _TerminalHero(order: order, isCanceled: isCanceled),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            categoryTitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.4,
            ),
          ),
        ),
        if (order.description != null && order.description!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              order.description!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.text3,
                height: 1.5,
              ),
            ),
          ),
        ],
        if (order.photos.isNotEmpty) ...[
          const SizedBox(height: 18),
          _Section(title: l.order_photos_label),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _PhotosGallery(
                urls: order.photos.map((p) => p.url).toList()),
          ),
        ],
        const SizedBox(height: 18),
        _Section(title: l.order_kv_address),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _AddressCard(order: order),
        ),
        if (order.master != null || order.client != null) ...[
          const SizedBox(height: 18),
          _Section(
            title: isClient ? l.order_kv_master : l.order_kv_client,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _CounterpartyCard(order: order, isClient: isClient),
          ),
        ],
        if (agreedPrice != null && agreedPrice > 0) ...[
          const SizedBox(height: 18),
          _PriceCard(price: agreedPrice, label: l.order_final_price),
        ],
        if (isCanceled && cancelReason != null && cancelReason.isNotEmpty) ...[
          const SizedBox(height: 18),
          _CancelReasonCard(reason: cancelReason),
        ],
        if (!isCanceled) ...[
          const SizedBox(height: 18),
          _Section(title: l.order_review_section),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _ReviewSummaryCard(
              myReviewLeft: myReviewLeft,
              theirReviewLeft: theirReviewLeft,
              isClient: isClient,
              canReview: canReview,
              onLeaveReview: () => _openReviewSheet(context),
            ),
          ),
        ],
        if (history.isNotEmpty) ...[
          const SizedBox(height: 22),
          _Section(title: l.order_timeline_title),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _HistoryTimeline(entries: history),
          ),
        ],
        if (isClient && order.status == OrderStatus.closed) ...[
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.router.push(CreateOrderRoute()),
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: AppColors.accent,
                ),
                label: Text(
                  l.order_reorder_btn,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.accent),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _openReviewSheet(BuildContext context) {
    final bloc = context.read<OrderDetailBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.cardLarge),
        ),
      ),
      builder: (_) => OrderReviewSheet(
        onSubmit: (rating, comment) {
          bloc.add(OrderReviewSubmitted(
            rating: rating,
            comment: comment,
          ));
        },
      ),
    );
  }

  List<_HistoryEntry> _statusHistory(OrderModel order) {
    final raw = order.raw['status_history'];
    if (raw is! List) return const [];
    final out = <_HistoryEntry>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final status = item['status']?.toString();
      if (status == null || status.isEmpty) continue;
      out.add(_HistoryEntry(
        status: status,
        at: parseDate(item['created_at']) ?? parseDate(item['changed_at']),
      ));
    }
    return out;
  }
}

/// Хост-хедер terminal-режима: back-кнопка слева + role-label по центру +
/// #id справа. Сам стандартный _Header страницы тут не используется.
class TerminalHeaderRow extends StatelessWidget {
  const TerminalHeaderRow({
    super.key,
    required this.order,
    required this.isClient,
    required this.onBack,
  });
  final OrderModel order;
  final bool isClient;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          HmIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            small: true,
            flat: true,
            onTap: onBack,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              isClient ? l.order_kv_master : l.order_kv_client,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.text5,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '#${order.id}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.text5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.text4,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _TerminalHero extends StatelessWidget {
  const _TerminalHero({required this.order, required this.isCanceled});
  final OrderModel order;
  final bool isCanceled;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final color = isCanceled ? AppColors.danger : AppColors.success;
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
        ? l.order_canceled
        : (order.status == OrderStatus.closed
            ? l.order_closed_title
            : l.order_completed_title);

    final at = parseDate(order.raw['closed_at']) ??
        parseDate(order.raw['canceled_at']) ??
        parseDate(order.raw['completed_at']);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.18),
              ),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.3,
              ),
            ),
            if (at != null) ...[
              const SizedBox(height: 4),
              Text(
                _fmt(at),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.text4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mn = d.minute.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}, $hh:$mn';
  }
}

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.order_cancel_reason_label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.danger,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              reason,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.text2,
                height: 1.45,
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
        onTap: route == null ? null : () => context.router.push(route),
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
  const _AddressCard({required this.order});
  final OrderModel order;
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

  void _openLightbox(BuildContext context, List<String> urls, int start) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) =>
            _PhotoLightbox(urls: urls, initialIndex: start),
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
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(color: AppColors.border2),
      ),
      child: Column(
        children: [
          _ReviewLine(label: l.order_review_yours, done: myReviewLeft),
          const SizedBox(height: 10),
          _ReviewLine(
            label:
                isClient ? l.order_review_master : l.order_review_client,
            done: theirReviewLeft,
          ),
          if (canReview) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: onLeaveReview,
                icon: const Icon(Icons.star_rounded,
                    size: 16, color: AppColors.black),
                label: Text(
                  l.review_leave,
                  style: const TextStyle(color: AppColors.black),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.black,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
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
    final l = context.l10n;
    return Row(
      children: [
        Icon(
          done
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 18,
          color: done ? AppColors.success : AppColors.text5,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.text2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          done ? l.order_review_done : l.order_review_pending,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: done ? AppColors.success : AppColors.text5,
          ),
        ),
      ],
    );
  }
}

class _HistoryEntry {
  const _HistoryEntry({required this.status, this.at});
  final String status;
  final DateTime? at;
}

class _HistoryTimeline extends StatelessWidget {
  const _HistoryTimeline({required this.entries});
  final List<_HistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
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
          for (var i = 0; i < entries.length; i++)
            _HistoryStep(
              entry: entries[i],
              isLast: i == entries.length - 1,
            ),
        ],
      ),
    );
  }
}

class _HistoryStep extends StatelessWidget {
  const _HistoryStep({required this.entry, required this.isLast});
  final _HistoryEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final s = OrderStatus.fromValue(entry.status);
    final at = entry.at;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.border2,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s?.label ?? entry.status,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  if (at != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _fmt(at),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.text5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mn = d.minute.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}, $hh:$mn';
  }
}
