import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/i18n/category_helpers.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/l10n/generated/app_localizations.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/categories/data/categories_repository.dart';
import 'package:master_mobile/features/master/data/masters_repository.dart';
import 'package:master_mobile/shared/widgets/hm_avatar.dart';
import 'package:master_mobile/shared/widgets/hm_icon_button.dart';

/// Resolves the slug from the URL into a backend `category_id` so the
/// /masters API filter works, then fetches the matching masters.
///
/// We resolve against the FULL active-category list (not `onlyWithMasters`)
/// so a category that legitimately has zero masters yet still shows the
/// "no results" empty state instead of silently falling back to every
/// master in the database.
final _mastersForSlugProvider =
    FutureProvider.autoDispose.family<List<MasterListItem>, String?>((ref, slug) async {
  final masters = ref.watch(mastersRepositoryProvider);
  if (slug == null || slug.isEmpty) {
    final res = await masters.list();
    return res.items;
  }
  final cats = await ref.watch(categoriesRepositoryProvider).list();
  final matched = cats.where((c) => c.slug == slug).toList();
  if (matched.isEmpty) {
    // Truly unknown slug — show empty state, not the whole catalog.
    return const [];
  }
  final res = await masters.list(categoryId: matched.first.id);
  return res.items;
});

class SpecialistListPage extends ConsumerStatefulWidget {
  const SpecialistListPage({super.key, this.title, this.categoryId});

  /// Pre-localized category name passed via go_router `extra` from the home
  /// row or the categories grid. When null, we resolve a title from the slug
  /// using the same ARB mapping used by the tile row.
  final String? title;

  /// `categoryId` is actually the slug (e.g. `santexnik`) — the backend API
  /// uses numeric ids, so we resolve slug→id inside `_mastersForSlugProvider`.
  final String? categoryId;

  @override
  ConsumerState<SpecialistListPage> createState() => _SpecialistListPageState();
}

class _SpecialistListPageState extends ConsumerState<SpecialistListPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final asyncMasters = ref.watch(_mastersForSlugProvider(widget.categoryId));
    final headerTitle = widget.title ??
        _slugTitle(loc, widget.categoryId) ??
        loc.cat_all_categories;

    return Scaffold(
      backgroundColor: HmColors.bg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      HmIconButton(icon: Icons.arrow_back_ios_new_rounded, small: true, flat: true,
                          onPressed: () => context.canPop() ? context.pop() : context.go('/categories')),
                      Expanded(child: Center(child: Text(headTitleClipped(headerTitle),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)))),
                      const SizedBox(width: 32),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: loc.list_search_hint,
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: HmColors.text4),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: asyncMasters.when(
                    data: (masters) {
                      final filtered = _filter(masters, _query);
                      if (filtered.isEmpty) {
                        return Center(child: Text(loc.list_no_results,
                            style: const TextStyle(color: HmColors.text5)));
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (_, i) => _SpecialistCard(
                          master: filtered[i],
                          onTap: () => context.push('/master/${filtered[i].id}'),
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
        ],
      ),
    );
  }

  static String headTitleClipped(String t) => t.length > 32 ? '${t.substring(0, 30)}…' : t;

  static String? _slugTitle(AppLocalizations loc, String? slug) {
    if (slug == null) return null;
    return localizedCategoryName(loc, ServiceCategory(id: 0, name: slug, slug: slug));
  }

  List<MasterListItem> _filter(List<MasterListItem> items, String q) {
    if (q.trim().isEmpty) return items;
    final needle = q.toLowerCase();
    return items.where((m) {
      if (m.fullName.toLowerCase().contains(needle)) return true;
      if (m.description != null && m.description!.toLowerCase().contains(needle)) return true;
      if (m.city != null && m.city!.toLowerCase().contains(needle)) return true;
      return false;
    }).toList();
  }

}

class _SpecialistCard extends StatelessWidget {
  const _SpecialistCard({required this.master, required this.onTap});
  final MasterListItem master;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final ratingStr = (master.ratingAvg != null && master.ratingAvg!.isNotEmpty)
        ? double.tryParse(master.ratingAvg!)?.toStringAsFixed(1) ?? master.ratingAvg!
        : '—';

    String? roleText;
    final cats = master.categories;
    if (cats != null && cats.isNotEmpty && cats.first is Map<String, dynamic>) {
      final cat = ServiceCategory.fromJson(cats.first as Map<String, dynamic>);
      roleText = localizedCategoryName(loc, cat);
    }
    final years = master.experienceYears;
    final subtitle = [
      if (roleText != null) roleText,
      if (years > 0) '$years ${loc.list_years_exp}',
    ].join(' • ');

    final available = master.isActive;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HmColors.surface3,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x14FFFFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (master.avatarUrl != null)
                  HmAvatar(url: master.avatarUrl!, size: 56, ring: true, online: available)
                else
                  Container(
                    width: 56, height: 56,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: HmColors.surface2),
                    child: const Icon(Icons.person_rounded, color: HmColors.text5),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(master.fullName,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: HmColors.text4)),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 13, color: HmColors.accent),
                          const SizedBox(width: 4),
                          Text(ratingStr,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: HmColors.accent)),
                          const SizedBox(width: 4),
                          Text(loc.list_reviews_n(master.ratingCount),
                              style: const TextStyle(fontSize: 12, color: HmColors.text6)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: available ? HmColors.accentSoft : const Color(0x1AEF4444),
                    borderRadius: BorderRadius.circular(HmRadius.pill),
                  ),
                  child: Text(available ? loc.list_available : loc.list_busy,
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: available ? HmColors.accent : HmColors.danger,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                child: Text(loc.list_book_appointment),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
