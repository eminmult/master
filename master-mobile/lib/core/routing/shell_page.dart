import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/routing/tab_history.dart';
import 'package:master_mobile/core/routing/tab_switcher.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';
import 'package:master_mobile/shared/widgets/hm_bottom_nav.dart';

/// Persistent shell hosting four parallel navigator stacks (one per bottom-
/// nav tab). The visible child is whichever branch is currently selected;
/// inactive branches stay alive in memory so their state (scroll position,
/// open forms, half-typed messages) survives a tab switch.
///
/// Tab taps drive `navigationShell.goBranch(i)` AND record the previous tab
/// in [TabHistory] so the global back handler can return to where the user
/// came from instead of dumping straight to home.
class HmShellPage extends ConsumerWidget {
  const HmShellPage({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  /// Map a shell branch index to the bottom-nav enum and back. Order MUST
  /// match the StatefulShellRoute.branches list in router.dart.
  static HmTab _navItem(int i) => switch (i) {
        0 => HmTab.home,
        1 => HmTab.announcements,
        2 => HmTab.bookings,
        3 => HmTab.profile,
        _ => HmTab.home,
      };
  static int _indexForNavItem(HmTab t) => switch (t) {
        HmTab.home => 0,
        HmTab.announcements => 1,
        HmTab.bookings => 2,
        HmTab.profile => 3,
      };

  static AppTab _appTabFor(int branchIndex) => switch (branchIndex) {
        0 => AppTab.home,
        1 => AppTab.announcements,
        2 => AppTab.orders,
        3 => AppTab.profile,
        _ => AppTab.home,
      };

  void _onTap(WidgetRef ref, HmTab tab) {
    final targetIndex = _indexForNavItem(tab);
    final currentIndex = navigationShell.currentIndex;
    if (targetIndex != currentIndex) {
      // Record the OLD tab so back can pop us back to it.
      ref.read(tabHistoryProvider).record(
            from: _appTabFor(currentIndex),
            to: _appTabFor(targetIndex),
          );
    }
    // Re-tapping the active tab pops its branch back to its root (standard
    // native tab-bar behaviour). Switching to a different branch never
    // resets — that's the point of having a stateful shell.
    navigationShell.goBranch(
      targetIndex,
      initialLocation: targetIndex == currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: HmColors.bg,
      extendBody: true, // shell paints under the floating bottom-nav pill
      // Wrap the navigator in an EdgeSwipeBack detector. When the active
      // branch is at root (CupertinoPageRoute's built-in gesture is
      // disabled because canPop=false), we still want the left-edge swipe
      // to "go back" — by popping the tab history. The detector observes
      // pointer events without consuming them, so CupertinoPage's gesture
      // continues to win on deeper routes.
      body: _EdgeSwipeBack(
        onTabPop: () {
          // From any non-home tab root, swipe-back goes to Home — the
          // app's "root of roots". This is what users actually expect
          // ("back = take me to the start"), rather than a strict tab
          // history pop which can land them on whichever tab they
          // happened to visit last. From Home itself the gesture is a
          // no-op (nothing to pop into).
          if (navigationShell.currentIndex == AppTab.home.branchIndex) return;
          ref.read(tabHistoryProvider).clear(); // history no longer relevant
          navigationShell.goBranch(
            AppTab.home.branchIndex,
            initialLocation: true,
          );
        },
        // When canPop is true within the branch, CupertinoPage handles the
        // swipe natively — our handler must stand down to avoid double-pop.
        // Cheap check: at a TAB ROOT path the branch has nothing to pop;
        // at any other URL there's a pushed page on top.
        canBranchPop: () {
          final path = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
          const tabRoots = {'/home', '/announcements', '/orders', '/profile'};
          return !tabRoots.contains(path);
        },
        child: navigationShell,
      ),
      bottomNavigationBar: HmBottomNav(
        active: _navItem(navigationShell.currentIndex),
        onChanged: (tab) => _onTap(ref, tab),
      ),
    );
  }
}

/// Left-edge swipe detector that fires only when the active branch has
/// nothing to pop AND there's at least one tab in [TabHistory]. Uses a
/// Listener (not GestureDetector) so it OBSERVES pointer events without
/// claiming them — CupertinoPageRoute's built-in gesture continues to win
/// on routes where canPop is true.
class _EdgeSwipeBack extends StatefulWidget {
  const _EdgeSwipeBack({
    required this.child,
    required this.onTabPop,
    required this.canBranchPop,
  });
  final Widget child;
  final VoidCallback onTabPop;
  final bool Function() canBranchPop;

  @override
  State<_EdgeSwipeBack> createState() => _EdgeSwipeBackState();
}

class _EdgeSwipeBackState extends State<_EdgeSwipeBack> {
  // Width of the screen-left "hot zone" — must start inside this strip for
  // the gesture to count. Matches CupertinoPageRoute's edge threshold.
  static const double _edgeWidth = 24;

  // Horizontal distance required before we consider it a deliberate swipe.
  static const double _minDistance = 80;

  // Vertical tolerance — if the user moves vertically more than this we
  // treat it as a scroll, not a back gesture.
  static const double _verticalSlop = 32;

  Offset? _startPos;
  bool _claimed = false; // set when we've decided this is a back gesture

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        if (e.position.dx <= _edgeWidth && !widget.canBranchPop()) {
          _startPos = e.position;
          _claimed = false;
        }
      },
      onPointerMove: (e) {
        final start = _startPos;
        if (start == null) return;
        final dx = e.position.dx - start.dx;
        final dy = (e.position.dy - start.dy).abs();
        if (dy > _verticalSlop) {
          // Vertical scroll — cancel.
          _startPos = null;
        } else if (dx > _minDistance && !_claimed) {
          _claimed = true; // arm the fire-on-release
        }
      },
      onPointerUp: (_) {
        if (_claimed) widget.onTabPop();
        _startPos = null;
        _claimed = false;
      },
      onPointerCancel: (_) {
        _startPos = null;
        _claimed = false;
      },
      child: widget.child,
    );
  }
}
