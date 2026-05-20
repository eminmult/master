import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/auth/auth_controller.dart';
import 'package:master_mobile/core/i18n/category_helpers.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/addresses/data/active_address_controller.dart';
import 'package:master_mobile/features/addresses/data/addresses_repository.dart';
import 'package:master_mobile/features/addresses/presentation/address_picker_sheet.dart';
import 'package:master_mobile/features/categories/data/categories_repository.dart';
import 'package:master_mobile/features/home/data/home_providers.dart';
import 'package:master_mobile/features/master/data/masters_repository.dart';
import 'package:master_mobile/features/orders/data/models/public_order.dart';
import 'package:master_mobile/features/smart_search/presentation/smart_search_widget.dart';
import 'package:master_mobile/shared/widgets/hm_avatar.dart';
import 'package:master_mobile/shared/widgets/hm_bottom_nav.dart';
import 'package:master_mobile/shared/widgets/hm_notification_bell.dart';
import 'package:master_mobile/shared/widgets/hm_section_head.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.l10n;
    final auth = ref.watch(authStateProvider);
    final mastersAsync = ref.watch(homeRecommendedMastersProvider);
    final annAsync = ref.watch(homeAnnouncementsProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    final isGuest = user == null;
    final avatarUrl = user?.avatarUrl;

    return Scaffold(
      backgroundColor: HmColors.bg,
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 110),
              children: [
                // Header — avatar + Wolt-style address bar + bell
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(HmRadius.pill),
                        onTap: () => isGuest ? context.go('/login') : context.go('/profile'),
                        child: avatarUrl != null
                            ? HmAvatar(url: avatarUrl, size: 40, ring: true)
                            : Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: HmColors.surface,
                                  border: Border.all(color: HmColors.border, width: 1.5),
                                ),
                                child: Icon(
                                  isGuest ? Icons.person_outline_rounded : Icons.person_rounded,
                                  color: HmColors.accent, size: 20,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AddressBar(isGuest: isGuest),
                      ),
                      const SizedBox(width: 8),
                      HmNotificationBell(
                        onTap: () => context.push('/notifications'),
                      ),
                    ],
                  ),
                ),
                // AI Smart Search — describe the issue + photo, Gemini picks
                // the right category and we jump to its specialist list.
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 12, 24, 4),
                  child: SmartSearchWidget(),
                ),
                const SizedBox(height: 8),
                // Recommended masters
                HmSectionHead(
                  title: loc.home_recommended,
                  linkLabel: loc.common_see_all,
                  onLinkTap: () => context.push('/categories'),
                ),
                _MastersRow(
                  async: mastersAsync,
                  onTapMaster: (m) => context.push('/master/${m.id}'),
                  onRetry: () => ref.invalidate(homeRecommendedMastersProvider),
                ),
                const SizedBox(height: 16),
                // Announcements
                HmSectionHead(
                  title: loc.ann_title,
                  linkLabel: loc.common_see_all,
                  onLinkTap: () => context.push('/announcements'),
                ),
                _AnnouncementsRow(
                  async: annAsync,
                  onTap: (id) => context.push('/announcements/$id'),
                  onRetry: () => ref.invalidate(homeAnnouncementsProvider),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: HmBottomNav(
              active: HmTab.home,
              onChanged: (t) => _onTab(context, t),
            ),
          ),
        ],
      ),
    );
  }

  void _onTab(BuildContext context, HmTab tab) {
    switch (tab) {
      case HmTab.home: break;
      case HmTab.bookings: context.go('/orders'); break;
      case HmTab.announcements: context.go('/announcements'); break;
      case HmTab.profile: context.go('/profile'); break;
    }
  }
}

// ---------------------------------------------------------------------------
// Wolt-style address bar — shown in the home header in place of the user's
// name. Three states:
//   1. Guest                   → "Daxil ol / Qeydiyyat" CTA, taps to /login.
//   2. Auth + no addresses     → "+ Ünvan əlavə et" CTA, taps to /addresses/new.
//   3. Auth + has addresses    → label / full address + chevron,
//                                 taps to open the bottom sheet picker.
// ---------------------------------------------------------------------------

class _AddressBar extends ConsumerWidget {
  const _AddressBar({required this.isGuest});
  final bool isGuest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.l10n;

    if (isGuest) {
      return _BarShell(
        onTap: () => context.go('/login'),
        smallLabel: loc.home_welcome,
        title: loc.home_sign_in_register,
        leading: Icons.login_rounded,
      );
    }

    final addressesAsync = ref.watch(addressesListProvider);
    return addressesAsync.when(
      loading: () => _BarShell(
        onTap: null,
        smallLabel: loc.address_label_caps,
        title: loc.home_loading,
        leading: Icons.location_on_outlined,
        muted: true,
      ),
      error: (_, __) => _BarShell(
        onTap: () => ref.invalidate(addressesListProvider),
        smallLabel: loc.address_label_caps,
        title: loc.home_load_error,
        leading: Icons.location_off_outlined,
        muted: true,
      ),
      data: (list) {
        if (list.isEmpty) {
          return _BarShell(
            onTap: () => context.push('/addresses/new'),
            smallLabel: loc.address_label_caps,
            title: loc.address_add_new,
            leading: Icons.add_location_alt_rounded,
            accentTitle: true,
          );
        }
        final active = ref.watch(activeAddressProvider);
        return _BarShell(
          onTap: () => showAddressPickerSheet(context),
          smallLabel: loc.address_label_caps,
          title: _formatAddress(active),
          leading: Icons.location_on_rounded,
          showChevron: true,
        );
      },
    );
  }

  static String _formatAddress(Address? a) {
    if (a == null) return '—';
    final label = a.label?.trim();
    if (label != null && label.isNotEmpty) return '$label · ${a.fullAddress}';
    return a.fullAddress;
  }
}

class _BarShell extends StatelessWidget {
  const _BarShell({
    required this.onTap,
    required this.smallLabel,
    required this.title,
    required this.leading,
    this.showChevron = false,
    this.accentTitle = false,
    this.muted = false,
  });

  final VoidCallback? onTap;
  final String smallLabel;
  final String title;
  final IconData leading;
  final bool showChevron;
  final bool accentTitle;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(smallLabel,
                style: const TextStyle(
                    fontSize: 10,
                    color: HmColors.text5,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Row(children: [
              Icon(leading,
                  size: 16,
                  color: muted ? HmColors.text5 : HmColors.accent),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: muted
                        ? HmColors.text4
                        : (accentTitle ? HmColors.accent : HmColors.text),
                  ),
                ),
              ),
              if (showChevron) ...[
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: HmColors.text4),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recommended masters carousel
// ---------------------------------------------------------------------------

/// 2-column grid of master cards, embedded inside the home `ListView`. We
/// disable inner scrolling and shrink-wrap so the page itself scrolls past
/// the grid — gives the home a long, browsable feel rather than a stubby
/// sideways carousel.
class _MastersRow extends StatelessWidget {
  const _MastersRow({required this.async, required this.onTapMaster, required this.onRetry});
  final AsyncValue<List<MasterListItem>> async;
  final void Function(MasterListItem) onTapMaster;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return async.when(
      data: (masters) {
        if (masters.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(loc.list_no_results, style: const TextStyle(color: HmColors.text5, fontSize: 13)),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: masters.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              // Square photo (1:1) + ~92px text area = card ~268 tall.
              // childAspectRatio = width / height; with 380/2-12/2 = 184px wide
              // and 268 tall, ratio is ~0.685.
              childAspectRatio: 0.685,
            ),
            itemBuilder: (_, i) => _MasterCard(
              master: masters[i],
              onTap: () => onTapMaster(masters[i]),
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: HmColors.accent, strokeWidth: 2.4)),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: TextButton(
            onPressed: onRetry,
            child: Text(loc.home_load_error, style: const TextStyle(color: HmColors.text5, fontSize: 12)),
          ),
        ),
      ),
    );
  }
}

/// Compact grid card — square photo with a rating chip overlay, then name,
/// role · years on one muted line, and a reviews-count strap. No standalone
/// "book" CTA; the whole card taps to /master/<id>.
class _MasterCard extends StatelessWidget {
  const _MasterCard({required this.master, required this.onTap});
  final MasterListItem master;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final ratingStr = (master.ratingAvg != null && master.ratingAvg!.isNotEmpty)
        ? double.tryParse(master.ratingAvg!)?.toStringAsFixed(1) ?? master.ratingAvg!
        : '—';
    final hasRating = master.ratingCount > 0;

    String? roleText;
    final cats = master.categories;
    if (cats != null && cats.isNotEmpty && cats.first is Map<String, dynamic>) {
      final cat = ServiceCategory.fromJson(cats.first as Map<String, dynamic>);
      roleText = localizedCategoryName(loc, cat);
    }
    final years = master.experienceYears;
    final yearsLabel = years > 0 ? '$years ${loc.list_years_exp}' : null;

    return Material(
      color: HmColors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: HmColors.border2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Square photo at top with rating + availability overlays.
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (master.avatarUrl != null)
                      Image.network(
                        master.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: HmColors.surface2,
                          child: Icon(Icons.person_rounded, size: 48, color: HmColors.text5),
                        ),
                      )
                    else
                      const ColoredBox(
                        color: HmColors.surface2,
                        child: Icon(Icons.person_rounded, size: 48, color: HmColors.text5),
                      ),
                    // Subtle bottom-up gradient so the rating chip reads
                    // even on bright photos.
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                            colors: [Color(0x99000000), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    // Rating chip — yellow accent pill bottom-left.
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: HmColors.accent,
                          borderRadius: BorderRadius.circular(HmRadius.pill),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.star_rounded, size: 11, color: Colors.black),
                          const SizedBox(width: 3),
                          Text(
                            ratingStr,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black, height: 1),
                          ),
                          if (hasRating) ...[
                            const SizedBox(width: 3),
                            Text(
                              '(${master.ratingCount})',
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black87, height: 1),
                            ),
                          ],
                        ]),
                      ),
                    ),
                    // Online dot — small green pill bottom-right when active.
                    if (master.isActive)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: HmColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: HmColors.surface, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Text body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        master.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: HmColors.text,
                            letterSpacing: -0.2,
                            height: 1.15),
                      ),
                      if (roleText != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          roleText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: HmColors.accent,
                              letterSpacing: 0.1,
                              height: 1.2),
                        ),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          if (yearsLabel != null) ...[
                            const Icon(Icons.workspace_premium_rounded,
                                size: 11, color: HmColors.text5),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                yearsLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11, color: HmColors.text4, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ] else if (master.city != null) ...[
                            const Icon(Icons.location_on_outlined, size: 11, color: HmColors.text5),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                master.city!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11, color: HmColors.text4, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Announcements carousel
// ---------------------------------------------------------------------------

/// 2-column grid of announcement cards. Same shrink-wrap pattern as the
/// masters grid — feeds the home page a long, browsable feel.
class _AnnouncementsRow extends StatelessWidget {
  const _AnnouncementsRow({required this.async, required this.onTap, required this.onRetry});
  final AsyncValue<List<PublicOrderItem>> async;
  final void Function(int id) onTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return async.when(
      data: (items) {
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(loc.ann_empty_title,
                  style: const TextStyle(color: HmColors.text5, fontSize: 13)),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.685,
            ),
            itemBuilder: (_, i) => _AnnMiniCard(
              order: items[i],
              onTap: () => onTap(items[i].id),
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: HmColors.accent, strokeWidth: 2.4)),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: TextButton(
            onPressed: onRetry,
            child: Text(loc.home_load_error, style: const TextStyle(color: HmColors.text5, fontSize: 12)),
          ),
        ),
      ),
    );
  }
}

/// Grid card for an announcement. Photo (or category-icon stub if none)
/// fills the top half; below comes the category accent label, the
/// description, and a meta row with a small client avatar + city + budget.
/// The avatar is intentionally tiny — the announcement (what + where + how
/// much) is the focus, the client is just a footnote.
class _AnnMiniCard extends StatelessWidget {
  const _AnnMiniCard({required this.order, required this.onTap});
  final PublicOrderItem order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;

    String categoryName = loc.order_service_fallback;
    String? categorySlug;
    final cat = order.category;
    if (cat != null && cat['slug'] != null) {
      final c = ServiceCategory.fromJson(cat);
      categoryName = localizedCategoryName(loc, c);
      categorySlug = c.slug;
    } else if (cat != null && cat['name'] != null) {
      categoryName = cat['name'].toString();
    }
    final budget = order.estimatedBudget;
    final clientAvatar = order.client?['avatar_url']?.toString();
    final firstPhoto = order.firstPhoto;

    return Material(
      color: HmColors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: HmColors.border2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Media area — photo if present, accent-soft stub with the
              // category icon if not. URGENT chip + +N badge overlaid.
              AspectRatio(
                aspectRatio: 1.25,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (firstPhoto != null)
                      Image.network(
                        firstPhoto,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _CategoryStub(slug: categorySlug),
                      )
                    else
                      _CategoryStub(slug: categorySlug),
                    if (firstPhoto != null)
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.center,
                              colors: [Color(0x66000000), Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                    if (firstPhoto != null && order.photosCount > 1)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(HmRadius.pill),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.photo_library_rounded, size: 10, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              '+${order.photosCount - 1}',
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),
              // Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category as accent label
                      Text(
                        categoryName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: HmColors.accent,
                            letterSpacing: 0.7,
                            height: 1.1),
                      ),
                      const SizedBox(height: 4),
                      // Description (or fallback to category if missing)
                      Expanded(
                        child: Text(
                          (order.description?.trim().isNotEmpty ?? false)
                              ? order.description!.trim()
                              : categoryName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12.5,
                              color: HmColors.text2,
                              fontWeight: FontWeight.w600,
                              height: 1.3),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Meta row — small avatar + city + budget. Avatar is
                      // a footnote, the budget is the loud bit.
                      Row(
                        children: [
                          // Tiny avatar (16px) — deliberately small.
                          if (clientAvatar != null)
                            ClipOval(
                              child: Image.network(
                                clientAvatar,
                                width: 16,
                                height: 16,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const _AvatarStub(),
                              ),
                            )
                          else
                            const _AvatarStub(),
                          const SizedBox(width: 5),
                          if (order.district != null && order.district!.trim().isNotEmpty)
                            Flexible(
                              child: Text(
                                order.district!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 10.5, color: HmColors.text5, fontWeight: FontWeight.w600),
                              ),
                            )
                          else
                            const Spacer(),
                          if (budget != null && budget.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: HmColors.accentSoft,
                                borderRadius: BorderRadius.circular(HmRadius.pill),
                              ),
                              child: Text(
                                '$budget AZN',
                                style: const TextStyle(
                                    fontSize: 10.5, fontWeight: FontWeight.w900, color: HmColors.accent, height: 1.1),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fallback media block shown when the announcement has no photos.
/// Soft accent gradient + the category's icon — keeps the grid visually
/// rhythmic instead of leaving a blank rectangle.
class _CategoryStub extends StatelessWidget {
  const _CategoryStub({this.slug});
  final String? slug;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x33FFFF00), Color(0x10FFFF00)],
        ),
      ),
      child: Center(
        child: Icon(
          iconForCategorySlug(slug),
          size: 44,
          color: HmColors.accent.withOpacity(0.55),
        ),
      ),
    );
  }
}

class _AvatarStub extends StatelessWidget {
  const _AvatarStub();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: HmColors.surface2),
      child: const Icon(Icons.person_rounded, size: 10, color: HmColors.text5),
    );
  }
}
// rebuild trigger 1778273251
