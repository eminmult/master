import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_mobile/core/routing/tab_switcher.dart';

/// Tracks the user's tab-switching history so Android back / iOS edge-swipe
/// at a branch root can pop back to the PREVIOUS tab instead of dumping
/// straight to home.
///
/// Why this exists:
///
/// StatefulShellRoute keeps a stack PER branch — but switching tabs doesn't
/// push anywhere, it just swaps the active branch. So `router.canPop()`
/// returns false on a branch root, even if the user got there via a tab
/// switch and conceptually expects to go "back" to the previous tab.
///
/// Mental model match: pressing back should reverse the last navigation
/// action the user took. Tab-switching IS a navigation, so it needs a
/// history that the back-handler can consult.
///
/// Behaviour:
///   - record(home, orders, profile)  → stack = [home, orders]
///   - back from profile               → popped to orders, stack = [home]
///   - back from orders                → popped to home,    stack = []
///   - back from home (empty stack)    → SystemNavigator.pop (exit)
///
/// Re-tapping the same tab (`tab == top`) is treated as a no-op so the
/// history doesn't fill up with duplicates.
class TabHistory {
  final List<AppTab> _stack = [];

  /// True when there's a previous tab to pop back to.
  bool get canPop => _stack.isNotEmpty;

  /// Snapshot for debugging / tests.
  List<AppTab> get stack => List.unmodifiable(_stack);

  /// Record a tab change. `from` is the tab the user was on before the
  /// switch; we push it onto the history so back can return to it.
  void record({required AppTab from, required AppTab to}) {
    if (from == to) return; // no-op tap
    // Avoid runaway growth: if the user oscillates between two tabs, the
    // history shouldn't grow without bound. Cap at 16 entries.
    if (_stack.length >= 16) _stack.removeAt(0);
    _stack.add(from);
  }

  /// Pop the last entry and return it. Caller is responsible for actually
  /// switching to it.
  AppTab? pop() => _stack.isEmpty ? null : _stack.removeLast();

  /// Wipe the history (e.g. on logout).
  void clear() => _stack.clear();
}

final tabHistoryProvider = Provider<TabHistory>((ref) => TabHistory());
