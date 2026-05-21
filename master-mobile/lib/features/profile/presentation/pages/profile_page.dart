import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/auth/auth_controller.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/features/addresses/data/addresses_repository.dart';
import 'package:master_mobile/features/master/data/masters_repository.dart';
import 'package:master_mobile/features/auth/data/models/user.dart';
import 'package:master_mobile/features/user_profile/data/user_profile_repository.dart';
import 'package:master_mobile/features/wallet/data/wallet_repository.dart';
import 'package:master_mobile/shared/widgets/hm_avatar.dart';
import 'package:master_mobile/shared/widgets/hm_icon_button.dart';

/// Self-profile dashboard. Builds a single page that serves both roles —
/// for masters it surfaces public-profile signal (rating, completed orders,
/// categories, recent reviews) and the subscription gate; for clients it
/// surfaces order count and saved addresses. Heavier data is fetched via
/// `/users/{me}/profile` so that the locally-cached `User` object is never
/// the bottleneck.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});
  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _pushOn = true;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final auth = ref.watch(authStateProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    if (user == null) {
      return const Scaffold(backgroundColor: HmColors.bg2, body: SizedBox.shrink());
    }
    final isMaster = user.isMaster;
    final asyncProfile = ref.watch(userProfileProvider(user.id));

    return Scaffold(
      backgroundColor: HmColors.bg2,
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              color: HmColors.accent,
              backgroundColor: HmColors.surface,
              onRefresh: () async {
                ref.invalidate(userProfileProvider(user.id));
                ref.invalidate(addressesListProvider);
                await ref.read(authStateProvider.notifier).refreshUser();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 110),
                children: [
                  _Header(loc: loc),
                  _Hero(user: user, profile: asyncProfile.valueOrNull),
                  const SizedBox(height: 8),
                  _StatsRow(
                    user: user,
                    profile: asyncProfile.valueOrNull,
                  ),
                  const SizedBox(height: 18),
                  if (isMaster) ...[
                    const _WalletBalanceCard(),
                    _SubscriptionCard(user: user),
                    if (asyncProfile.valueOrNull != null)
                      _MasterPublicCard(profile: asyncProfile.value!, user: user),
                    _CategoriesSection(profile: asyncProfile.valueOrNull),
                    _AboutSection(profile: asyncProfile.valueOrNull),
                    _RecentReviewsSection(profile: asyncProfile.valueOrNull),
                  ] else ...[
                    _AddressesSection(),
                  ],
                  _Section(title: loc.profile_section_account, children: [
                    _PrefRow(
                      icon: Icons.calendar_today_rounded,
                      label: loc.my_orders_title,
                      onTap: () => context.go('/orders'),
                    ),
                    if (!isMaster)
                      _PrefRow(
                        icon: Icons.location_on_rounded,
                        label: loc.profile_my_addresses,
                        onTap: () => context.push('/addresses/new'),
                      ),
                    _PrefRow(
                      icon: Icons.credit_card_rounded,
                      label: loc.profile_payment_methods,
                      onTap: () => context.push('/payment-methods'),
                    ),
                    if (user.role == 'master')
                      _PrefRow(
                        icon: Icons.account_balance_wallet_rounded,
                        label: loc.wallet_title,
                        onTap: () => context.push('/wallet'),
                      ),
                  ]),
                  _Section(title: loc.profile_section_preferences, children: [
                    _PrefRow(
                      icon: Icons.notifications_rounded,
                      label: loc.profile_push_notifications,
                      trailing: _Switch(
                          value: _pushOn,
                          onChanged: (v) => setState(() => _pushOn = v)),
                    ),
                  ]),
                  _LogoutButton(loc: loc, onTap: () =>
                      ref.read(authStateProvider.notifier).logout()),
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Center(
                      child: Text(loc.profile_copyright,
                          style: const TextStyle(
                              fontSize: 10,
                              color: Color(0x33FFFFFF),
                              letterSpacing: 1)),
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
}

// ===== Header =====

class _Header extends StatelessWidget {
  const _Header({required this.loc});
  final dynamic loc;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Row(children: [
        const SizedBox(width: 32),
        Expanded(
          child: Center(
            child: Text(loc.profile_title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4)),
          ),
        ),
        HmIconButton(
            icon: Icons.settings_rounded, accent: true, small: true,
            onPressed: () => context.push('/settings')),
      ]),
    );
  }
}

// ===== Hero (avatar + name + role + verified badges + edit) =====

class _Hero extends StatelessWidget {
  const _Hero({required this.user, this.profile});
  final User user;
  final Map<String, dynamic>? profile;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final isMaster = user.isMaster;
    final premium = isMaster && user.canOperate;
    final mp = profile?['master_profile'] as Map<String, dynamic>?;
    final isOnline = mp?['is_online'] == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
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
            if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
              HmAvatar(url: user.avatarUrl, size: 110, ring: true)
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
            if (isMaster && isOnline)
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
            Positioned(
              right: -2, top: -2,
              child: Material(
                color: HmColors.accent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => context.push('/profile/edit'),
                  child: const SizedBox(
                    width: 32, height: 32,
                    child: Icon(Icons.edit_rounded, size: 14, color: Colors.black),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Text(user.fullName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6, runSpacing: 6,
            children: [
              _RoleBadge(isMaster: isMaster),
              if (premium)
                _MiniBadge(
                  icon: Icons.workspace_premium_rounded,
                  label: loc.profile_premium_member,
                  color: HmColors.accent,
                  bg: HmColors.accentSoft,
                  border: HmColors.accentBorder,
                ),
              if (user.isVerified || (mp != null && mp['is_verified'] == true))
                _MiniBadge(
                  icon: Icons.verified_rounded,
                  label: loc.profile_verified,
                  color: HmColors.success,
                  bg: const Color(0x1F22C55E),
                  border: const Color(0x4D22C55E),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _ContactRow(user: user),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 44,
            child: FilledButton.icon(
              onPressed: () => context.push('/profile/edit'),
              icon: const Icon(Icons.edit_rounded, size: 14, color: Colors.black),
              label: Text(loc.profile_edit_btn,
                  style: const TextStyle(color: Colors.black)),
              style: FilledButton.styleFrom(
                backgroundColor: HmColors.accent,
                foregroundColor: Colors.black,
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity, height: 40,
            child: OutlinedButton.icon(
              onPressed: () => context.push(
                  isMaster ? '/master/${user.id}' : '/user/${user.id}'),
              icon: const Icon(Icons.open_in_new_rounded,
                  size: 13, color: HmColors.accent),
              label: Text(loc.profile_view_public,
                  style: const TextStyle(color: HmColors.accent)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: HmColors.accentBorder),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.isMaster});
  final bool isMaster;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return _MiniBadge(
      icon: isMaster ? Icons.handyman_rounded : Icons.person_rounded,
      label: isMaster ? loc.profile_role_master : loc.profile_role_client,
      color: HmColors.text2,
      bg: HmColors.surface,
      border: HmColors.border2,
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

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.user});
  final User user;
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _ContactLine(
        icon: Icons.phone_rounded,
        text: user.phone,
        verified: user.phoneVerified,
      ),
      if (user.email != null && user.email!.isNotEmpty) ...[
        const SizedBox(height: 6),
        _ContactLine(
          icon: Icons.alternate_email_rounded,
          text: user.email!,
          verified: user.emailVerified,
        ),
      ],
    ]);
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.text, required this.verified});
  final IconData icon;
  final String text;
  final bool verified;
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 13, color: HmColors.text4),
      const SizedBox(width: 6),
      Flexible(
        child: Text(text,
            style: const TextStyle(fontSize: 13, color: HmColors.text3)),
      ),
      if (verified) ...[
        const SizedBox(width: 4),
        const Icon(Icons.check_circle_rounded, size: 13, color: HmColors.success),
      ],
    ]);
  }
}

// ===== Stats row =====

class _StatsRow extends ConsumerWidget {
  const _StatsRow({required this.user, this.profile});
  final User user;
  final Map<String, dynamic>? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.l10n;
    final isMaster = user.isMaster;
    final mp = profile?['master_profile'] as Map<String, dynamic>?;

    final since = profile?['created_at'] != null
        ? _shortMonth(DateTime.tryParse(profile!['created_at'].toString()), loc)
        : (user.createdAt != null ? _shortMonth(user.createdAt, loc) : '—');

    if (isMaster) {
      final ratingAvg = double.tryParse(
              profile?['rating_avg']?.toString() ?? user.ratingAvg ?? '') ??
          0.0;
      final ratingCount = (profile?['rating_count'] as num?)?.toInt() ??
          user.ratingCount;
      final completed =
          (mp?['completed_orders'] as num?)?.toInt() ?? 0;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          _StatTile(
            icon: Icons.star_rounded,
            value: ratingAvg > 0 ? ratingAvg.toStringAsFixed(1) : '—',
            label: '$ratingCount ${loc.profile_reviews_count}',
            accent: true,
          ),
          const SizedBox(width: 8),
          _StatTile(
            icon: Icons.task_alt_rounded,
            value: '$completed',
            label: loc.profile_orders_completed,
          ),
          const SizedBox(width: 8),
          _StatTile(
            icon: Icons.event_rounded,
            value: since,
            label: loc.profile_member_since,
          ),
        ]),
      );
    }

    final ordersCount = (profile?['orders_count'] as num?)?.toInt() ?? 0;
    final addressesAsync = ref.watch(addressesListProvider);
    final addrCount = addressesAsync.valueOrNull?.length ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        _StatTile(
          icon: Icons.shopping_bag_rounded,
          value: '$ordersCount',
          label: loc.profile_orders_completed,
          accent: true,
        ),
        const SizedBox(width: 8),
        _StatTile(
          icon: Icons.location_on_rounded,
          value: '$addrCount',
          label: loc.profile_my_addresses,
        ),
        const SizedBox(width: 8),
        _StatTile(
          icon: Icons.event_rounded,
          value: since,
          label: loc.profile_member_since,
        ),
      ]),
    );
  }

  String _shortMonth(DateTime? d, dynamic loc) {
    if (d == null) return '—';
    return '${d.month.toString().padLeft(2, '0')}.${d.year}';
  }
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
          Icon(icon, size: 16, color: accent ? HmColors.accent : HmColors.text4),
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
              style: const TextStyle(fontSize: 10.5, color: HmColors.text5,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ===== Wallet balance card (master-only) =====

final _balanceProvider = FutureProvider.autoDispose<WalletBalance>((ref) =>
    ref.watch(walletRepositoryProvider).balance());

class _WalletBalanceCard extends ConsumerWidget {
  const _WalletBalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.l10n;
    final async = ref.watch(_balanceProvider);
    final amountCents = async.valueOrNull?.cents ?? 0;
    final currency = async.valueOrNull?.currency ?? 'AZN';
    final amount = (amountCents / 100).toStringAsFixed(2);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [HmColors.accent.withOpacity(0.14), HmColors.accent.withOpacity(0.04)],
        ),
        borderRadius: BorderRadius.circular(HmRadius.cardLarge),
        border: Border.all(color: HmColors.accentBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.account_balance_wallet_rounded,
              size: 18, color: HmColors.accent),
          const SizedBox(width: 8),
          Text(loc.wallet_balance,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  letterSpacing: 0.8, color: HmColors.text4)),
        ]),
        const SizedBox(height: 10),
        async.when(
          loading: () => const _BalanceSkeleton(),
          error: (_, __) => Text('— $currency',
              style: const TextStyle(
                  fontSize: 30, fontWeight: FontWeight.w800,
                  letterSpacing: -1, color: HmColors.text4)),
          data: (_) => Text('$amount $currency',
              style: const TextStyle(
                  fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1)),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.push('/wallet'),
              icon: const Icon(Icons.list_alt_rounded, size: 14, color: HmColors.accent),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(loc.wallet_transactions,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: HmColors.accent, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: HmColors.accentBorder),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                minimumSize: const Size(0, 38),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              onPressed: amountCents <= 0 ? null : () => context.push('/wallet'),
              icon: const Icon(Icons.north_east_rounded, size: 14, color: Colors.black),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(loc.wallet_withdraw_cta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: HmColors.accent,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                minimumSize: const Size(0, 38),
                disabledBackgroundColor: HmColors.surface2,
                disabledForegroundColor: HmColors.text5,
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _BalanceSkeleton extends StatelessWidget {
  const _BalanceSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140, height: 28,
      decoration: BoxDecoration(
        color: HmColors.surface2,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

// ===== Subscription card =====

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.user});
  final User user;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final sub = user.subscription;
    final active = user.canOperate;
    final until = sub?.expiresAt;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: active
                    ? const [Color(0x14FFFF00), Color(0x0AFFFF00)]
                    : const [Color(0x14EF4444), Color(0x05EF4444)],
              ),
              borderRadius: BorderRadius.circular(HmRadius.cardLarge),
              border: Border.all(
                  color: active ? HmColors.accentBorder : const Color(0x4DEF4444)),
            ),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? HmColors.accentSoft : const Color(0x1FEF4444),
                ),
                child: Icon(
                    active
                        ? Icons.workspace_premium_rounded
                        : Icons.lock_outline_rounded,
                    size: 22,
                    color: active ? HmColors.accent : HmColors.danger),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        active
                            ? loc.profile_subscription_active
                            : loc.profile_subscription_inactive,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: active ? HmColors.accent : HmColors.danger)),
                    const SizedBox(height: 2),
                    Text(
                        until != null
                            ? '${loc.profile_subscription_until} ${_dateLabel(until)}'
                            : loc.profile_subscription_inactive_sub,
                        style: const TextStyle(
                            fontSize: 12, color: HmColors.text4)),
                  ])),
            ]),
      ),
    );
  }

  String _dateLabel(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

// ===== Master public card (city, exp, work-radius) =====

class _MasterPublicCard extends StatelessWidget {
  const _MasterPublicCard({required this.profile, required this.user});
  final Map<String, dynamic> profile;
  final User user;
  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final mp = profile['master_profile'] as Map<String, dynamic>?;
    if (mp == null) return const SizedBox.shrink();
    final city = mp['city']?.toString();
    final district = mp['district']?.toString();
    final exp = (mp['experience_years'] as num?)?.toInt();
    final radius = (mp['work_radius_km'] as num?)?.toInt();
    final accepting = mp['is_accepting'] == true;

    final items = <Widget>[];
    if (city != null && city.isNotEmpty) {
      items.add(_KV(
          icon: Icons.location_city_rounded,
          k: loc.profile_city,
          v: [city, district].where((x) => x != null && x.isNotEmpty).join(', ')));
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
    // Active toggle — the website's header had this; mobile only showed
    // a static "Yes/No" cell. Wired to PUT /master/status (online|offline).
    items.add(_AcceptingToggleRow(initial: accepting));

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
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
              if (i > 0)
                const Divider(height: 1, color: HmColors.border2),
              items[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Interactive online/offline toggle for masters. Mirrors the website
/// header switch — PUT /master/status with online|offline. Optimistic UI:
/// flip immediately, snap back on API failure.
class _AcceptingToggleRow extends ConsumerStatefulWidget {
  const _AcceptingToggleRow({required this.initial});
  final bool initial;
  @override
  ConsumerState<_AcceptingToggleRow> createState() => _AcceptingToggleRowState();
}

class _AcceptingToggleRowState extends ConsumerState<_AcceptingToggleRow> {
  late bool _on = widget.initial;
  bool _busy = false;

  Future<void> _toggle(bool next) async {
    if (_busy) return;
    setState(() { _on = next; _busy = true; });
    try {
      await ref.read(mastersRepositoryProvider).setStatus(next ? 'online' : 'offline');
      // Refresh the cached user so other surfaces (header chip, online dot)
      // see the new state without waiting for the next /auth/me poll.
      await ref.read(authStateProvider.notifier).refreshUser();
    } catch (_) {
      if (mounted) setState(() => _on = !next); // snap back on failure
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(_on ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
            size: 16, color: _on ? HmColors.success : HmColors.text5),
        const SizedBox(width: 10),
        Expanded(
          child: Text(loc.profile_accepting_orders,
              style: const TextStyle(fontSize: 13, color: HmColors.text4)),
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: HmColors.accent),
            ),
          ),
        Switch.adaptive(
          value: _on,
          onChanged: _busy ? null : _toggle,
          activeColor: HmColors.success,
        ),
      ]),
    );
  }
}

class _KV extends StatelessWidget {
  const _KV({required this.icon, required this.k, required this.v, this.valueColor});
  final IconData icon;
  final String k;
  final String v;
  final Color? valueColor;
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
        Text(v,
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: valueColor ?? HmColors.text)),
      ]),
    );
  }
}

// ===== Categories =====

class _CategoriesSection extends StatelessWidget {
  const _CategoriesSection({this.profile});
  final Map<String, dynamic>? profile;
  @override
  Widget build(BuildContext context) {
    final mp = profile?['master_profile'] as Map<String, dynamic>?;
    final cats = (mp?['categories'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    if (cats.isEmpty) return const SizedBox.shrink();
    final loc = context.l10n;
    return _Section(
      title: loc.profile_categories_label,
      children: [
        Wrap(
          spacing: 8, runSpacing: 8,
          children: cats.map((c) {
            final name = c['name']?.toString() ?? '';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: HmColors.accentSoft,
                borderRadius: BorderRadius.circular(HmRadius.pill),
                border: Border.all(color: HmColors.accentBorder),
              ),
              child: Text(name,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: HmColors.accent)),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ===== About =====

class _AboutSection extends StatelessWidget {
  const _AboutSection({this.profile});
  final Map<String, dynamic>? profile;
  @override
  Widget build(BuildContext context) {
    final mp = profile?['master_profile'] as Map<String, dynamic>?;
    final desc = mp?['description']?.toString();
    if (desc == null || desc.trim().isEmpty) return const SizedBox.shrink();
    final loc = context.l10n;
    return _Section(title: loc.profile_about, children: [
      Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: HmColors.surface,
          borderRadius: BorderRadius.circular(HmRadius.card),
          border: Border.all(color: HmColors.border2),
        ),
        child: Text(desc,
            style: const TextStyle(
                fontSize: 13.5, color: HmColors.text2, height: 1.45)),
      ),
    ]);
  }
}

// ===== Recent reviews (last 3) =====

class _RecentReviewsSection extends StatelessWidget {
  const _RecentReviewsSection({this.profile});
  final Map<String, dynamic>? profile;
  @override
  Widget build(BuildContext context) {
    final reviews = (profile?['reviews'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    if (reviews.isEmpty) return const SizedBox.shrink();
    final loc = context.l10n;
    final shown = reviews.take(3).toList();
    return _Section(
      title: loc.profile_recent_reviews,
      trailing: reviews.length > 3
          ? Builder(builder: (ctx) {
              final selfId = (profile!['id'] as num).toInt();
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => ctx.push('/master/$selfId'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(loc.profile_view_full,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: HmColors.accent)),
                ),
              );
            })
          : null,
      children: shown.map((r) => _ReviewItem(r: r)).toList(),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  const _ReviewItem({required this.r});
  final Map<String, dynamic> r;
  @override
  Widget build(BuildContext context) {
    final rating = (r['rating'] as num?)?.toInt() ?? 0;
    final text = r['text']?.toString();
    final name = r['reviewer_name']
            ?.toString() ??
        (r['reviewer'] is Map<String, dynamic>
            ? (r['reviewer']['first_name']?.toString() ?? '—')
            : '—');
    // Backend returns either `[{thumb, medium, large}, ...]` (UserProfile API)
    // or `[{url}, ...]` (older shape). Normalise to a list of preview/full pairs.
    final rawPhotos = (r['photos'] as List?) ?? const [];
    final photos = rawPhotos.whereType<Map>().map((p) {
      final pp = Map<String, dynamic>.from(p);
      final thumb = (pp['thumb'] ?? pp['thumb_url'] ?? pp['medium'] ?? pp['url'])?.toString();
      final full = (pp['large'] ?? pp['large_url'] ?? pp['url'] ?? pp['medium'] ?? thumb)?.toString();
      return (thumb: thumb, full: full);
    }).where((p) => p.thumb != null).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: HmColors.surface,
        borderRadius: BorderRadius.circular(HmRadius.card),
        border: Border.all(color: HmColors.border2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(name,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: HmColors.text)),
          ),
          Row(children: List.generate(5, (i) => Icon(
            i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 13,
            color: i < rating ? HmColors.accent : HmColors.text5,
          ))),
        ]),
        if (text != null && text.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(text,
              maxLines: 4, overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, color: HmColors.text3, height: 1.4)),
        ],
        if (photos.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) => InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  final urls = photos.map((p) => p.full ?? p.thumb!).whereType<String>().toList();
                  Navigator.of(context).push(PageRouteBuilder(
                    opaque: false,
                    barrierColor: Colors.black,
                    pageBuilder: (_, __, ___) => _ReviewLightbox(urls: urls, initialIndex: i),
                    transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                  ));
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(photos[i].thumb!,
                      width: 72, height: 72, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                            width: 72, height: 72,
                            color: HmColors.surface2,
                            child: const Icon(Icons.broken_image_outlined,
                                size: 16, color: HmColors.text5),
                          )),
                ),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

class _ReviewLightbox extends StatefulWidget {
  const _ReviewLightbox({required this.urls, required this.initialIndex});
  final List<String> urls;
  final int initialIndex;
  @override
  State<_ReviewLightbox> createState() => _ReviewLightboxState();
}

class _ReviewLightboxState extends State<_ReviewLightbox> {
  late final PageController _ctrl = PageController(initialPage: widget.initialIndex);
  late int _i = widget.initialIndex;
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Stack(children: [
          GestureDetector(
            onVerticalDragEnd: (d) {
              if ((d.primaryVelocity ?? 0).abs() > 600) Navigator.of(context).pop();
            },
            child: PageView.builder(
              controller: _ctrl,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _i = i),
              itemBuilder: (_, i) => InteractiveViewer(
                minScale: 1.0, maxScale: 4.0,
                child: Center(
                  child: Image.network(widget.urls[i],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image_outlined, size: 64, color: Colors.white54),
                      loadingBuilder: (_, c, p) => p == null
                          ? c
                          : const Center(child: CircularProgressIndicator(color: Colors.white))),
                ),
              ),
            ),
          ),
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
                  Text('${_i + 1} / ${widget.urls.length}',
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

// ===== Addresses (client) =====

class _AddressesSection extends ConsumerWidget {
  const _AddressesSection();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.l10n;
    final asyncList = ref.watch(addressesListProvider);
    final list = asyncList.valueOrNull ?? const [];

    return _Section(
      title: loc.profile_my_addresses,
      trailing: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/addresses/new'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            const Icon(Icons.add_rounded, size: 14, color: HmColors.accent),
            const SizedBox(width: 2),
            Text(loc.profile_add_address,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800,
                    color: HmColors.accent)),
          ]),
        ),
      ),
      children: [
        if (asyncList.isLoading && list.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
                child: CircularProgressIndicator(
                    color: HmColors.accent, strokeWidth: 2.4)),
          )
        else if (list.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            decoration: BoxDecoration(
              color: HmColors.surface,
              borderRadius: BorderRadius.circular(HmRadius.card),
              border: Border.all(color: HmColors.border2),
            ),
            child: Column(children: [
              const Icon(Icons.location_off_rounded,
                  size: 24, color: HmColors.text5),
              const SizedBox(height: 6),
              Text(loc.profile_no_addresses,
                  style: const TextStyle(
                      fontSize: 12.5, color: HmColors.text4)),
            ]),
          )
        else
          for (final a in list.take(3))
            _AddressTile(a: a),
      ],
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({required this.a});
  final Address a;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: HmColors.surface,
        borderRadius: BorderRadius.circular(HmRadius.card),
        border: Border.all(
            color: a.isDefault ? HmColors.accentBorder : HmColors.border2),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: a.isDefault ? HmColors.accentSoft : HmColors.bg2),
          child: Icon(
              a.isDefault
                  ? Icons.home_rounded
                  : Icons.location_on_rounded,
              size: 18,
              color: a.isDefault ? HmColors.accent : HmColors.text4),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (a.label != null && a.label!.isNotEmpty)
                Text(a.label!,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: HmColors.text)),
              const SizedBox(height: 2),
              Text(a.fullAddress,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: HmColors.text4, height: 1.35)),
            ],
          ),
        ),
        if (a.isDefault)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: HmColors.accentSoft,
              borderRadius: BorderRadius.circular(HmRadius.pill),
              border: Border.all(color: HmColors.accentBorder),
            ),
            child: Text(context.l10n.profile_default,
                style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: HmColors.accent,
                    letterSpacing: 0.8)),
          ),
      ]),
    );
  }
}

// ===== Section / PrefRow / Switch =====

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.trailing});
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(children: [
              Expanded(
                child: Text(title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                      color: HmColors.text4,
                    )),
              ),
              if (trailing != null) trailing!,
            ]),
          ),
          ...children.map((c) =>
              Padding(padding: const EdgeInsets.only(bottom: 10), child: c)),
        ],
      ),
    );
  }
}

class _PrefRow extends StatelessWidget {
  const _PrefRow({required this.icon, required this.label, this.sub, this.trailing, this.onTap});

  final IconData icon;
  final String label;
  final String? sub;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HmColors.surface,
        borderRadius: BorderRadius.circular(HmRadius.pill),
        border: Border.all(color: HmColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: HmColors.accentSoft),
            child: Icon(icon, size: 18, color: HmColors.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(sub!,
                      style: const TextStyle(
                          fontSize: 12, color: HmColors.text5)),
                ],
              ],
            ),
          ),
          trailing ??
              const Icon(Icons.chevron_right_rounded,
                  color: HmColors.accent, size: 18),
        ],
      ),
    );
    if (onTap == null) return body;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HmRadius.pill),
      child: body,
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46, height: 24,
        decoration: BoxDecoration(
          color: value ? HmColors.accent : Colors.white24,
          borderRadius: BorderRadius.circular(HmRadius.pill),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                color: value ? Colors.black : Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.loc, required this.onTap});
  final dynamic loc;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
      child: SizedBox(
        height: 50,
        child: FilledButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.logout_rounded, size: 16, color: HmColors.danger),
          label: Text(loc.profile_sign_out),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0x1AEF4444),
            foregroundColor: HmColors.danger,
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HmRadius.pill),
              side: const BorderSide(color: Color(0x4DEF4444)),
            ),
          ),
        ),
      ),
    );
  }
}
