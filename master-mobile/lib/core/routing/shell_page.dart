import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/shared/widgets/hm_bottom_nav.dart';

/// Persistent shell hosting four parallel navigator stacks (one per bottom-
/// nav tab). The visible child is whichever branch is currently selected;
/// inactive branches stay alive in memory so their state (scroll position,
/// open forms, half-typed messages) survives a tab switch.
///
/// Tab taps drive `navigationShell.goBranch(i)`. Deep-link/push handlers
/// can call it with `initialLocation: true` to jump the selected branch
/// back to its root.
class HmShellPage extends StatelessWidget {
  const HmShellPage({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  /// Map the navigation-shell branch index to the bottom-nav enum and back.
  /// The order MUST match the StatefulShellRoute branches in router.dart.
  static HmTab _tabForIndex(int i) => switch (i) {
        0 => HmTab.home,
        1 => HmTab.announcements,
        2 => HmTab.bookings,
        3 => HmTab.profile,
        _ => HmTab.home,
      };
  static int _indexForTab(HmTab t) => switch (t) {
        HmTab.home => 0,
        HmTab.announcements => 1,
        HmTab.bookings => 2,
        HmTab.profile => 3,
      };

  void _onTap(HmTab tab) {
    final i = _indexForTab(tab);
    // Re-tapping the currently active tab pops its branch back to its root
    // (standard native iOS/Android behaviour for tab bars). Switching to a
    // different branch never resets — that's the whole point of having a
    // stateful shell.
    navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HmColors.bg,
      extendBody: true, // shell paints under the floating bottom-nav pill
      body: navigationShell,
      bottomNavigationBar: HmBottomNav(
        active: _tabForIndex(navigationShell.currentIndex),
        onChanged: _onTap,
      ),
    );
  }
}
