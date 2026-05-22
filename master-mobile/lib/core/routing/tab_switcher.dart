import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:master_mobile/core/routing/tab_history.dart';

/// Bottom-nav tab identifier. The integer indexes MUST line up with the
/// branch order declared in `router.dart`'s StatefulShellRoute. If you
/// reorder the branches there, reorder this enum to match.
enum AppTab {
  home(0),
  announcements(1),
  orders(2),
  profile(3);

  const AppTab(this.branchIndex);
  final int branchIndex;

  static AppTab fromIndex(int i) => switch (i) {
        0 => AppTab.home,
        1 => AppTab.announcements,
        2 => AppTab.orders,
        3 => AppTab.profile,
        _ => AppTab.home,
      };
}

extension TabSwitch on WidgetRef {
  /// Switch to a named bottom-nav tab from a Riverpod-aware context. Like
  /// `context.switchTab`, but also records the move in [TabHistory] so the
  /// global back handler can return to the previous tab on Android back /
  /// edge-swipe at branch root.
  ///
  /// Prefer this overload from ConsumerWidget / ConsumerStatefulWidget; use
  /// the BuildContext overload as a fallback when you don't have a
  /// WidgetRef (e.g. in StatelessWidget callbacks).
  void switchTab(BuildContext context, AppTab target) {
    final shell = context.findAncestorWidgetOfExactType<StatefulNavigationShell>();
    if (shell == null) {
      _fallbackGo(context, target);
      return;
    }
    final current = AppTab.fromIndex(shell.currentIndex);
    if (current != target) {
      read(tabHistoryProvider).record(from: current, to: target);
    }
    shell.goBranch(target.branchIndex, initialLocation: true);
  }
}

extension TabSwitchContext on BuildContext {
  /// BuildContext-only fallback when no WidgetRef is available. Doesn't
  /// record tab history (we have no ref to the provider), so prefer the
  /// WidgetRef overload above.
  void switchTab(AppTab target) {
    final shell = findAncestorWidgetOfExactType<StatefulNavigationShell>();
    if (shell == null) {
      _fallbackGo(this, target);
      return;
    }
    shell.goBranch(target.branchIndex, initialLocation: true);
  }
}

void _fallbackGo(BuildContext context, AppTab target) {
  // Caller is outside the shell — likely an auth flow or splash. Fall back
  // to URL-based navigation; go-router will route into the shell and pick
  // the correct branch on mount.
  const pathByTab = ['/home', '/announcements', '/orders', '/profile'];
  context.go(pathByTab[target.branchIndex]);
}
