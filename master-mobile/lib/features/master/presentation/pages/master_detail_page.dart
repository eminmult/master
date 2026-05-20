import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/user_profile/data/user_profile_repository.dart';
import 'package:master_mobile/shared/widgets/hm_avatar.dart';
import 'package:master_mobile/shared/widgets/hm_icon_button.dart';

/// Rich master profile — data parity with the website's `pages/user/[id].vue`.
/// Backed by `/users/{id}/profile`, which returns master_profile (description,
/// experience, city, radius, languages, is_verified, is_online, is_accepting,
/// urgent_available, completed_orders, categories, skills, portfolio) plus
/// reviews with photos.
///
/// Visual hierarchy puts the master themselves first — avatar, verified
/// badge, name, rating, status chips — and pushes the "what services they
/// offer" list to a tiny subtitle. Reviews and portfolio carry the weight.
class MasterDetailPage extends ConsumerStatefulWidget {
  const MasterDetailPage({super.key, required this.masterId});
  final int masterId;
  @override
  ConsumerState<MasterDetailPage> createState() => _MasterDetailPageState();
}

enum _Tab { portfolio, reviews, skills }

class _MasterDetailPageState extends ConsumerState<MasterDetailPage> {
  _Tab _tab = _Tab.reviews;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final asyncProfile = ref.watch(userProfileProvider(widget.masterId));

    return Scaffold(
      backgroundColor: HmColors.bg,
      body: asyncProfile.when(
        loading: () => const SafeArea(
          child: Center(child: CircularProgressIndicator(color: HmColors.accent, strokeWidth: 2.4)),
        ),
        error: (_, __) => SafeArea(
          child: Center(
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
                  onPressed: () => ref.invalidate(userProfileProvider(widget.masterId)),
                  style: FilledButton.styleFrom(
                    backgroundColor: HmColors.accent,
                    foregroundColor: Colors.black,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(loc.notif_retry),
                ),
              ]),
            ),
          ),
        ),
        data: (profile) => _Body(
          profile: profile,
          tab: _tab,
          onTab: (t) => setState(() => _tab = t),
          masterId: widget.masterId,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.profile,
    required this.tab,
    required this.onTab,
    required this.masterId,
  });
  final Map<String, dynamic> profile;
  final _Tab tab;
  final ValueChanged<_Tab> onTab;
  final int masterId;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final mp = profile['master_profile'] is Map<String, dynamic>
        ? profile['master_profile'] as Map<String, dynamic>
        : <String, dynamic>{};

    final categories = (mp['categories'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final portfolio = (mp['portfolio'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final skills = mp['skills'] is Map<String, dynamic>
        ? mp['skills'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final reviews = (profile['reviews'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    final hasPortfolio = portfolio.isNotEmpty;
    final hasSkills = skills.isNotEmpty;
    final hasReviews = reviews.isNotEmpty;

    final isAccepting = mp['is_accepting'] == true;

    return SafeArea(
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 110),
            children: [
              const _HeaderBar(),
              const SizedBox(height: 4),
              _Hero(profile: profile, mp: mp, categories: categories),
              const SizedBox(height: 18),
              _StatsGrid(profile: profile, mp: mp),
              if (mp['description'] != null && (mp['description'] as String).trim().isNotEmpty) ...[
                const SizedBox(height: 22),
                _Section(title: loc.person_about),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
                  child: Text(
                    mp['description'].toString(),
                    style: const TextStyle(fontSize: 14, color: HmColors.text2, height: 1.55, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
              if (mp['city'] != null) ...[
                const SizedBox(height: 22),
                _Section(title: loc.person_location),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
                  child: _LocationRow(mp: mp),
                ),
              ],
              const SizedBox(height: 22),
              _TabsRow(
                current: tab,
                hasPortfolio: hasPortfolio,
                hasSkills: hasSkills,
                reviewsCount: reviews.length,
                onTap: onTab,
              ),
              const SizedBox(height: 12),
              _TabContent(
                tab: tab,
                portfolio: portfolio,
                reviews: reviews,
                skills: skills,
                hasPortfolio: hasPortfolio,
                hasReviews: hasReviews,
                hasSkills: hasSkills,
              ),
            ],
          ),
          // Sticky bottom CTA
          Align(
            alignment: Alignment.bottomCenter,
            child: _StickyBookingBar(
              isAccepting: isAccepting,
              masterId: profile['id'] as int? ?? masterId,
              fullName: profile['full_name']?.toString() ?? '',
            ),
          ),
        ],
      ),
    );
  }
}

// --- Header bar ------------------------------------------------------------

class _HeaderBar extends StatelessWidget {
  const _HeaderBar();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(children: [
        HmIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          small: true,
          flat: true,
          onPressed: () => context.canPop() ? context.pop() : context.go('/categories'),
        ),
      ]),
    );
  }
}

// --- Hero (avatar + name + rating + chips) --------------------------------

class _Hero extends StatelessWidget {
  const _Hero({required this.profile, required this.mp, required this.categories});
  final Map<String, dynamic> profile;
  final Map<String, dynamic> mp;
  final List<Map<String, dynamic>> categories;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final fullName = profile['full_name']?.toString() ?? '—';
    final avatar = profile['avatar_url']?.toString();
    final ratingAvg =
        double.tryParse(profile['rating_avg']?.toString() ?? '') ?? 0;
    final ratingCount = (profile['rating_count'] as num?)?.toInt() ?? 0;
    final isVerified = mp['is_verified'] == true;
    final isOnline = mp['is_online'] == true;
    final years = (mp['experience_years'] as num?)?.toInt();
    final languages = mp['languages']?.toString();

    // "Subtitle" = small-print categories list. Deliberately tiny: services
    // are secondary; the master & their reviews are the focus.
    final subtitle = categories.isEmpty
        ? loc.role_master.toLowerCase()
        : categories.map((c) => c['name']?.toString() ?? '').where((s) => s.isNotEmpty).join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(children: [
        Stack(clipBehavior: Clip.none, children: [
          if (avatar != null && avatar.isNotEmpty)
            HmAvatar(url: avatar, size: 124, ring: true, online: isOnline)
          else
            Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: HmColors.surface,
                border: Border.all(color: HmColors.accentBorder, width: 2),
              ),
              child: const Icon(Icons.person_rounded, color: HmColors.accent, size: 56),
            ),
          if (isVerified)
            Positioned(
              right: -2, bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: HmColors.bg,
                  borderRadius: BorderRadius.circular(HmRadius.pill),
                  border: Border.all(color: HmColors.accent, width: 1.5),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.verified_rounded, size: 11, color: HmColors.accent),
                  const SizedBox(width: 3),
                  Text(loc.master_verified,
                      style: const TextStyle(
                          fontSize: 9.5, fontWeight: FontWeight.w900, color: HmColors.accent, letterSpacing: 0.5)),
                ]),
              ),
            ),
        ]),
        const SizedBox(height: 14),
        Text(fullName,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.15)),
        if (ratingCount > 0) ...[
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.star_rounded, size: 16, color: HmColors.accent),
            const SizedBox(width: 4),
            Text(ratingAvg.toStringAsFixed(2),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w900, color: HmColors.accent)),
            const SizedBox(width: 6),
            Text('($ratingCount ${loc.master_reviews_short})',
                style: const TextStyle(fontSize: 12.5, color: HmColors.text4, fontWeight: FontWeight.w600)),
          ]),
        ],
        const SizedBox(height: 8),
        // Categories as tiny secondary subtitle.
        if (subtitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              subtitle,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11.5,
                  color: HmColors.text5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  height: 1.4),
            ),
          ),
        const SizedBox(height: 12),
        // Chips row — online / urgent / years / languages.
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            if (isOnline)
              _Chip(
                label: loc.master_online,
                icon: Icons.fiber_manual_record_rounded,
                accent: HmColors.success,
                bg: const Color(0x1F22C55E),
              ),
            if (years != null && years > 0)
              _Chip(
                label: '$years+ ${loc.list_years_exp}',
                icon: Icons.workspace_premium_rounded,
                accent: HmColors.accent,
                bg: HmColors.accentSoft,
              ),
            if (languages != null && languages.trim().isNotEmpty)
              _Chip(
                label: languages,
                icon: Icons.language_rounded,
                accent: HmColors.text2,
                bg: HmColors.surface,
              ),
          ],
        ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.accent,
    required this.bg,
  });
  final String label;
  final IconData icon;
  final Color accent;
  final Color bg;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(HmRadius.pill),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: accent),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: accent)),
      ]),
    );
  }
}

// --- Stats grid (4 cells) -------------------------------------------------

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.profile, required this.mp});
  final Map<String, dynamic> profile;
  final Map<String, dynamic> mp;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final ratingAvg =
        double.tryParse(profile['rating_avg']?.toString() ?? '') ?? 0;
    final ratingCount = (profile['rating_count'] as num?)?.toInt() ?? 0;
    final completed = (mp['completed_orders'] as num?)?.toInt() ?? 0;
    final years = (mp['experience_years'] as num?)?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: HmColors.surface,
          borderRadius: BorderRadius.circular(HmRadius.cardLarge),
          border: Border.all(color: HmColors.border2),
        ),
        child: Row(children: [
          Expanded(
              child: _Stat(value: '$ratingCount', label: loc.master_reviews_short, accent: true)),
          _StatDivider(),
          Expanded(
              child: _Stat(value: ratingAvg.toStringAsFixed(1), label: loc.master_rating)),
          _StatDivider(),
          Expanded(
              child: _Stat(value: '$completed', label: loc.master_completed)),
          _StatDivider(),
          Expanded(
              child: _Stat(value: years > 0 ? '$years' : '—', label: loc.master_experience_short)),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.accent = false});
  final String value;
  final String label;
  final bool accent;
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: accent ? HmColors.accent : HmColors.text,
              letterSpacing: -0.4,
              height: 1.1)),
      const SizedBox(height: 3),
      Text(label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 10.5, fontWeight: FontWeight.w700, color: HmColors.text5, letterSpacing: 0.5)),
    ]);
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 30, color: HmColors.border2);
}

// --- Section header --------------------------------------------------------

class _Section extends StatelessWidget {
  const _Section({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
      child: Text(title.toUpperCase(),
          style: const TextStyle(
              fontSize: 11.5, fontWeight: FontWeight.w900, color: HmColors.text4, letterSpacing: 1.4)),
    );
  }
}

// --- Location row ---------------------------------------------------------

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.mp});
  final Map<String, dynamic> mp;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final city = mp['city']?.toString() ?? '';
    final district = mp['district']?.toString();
    final radius = (mp['work_radius_km'] as num?)?.toInt();

    final parts = <String>[
      city,
      if (district != null && district.isNotEmpty) district,
    ];
    final placeText = parts.join(', ');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: HmColors.surface,
        borderRadius: BorderRadius.circular(HmRadius.cardLarge),
        border: Border.all(color: HmColors.border2),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: HmColors.accentSoft,
            shape: BoxShape.circle,
            border: Border.all(color: HmColors.accentBorder),
          ),
          child: const Icon(Icons.location_on_rounded, size: 18, color: HmColors.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(placeText,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800, color: HmColors.text)),
              if (radius != null && radius > 0) ...[
                const SizedBox(height: 2),
                Text('${loc.master_radius}: $radius ${loc.master_km}',
                    style: const TextStyle(fontSize: 12, color: HmColors.text5, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ]),
    );
  }
}

// --- Tabs ------------------------------------------------------------------

class _TabsRow extends StatelessWidget {
  const _TabsRow({
    required this.current,
    required this.hasPortfolio,
    required this.hasSkills,
    required this.reviewsCount,
    required this.onTap,
  });
  final _Tab current;
  final bool hasPortfolio;
  final bool hasSkills;
  final int reviewsCount;
  final ValueChanged<_Tab> onTap;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          if (hasPortfolio)
            _TabPill(
              label: loc.person_tab_portfolio,
              active: current == _Tab.portfolio,
              onTap: () => onTap(_Tab.portfolio),
            ),
          if (hasPortfolio) const SizedBox(width: 6),
          _TabPill(
            label: '${loc.person_tab_reviews} ($reviewsCount)',
            active: current == _Tab.reviews,
            onTap: () => onTap(_Tab.reviews),
          ),
          if (hasSkills) const SizedBox(width: 6),
          if (hasSkills)
            _TabPill(
              label: loc.person_tab_skills,
              active: current == _Tab.skills,
              onTap: () => onTap(_Tab.skills),
            ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? HmColors.accent : HmColors.surface,
      borderRadius: BorderRadius.circular(HmRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HmRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HmRadius.pill),
            border: Border.all(color: active ? HmColors.accent : HmColors.border2),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.black : HmColors.text3)),
        ),
      ),
    );
  }
}

// --- Tab content ----------------------------------------------------------

class _TabContent extends StatelessWidget {
  const _TabContent({
    required this.tab,
    required this.portfolio,
    required this.reviews,
    required this.skills,
    required this.hasPortfolio,
    required this.hasReviews,
    required this.hasSkills,
  });
  final _Tab tab;
  final List<Map<String, dynamic>> portfolio;
  final List<Map<String, dynamic>> reviews;
  final Map<String, dynamic> skills;
  final bool hasPortfolio;
  final bool hasReviews;
  final bool hasSkills;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final shown = tab == _Tab.portfolio && !hasPortfolio
        ? _Tab.reviews
        : (tab == _Tab.skills && !hasSkills ? _Tab.reviews : tab);

    if (shown == _Tab.portfolio) {
      return _Portfolio(items: portfolio);
    }
    if (shown == _Tab.skills) {
      return _Skills(skills: skills);
    }
    if (reviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Center(
          child: Text(loc.master_no_reviews,
              style: const TextStyle(color: HmColors.text5, fontSize: 13)),
        ),
      );
    }
    return Column(
      children: reviews
          .map((r) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: _ReviewCard(review: r),
              ))
          .toList(),
    );
  }
}

// --- Portfolio -------------------------------------------------------------

class _Portfolio extends StatelessWidget {
  const _Portfolio({required this.items});
  final List<Map<String, dynamic>> items;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemBuilder: (_, i) {
          final it = items[i];
          final src = (it['large_url'] ?? it['medium_url'] ?? it['thumb_url'] ?? it['image_url'])?.toString();
          if (src == null) return const SizedBox.shrink();
          return GestureDetector(
            onTap: () => _openLightbox(context, items, i),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(fit: StackFit.expand, children: [
                Image.network(_resolve(src),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                          color: HmColors.surface2,
                          child: Icon(Icons.image_not_supported_outlined, color: HmColors.text5),
                        )),
                if (it['title'] != null && it['title'].toString().isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xCC000000)],
                        ),
                      ),
                      child: Text(it['title'].toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
              ]),
            ),
          );
        },
      ),
    );
  }

  void _openLightbox(BuildContext context, List<Map<String, dynamic>> all, int initial) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _Lightbox(
        urls: all
            .map((it) =>
                (it['large_url'] ?? it['medium_url'] ?? it['image_url'] ?? it['thumb_url'])
                    ?.toString())
            .whereType<String>()
            .map(_resolve)
            .toList(),
        initial: initial,
      ),
    ));
  }
}

// --- Lightbox --------------------------------------------------------------

class _Lightbox extends StatefulWidget {
  const _Lightbox({required this.urls, required this.initial});
  final List<String> urls;
  final int initial;
  @override
  State<_Lightbox> createState() => _LightboxState();
}

class _LightboxState extends State<_Lightbox> {
  late final PageController _ctrl = PageController(initialPage: widget.initial);
  int _idx = 0;
  @override
  void initState() {
    super.initState();
    _idx = widget.initial;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView.builder(
          controller: _ctrl,
          itemCount: widget.urls.length,
          onPageChanged: (i) => setState(() => _idx = i),
          itemBuilder: (_, i) => InteractiveViewer(
            child: Center(
              child: Image.network(widget.urls[i],
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded,
                      size: 64, color: Colors.white24)),
            ),
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
        Positioned(
          bottom: 24, left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(HmRadius.pill),
              ),
              child: Text('${_idx + 1} / ${widget.urls.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ]),
    );
  }
}

// --- Reviews --------------------------------------------------------------

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final Map<String, dynamic> review;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final text = review['text']?.toString() ?? '';
    final reviewer = review['reviewer_name']?.toString() ??
        review['reviewer']?['full_name']?.toString() ??
        loc.common_user;
    final created = DateTime.tryParse(review['created_at']?.toString() ?? '');
    final photos = (review['photos'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        const <Map<String, dynamic>>[];
    final initial = reviewer.isNotEmpty ? reviewer[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HmColors.surface,
        borderRadius: BorderRadius.circular(HmRadius.cardLarge),
        border: Border.all(color: HmColors.border2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: HmColors.accentSoft,
                border: Border.all(color: HmColors.accentBorder),
              ),
              child: Center(
                child: Text(initial,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w900, color: HmColors.accent)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(reviewer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800, color: HmColors.text)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: HmColors.accentSoft,
                        borderRadius: BorderRadius.circular(HmRadius.pill),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.verified_rounded, size: 9, color: HmColors.accent),
                        const SizedBox(width: 2),
                        Text(loc.person_verified,
                            style: const TextStyle(
                                fontSize: 8.5, fontWeight: FontWeight.w900, color: HmColors.accent, letterSpacing: 0.3)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 3),
                  Row(children: [
                    ...List.generate(
                      5,
                      (i) => Icon(
                          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: HmColors.accent,
                          size: 13),
                    ),
                    if (created != null) ...[
                      const SizedBox(width: 8),
                      Text('· ${_formatDate(created)}',
                          style: const TextStyle(
                              fontSize: 11, color: HmColors.text5, fontWeight: FontWeight.w600)),
                    ],
                  ]),
                ],
              ),
            ),
          ]),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(text,
                style: const TextStyle(
                    fontSize: 13, color: HmColors.text2, height: 1.5, fontWeight: FontWeight.w500)),
          ],
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final p = photos[i];
                  final thumb = (p['thumb'] ?? p['medium'] ?? p['large'])?.toString();
                  if (thumb == null) return const SizedBox.shrink();
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => _Lightbox(
                          urls: photos
                              .map((p) =>
                                  (p['large'] ?? p['medium'] ?? p['thumb'])?.toString())
                              .whereType<String>()
                              .map(_resolve)
                              .toList(),
                          initial: i,
                        ),
                      ));
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(_resolve(thumb),
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                                width: 76,
                                height: 76,
                                color: HmColors.surface2,
                                child: const Icon(Icons.image_not_supported_outlined,
                                    size: 18, color: HmColors.text5),
                              )),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _resolve(String url) {
  // Backend sometimes returns site-relative paths like `/storage/...`. Make
  // them absolute so Image.network can load them via the production host.
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  if (url.startsWith('/')) return 'https://itez.app$url';
  return url;
}

String _formatDate(DateTime d) {
  final dt = d.toLocal();
  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${dt.day} ${months[(dt.month - 1).clamp(0, 11)]} ${dt.year}';
}

// --- Skills ---------------------------------------------------------------

class _Skills extends StatelessWidget {
  const _Skills({required this.skills});
  final Map<String, dynamic> skills;
  @override
  Widget build(BuildContext context) {
    final groups = skills.entries.toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          for (final g in groups) ...[
            _SkillGroup(name: g.key, items: (g.value as List).cast<Map<String, dynamic>>()),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _SkillGroup extends StatelessWidget {
  const _SkillGroup({required this.name, required this.items});
  final String name;
  final List<Map<String, dynamic>> items;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        color: HmColors.surface,
        borderRadius: BorderRadius.circular(HmRadius.cardLarge),
        border: Border.all(color: HmColors.border2),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: HmColors.accentSoft,
            shape: BoxShape.circle,
            border: Border.all(color: HmColors.accentBorder),
          ),
          child: const Icon(Icons.shield_outlined, size: 18, color: HmColors.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w800, color: HmColors.text)),
              const SizedBox(height: 4),
              Text(
                items.map((e) => e['name']?.toString() ?? '').where((s) => s.isNotEmpty).join(' · '),
                style: const TextStyle(fontSize: 12, color: HmColors.text4, height: 1.45, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// --- Sticky booking bar ---------------------------------------------------

class _StickyBookingBar extends StatelessWidget {
  const _StickyBookingBar({
    required this.isAccepting,
    required this.masterId,
    required this.fullName,
  });
  final bool isAccepting;
  final int masterId;
  final String fullName;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: HmColors.bg.withOpacity(0.96),
        border: const Border(top: BorderSide(color: HmColors.border)),
      ),
      child: Row(children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: isAccepting ? HmColors.success : HmColors.text5,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isAccepting ? loc.person_available_today : loc.master_not_accepting_now,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isAccepting ? HmColors.success : HmColors.text5,
                letterSpacing: 0.2),
          ),
        ),
        SizedBox(
          height: 44,
          child: FilledButton.icon(
            onPressed: !isAccepting
                ? null
                : () {
                    final encoded = Uri.encodeComponent(fullName);
                    context.push('/order/create?master_id=$masterId&master_name=$encoded');
                  },
            icon: const Icon(Icons.event_available_rounded, size: 16, color: Colors.black),
            label: Text(loc.master_book_appointment,
                style: const TextStyle(color: Colors.black)),
            style: FilledButton.styleFrom(
              backgroundColor: HmColors.accent,
              foregroundColor: Colors.black,
              disabledBackgroundColor: HmColors.surface2,
              disabledForegroundColor: HmColors.text5,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ]),
    );
  }
}
// poke 1778321810
// poke 1778322351
