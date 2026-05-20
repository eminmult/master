import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/i18n/category_helpers.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/categories/data/categories_repository.dart';
import 'package:master_mobile/features/orders/data/models/public_order.dart';
import 'package:master_mobile/features/orders/data/orders_repository.dart';
import 'package:master_mobile/shared/widgets/hm_avatar.dart';
import 'package:master_mobile/shared/widgets/hm_bottom_nav.dart';
import 'package:master_mobile/shared/widgets/hm_icon_button.dart';

/// Public order feed — mirrors the website's `/orders` page. Lists open
/// announcements that masters can browse and apply to.
final _announcementsProvider =
    FutureProvider.autoDispose<List<PublicOrderItem>>((ref) async {
  final res = await ref.watch(ordersRepositoryProvider).publicFeed();
  return res.items;
});

class AnnouncementsPage extends ConsumerStatefulWidget {
  const AnnouncementsPage({super.key});
  @override
  ConsumerState<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends ConsumerState<AnnouncementsPage> {
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final asyncOrders = ref.watch(_announcementsProvider);

    return Scaffold(
      backgroundColor: HmColors.bg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      HmIconButton(icon: Icons.arrow_back_ios_new_rounded, small: true, flat: true,
                          onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(loc.ann_title,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
                              asyncOrders.maybeWhen(
                                data: (orders) => Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(loc.ann_subtitle_n(orders.length),
                                      style: const TextStyle(fontSize: 12, color: HmColors.text5)),
                                ),
                                orElse: () => const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: asyncOrders.when(
                    data: (orders) {
                      final filtered = orders;
                      if (filtered.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.inbox_rounded, color: HmColors.text5, size: 48),
                                const SizedBox(height: 12),
                                Text(loc.ann_empty_title, textAlign: TextAlign.center,
                                    style: const TextStyle(color: HmColors.text4, fontSize: 16, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text(loc.ann_empty_desc, textAlign: TextAlign.center,
                                    style: const TextStyle(color: HmColors.text5, fontSize: 13, height: 1.5)),
                              ],
                            ),
                          ),
                        );
                      }
                      return RefreshIndicator(
                        color: HmColors.accent,
                        backgroundColor: HmColors.surface,
                        onRefresh: () => ref.refresh(_announcementsProvider.future),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _AnnCard(
                            order: filtered[i],
                            onTap: () => context.push('/announcements/${filtered[i].id}'),
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: HmColors.accent)),
                    error: (_, __) => Center(child: Text(loc.auth_failed_to_load,
                        style: const TextStyle(color: HmColors.danger))),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: HmBottomNav(
              active: HmTab.announcements,
              onChanged: (t) => _onTab(context, t),
            ),
          ),
        ],
      ),
    );
  }

  void _onTab(BuildContext context, HmTab tab) {
    switch (tab) {
      case HmTab.home: context.go('/home'); break;
      case HmTab.bookings: context.go('/orders'); break;
      case HmTab.announcements: break;
      case HmTab.profile: context.go('/profile'); break;
    }
  }
}

class _AnnCard extends StatelessWidget {
  const _AnnCard({required this.order, required this.onTap});
  final PublicOrderItem order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;

    String categoryName = loc.order_service_fallback;
    final cat = order.category;
    if (cat != null && cat['slug'] != null) {
      categoryName = localizedCategoryName(loc, ServiceCategory.fromJson(cat));
    } else if (cat != null && cat['name'] != null) {
      categoryName = cat['name'].toString();
    }

    final budget = order.estimatedBudget;
    final clientAvatar = order.client?['avatar_url']?.toString();
    final clientName = (order.client?['first_name'] ?? loc.common_user).toString();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HmRadius.cardLarge),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: HmColors.surface,
          borderRadius: BorderRadius.circular(HmRadius.cardLarge),
          border: Border.all(color: HmColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: client avatar + name
            Row(
              children: [
                if (clientAvatar != null)
                  HmAvatar(url: clientAvatar, size: 36, ring: false)
                else
                  Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: HmColors.surface2),
                    child: const Icon(Icons.person_rounded, color: HmColors.text5, size: 18),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(clientName, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      if (order.district != null && order.district!.isNotEmpty)
                        Text(order.district!,
                            style: const TextStyle(fontSize: 11, color: HmColors.text5)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Photo + description side-by-side if there's a thumbnail
            if (order.firstPhoto != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Image.network(order.firstPhoto!, fit: BoxFit.cover,
                            width: double.infinity, height: 140,
                            errorBuilder: (_, __, ___) => Container(color: HmColors.surface2)),
                        if (order.photosCount > 1)
                          Positioned(
                            top: 8, right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(HmRadius.pill),
                              ),
                              child: Text('+${order.photosCount - 1}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            // Category pill
            Wrap(
              spacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: HmColors.accentSoft,
                    borderRadius: BorderRadius.circular(HmRadius.pill),
                    border: Border.all(color: HmColors.accentBorder),
                  ),
                  child: Text(categoryName,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: HmColors.accent, letterSpacing: 0.4)),
                ),
              ],
            ),
            if (order.description != null && order.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(order.description!, maxLines: 3, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: HmColors.text3, height: 1.45)),
            ],
            if (budget != null && budget.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('~$budget AZN',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: HmColors.accent)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
