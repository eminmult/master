import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/user_profile/data/user_profile_repository.dart';
import 'package:master_mobile/shared/widgets/hm_avatar.dart';
import 'package:master_mobile/shared/widgets/hm_icon_button.dart';

/// Public profile page (`/user/<id>`). Serves both clients and masters using
/// the unified `/users/{id}/profile` payload — for masters it links out to
/// the richer `/master/<id>` page, for clients it shows the only signals we
/// have (rating, reviews received, when they joined). Phone/email stay
/// hidden — those only appear inside an active order.
class UserDetailPage extends ConsumerWidget {
  const UserDetailPage({super.key, required this.userId});
  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.l10n;
    final asyncProfile = ref.watch(userProfileProvider(userId));

    return Scaffold(
      backgroundColor: HmColors.bg2,
      body: SafeArea(
        child: asyncProfile.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
                color: HmColors.accent, strokeWidth: 2.4),
          ),
          error: (_, __) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline_rounded,
                    size: 32, color: HmColors.danger),
                const SizedBox(height: 12),
                Text(loc.auth_failed_to_load,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: HmColors.text3)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(userProfileProvider(userId)),
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
          data: (data) => _Body(profile: data),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.profile});
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final isMaster = profile['role']?.toString() == 'master';
    final mp = profile['master_profile'] is Map<String, dynamic>
        ? profile['master_profile'] as Map<String, dynamic>
        : null;
    final reviews = (profile['reviews'] as List?)?.cast<Map<String, dynamic>>() ??
        const [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
      children: [
        _Header(),
        _Hero(profile: profile, mp: mp, isMaster: isMaster),
        const SizedBox(height: 14),
        _Stats(profile: profile, isMaster: isMaster),
        if (isMaster && mp != null) ...[
          const SizedBox(height: 18),
          _MasterFacts(mp: mp),
        ],
        if (isMaster && (mp?['description']?.toString().trim().isNotEmpty ?? false)) ...[
          const SizedBox(height: 18),
          _SectionLabel(loc.profile_about),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: HmColors.surface,
                borderRadius: BorderRadius.circular(HmRadius.card),
                border: Border.all(color: HmColors.border2),
              ),
              child: Text(mp!['description'].toString(),
                  style: const TextStyle(
                      fontSize: 13.5, color: HmColors.text2, height: 1.45)),
            ),
          ),
        ],
        if (reviews.isNotEmpty) ...[
          const SizedBox(height: 18),
          _SectionLabel(loc.profile_recent_reviews),
          const SizedBox(height: 8),
          for (final r in reviews.take(5)) _ReviewCard(r: r),
        ] else ...[
          const SizedBox(height: 18),
          _NoReviewsCard(isMaster: isMaster),
        ],
        if (isMaster) ...[
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity, height: 48,
              child: FilledButton.icon(
                onPressed: () => context.push('/master/${profile['id']}'),
                icon: const Icon(Icons.open_in_new_rounded,
                    size: 16, color: Colors.black),
                label: Text(loc.profile_view_full,
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
          ),
        ],
      ],
    );
  }
}

// ===== Header =====

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(children: [
        HmIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          small: true, flat: true,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        const Spacer(),
      ]),
    );
  }
}

// ===== Hero =====

class _Hero extends StatelessWidget {
  const _Hero({required this.profile, this.mp, required this.isMaster});
  final Map<String, dynamic> profile;
  final Map<String, dynamic>? mp;
  final bool isMaster;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final fullName = (profile['full_name'] ??
            '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'
                .trim())
        .toString();
    final avatar = profile['avatar_url']?.toString();
    final ratingAvg = double.tryParse(profile['rating_avg']?.toString() ?? '');
    final ratingCount = (profile['rating_count'] as num?)?.toInt() ?? 0;
    final isOnline = mp?['is_online'] == true;
    final isVerified =
        profile['is_verified'] == true || mp?['is_verified'] == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x14FFFF00), Color(0x05FFFF00)],
          ),
          borderRadius: BorderRadius.circular(HmRadius.cardLarge),
          border: Border.all(color: HmColors.accentBorder),
        ),
        child: Column(children: [
          Stack(clipBehavior: Clip.none, children: [
            if (avatar != null && avatar.isNotEmpty)
              HmAvatar(url: avatar, size: 110, ring: true)
            else
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: HmColors.surface,
                  border: Border.all(color: HmColors.accent, width: 2),
                ),
                child: const Icon(Icons.person_rounded,
                    size: 56, color: HmColors.accent),
              ),
            if (isOnline)
              Positioned(
                right: 6, bottom: 6,
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: HmColors.success,
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 14),
          Text(fullName.isEmpty ? '—' : fullName,
              textAlign: TextAlign.center,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6, runSpacing: 6,
            children: [
              _MiniBadge(
                icon: isMaster
                    ? Icons.handyman_rounded
                    : Icons.person_rounded,
                label: isMaster
                    ? loc.profile_role_master
                    : loc.profile_role_client,
                color: HmColors.text2,
                bg: HmColors.surface,
                border: HmColors.border2,
              ),
              if (isVerified)
                _MiniBadge(
                  icon: Icons.verified_rounded,
                  label: loc.profile_verified,
                  color: HmColors.success,
                  bg: const Color(0x1F22C55E),
                  border: const Color(0x4D22C55E),
                ),
            ],
          ),
          if (ratingAvg != null && ratingAvg > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: HmColors.accentSoft,
                borderRadius: BorderRadius.circular(HmRadius.pill),
                border: Border.all(color: HmColors.accentBorder),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star_rounded, size: 16, color: HmColors.accent),
                const SizedBox(width: 5),
                Text(ratingAvg.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: HmColors.accent)),
                const SizedBox(width: 6),
                Text('· $ratingCount ${loc.profile_reviews_count}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: HmColors.accent,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.icon, required this.label,
    required this.color, required this.bg, required this.border,
  });
  final IconData icon;
  final String label;
  final Color color;
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
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 1.0)),
      ]),
    );
  }
}

// ===== Stats row =====

class _Stats extends StatelessWidget {
  const _Stats({required this.profile, required this.isMaster});
  final Map<String, dynamic> profile;
  final bool isMaster;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final ratingAvg = double.tryParse(profile['rating_avg']?.toString() ?? '');
    final ratingCount = (profile['rating_count'] as num?)?.toInt() ?? 0;
    final since =
        DateTime.tryParse(profile['created_at']?.toString() ?? '');
    final mp = profile['master_profile'] is Map<String, dynamic>
        ? profile['master_profile'] as Map<String, dynamic>
        : null;
    final ordersCount = (profile['orders_count'] as num?)?.toInt() ??
        (mp?['completed_orders'] as num?)?.toInt() ??
        0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        _StatTile(
          icon: Icons.star_rounded,
          value: (ratingAvg != null && ratingAvg > 0)
              ? ratingAvg.toStringAsFixed(1)
              : '—',
          label: '$ratingCount ${loc.profile_reviews_count}',
          accent: true,
        ),
        const SizedBox(width: 8),
        _StatTile(
          icon: isMaster ? Icons.task_alt_rounded : Icons.shopping_bag_rounded,
          value: '$ordersCount',
          label: loc.profile_orders_completed,
        ),
        const SizedBox(width: 8),
        _StatTile(
          icon: Icons.event_rounded,
          value: since != null ? _shortMonth(since) : '—',
          label: loc.profile_member_since,
        ),
      ]),
    );
  }

  String _shortMonth(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    this.accent = false,
  });
  final IconData icon;
  final String value;
  final String label;
  final bool accent;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        decoration: BoxDecoration(
          color: HmColors.surface,
          borderRadius: BorderRadius.circular(HmRadius.card),
          border: Border.all(
              color: accent ? HmColors.accentBorder : HmColors.border2),
        ),
        child: Column(children: [
          Icon(icon, size: 16,
              color: accent ? HmColors.accent : HmColors.text4),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: accent ? HmColors.accent : HmColors.text,
                  letterSpacing: -0.4)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 10.5,
                  color: HmColors.text5,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ===== Master facts (city / experience / radius) =====

class _MasterFacts extends StatelessWidget {
  const _MasterFacts({required this.mp});
  final Map<String, dynamic> mp;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final city = mp['city']?.toString();
    final district = mp['district']?.toString();
    final exp = (mp['experience_years'] as num?)?.toInt();
    final radius = (mp['work_radius_km'] as num?)?.toInt();

    final items = <Widget>[];
    if (city != null && city.isNotEmpty) {
      items.add(_KV(
          icon: Icons.location_city_rounded,
          k: loc.profile_city,
          v: [city, district]
              .where((x) => x != null && x.isNotEmpty)
              .join(', ')));
    }
    if (exp != null && exp > 0) {
      items.add(_KV(
          icon: Icons.timeline_rounded,
          k: loc.profile_experience,
          v: '$exp ${loc.profile_years_short}'));
    }
    if (radius != null && radius > 0) {
      items.add(_KV(
          icon: Icons.adjust_rounded,
          k: loc.profile_work_radius,
          v: '$radius ${loc.profile_km_short}'));
    }
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: HmColors.surface,
          borderRadius: BorderRadius.circular(HmRadius.cardLarge),
          border: Border.all(color: HmColors.border2),
        ),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: HmColors.border2),
              items[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _KV extends StatelessWidget {
  const _KV({required this.icon, required this.k, required this.v});
  final IconData icon;
  final String k;
  final String v;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(icon, size: 16, color: HmColors.text5),
        const SizedBox(width: 10),
        Expanded(
            child: Text(k,
                style: const TextStyle(fontSize: 13, color: HmColors.text4))),
        Flexible(
          child: Text(v,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: HmColors.text)),
        ),
      ]),
    );
  }
}

// ===== Reviews =====

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: Text(text.toUpperCase(),
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
              color: HmColors.text4)),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.r});
  final Map<String, dynamic> r;
  @override
  Widget build(BuildContext context) {
    final rating = (r['rating'] as num?)?.toInt() ?? 0;
    final text = r['text']?.toString();
    final name = r['reviewer_name']?.toString() ?? '—';
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: HmColors.surface,
          borderRadius: BorderRadius.circular(HmRadius.card),
          border: Border.all(color: HmColors.border2),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: HmColors.accentSoft),
                  alignment: Alignment.center,
                  child: Text(initial,
                      style: const TextStyle(
                          color: HmColors.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(name,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: HmColors.text)),
                ),
                Row(
                    children: List.generate(
                        5,
                        (i) => Icon(
                              i < rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 13,
                              color: i < rating
                                  ? HmColors.accent
                                  : HmColors.text5,
                            ))),
              ]),
              if (text != null && text.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(text,
                    maxLines: 4, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        color: HmColors.text3,
                        height: 1.4)),
              ],
            ]),
      ),
    );
  }
}

class _NoReviewsCard extends StatelessWidget {
  const _NoReviewsCard({required this.isMaster});
  final bool isMaster;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: BoxDecoration(
          color: HmColors.surface,
          borderRadius: BorderRadius.circular(HmRadius.card),
          border: Border.all(color: HmColors.border2),
        ),
        child: Column(children: [
          const Icon(Icons.rate_review_outlined, size: 26, color: HmColors.text5),
          const SizedBox(height: 8),
          Text(loc.profile_no_reviews_yet,
              style: const TextStyle(
                  fontSize: 12.5,
                  color: HmColors.text4,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
