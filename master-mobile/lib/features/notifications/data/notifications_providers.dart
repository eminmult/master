import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_mobile/core/auth/auth_controller.dart';
import 'package:master_mobile/features/notifications/data/notifications_repository.dart';

/// FutureProvider for the notifications list. Refreshable via
/// `ref.invalidate(notificationsListProvider)` after marking read or on
/// pull-to-refresh.
final notificationsListProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  return ref.watch(notificationsRepositoryProvider).list();
});

/// Live unread-counter. Polls the backend every 30 s while authenticated;
/// pauses when the auth state is unauthenticated to avoid hammering the
/// `/auth/me` 401 path. Components watch this and re-render when the count
/// changes — the bell uses it to decide whether to shake + paint accent.
final unreadNotificationsCountProvider =
    StreamProvider<int>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth is! AuthAuthenticated) return Stream.value(0);

  final controller = StreamController<int>();
  final repo = ref.watch(notificationsRepositoryProvider);
  Timer? timer;

  Future<void> tick() async {
    try {
      final n = await repo.unreadCount();
      if (!controller.isClosed) controller.add(n);
    } catch (_) {/* swallow — keep last value */}
  }

  // Initial fetch immediately, then every 30 s.
  tick();
  timer = Timer.periodic(const Duration(seconds: 30), (_) => tick());

  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });

  return controller.stream;
});
