import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';

enum HmTab { home, bookings, announcements, profile }

/// Floating pill-shaped bottom navigation matching `.bottom-nav`. Active item
/// has a soft yellow glow halo (Handyman signature) — implemented via a
/// blurred yellow circle behind the icon.
class HmBottomNav extends StatelessWidget {
  const HmBottomNav({super.key, required this.active, required this.onChanged});

  final HmTab active;
  final ValueChanged<HmTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    final items = <(HmTab, IconData, String)>[
      (HmTab.home,     Icons.home_rounded,                 loc.tab_home),
      (HmTab.bookings, Icons.calendar_today_rounded,       loc.tab_bookings),
      (HmTab.announcements, Icons.campaign_rounded,         loc.tab_announcements),
      (HmTab.profile,  Icons.person_outline_rounded,       loc.tab_profile),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(HmRadius.pill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: HmColors.surface.withOpacity(0.92),
              borderRadius: BorderRadius.circular(HmRadius.pill),
              border: Border.all(color: HmColors.border2),
              boxShadow: HmShadows.navBar,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: items
                  .map((it) => Expanded(
                        child: _NavItem(
                          icon: it.$2,
                          label: it.$3,
                          active: it.$1 == active,
                          onTap: () => onChanged(it.$1),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? HmColors.accent : HmColors.text5;
    return InkWell(
      borderRadius: BorderRadius.circular(HmRadius.pill),
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (active)
              // Soft glow halo behind the icon (matches ::before in CSS)
              Positioned(
                top: 6,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: HmColors.accentGlow,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
