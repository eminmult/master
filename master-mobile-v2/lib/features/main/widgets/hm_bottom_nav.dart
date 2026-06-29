import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';

/// Floating pill bottom-navigation — точный порт из master-mobile.
///
/// Padding `(24, 0, 24, 12)`, высота капсулы 64, фон `surface @ 0.92`,
/// внутри Row с `horizontal: 8` padding. Каждый item — SizedBox 48 высоты,
/// в центре Column(icon 22 + text 10sp/w700/ls 0.4), за активной иконкой
/// soft-yellow halo-круг 22×22 (accentGlow), смещение top: 6.
class HmBottomNav extends StatelessWidget {
  const HmBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<HmNavItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.92),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.border2),
              boxShadow: AppShadows.navBar,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                for (int i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavItem(
                      item: items[i],
                      active: i == currentIndex,
                      onTap: () => onTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HmNavItem {
  const HmNavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final HmNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.text5;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (active)
              // Soft halo за иконкой — не halo вокруг (как у меня было),
              // а круг точно за глифом.
              Positioned(
                top: 6,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.accentGlow,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: 22, color: color),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: color,
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
