import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_mobile/features/master/data/masters_repository.dart';
import 'package:master_mobile/features/orders/data/models/public_order.dart';
import 'package:master_mobile/features/orders/data/orders_repository.dart';

/// Top masters for the home carousel. Capped at 10 — the list endpoint orders
/// by rating server-side.
final homeRecommendedMastersProvider =
    FutureProvider.autoDispose<List<MasterListItem>>((ref) async {
  final repo = ref.watch(mastersRepositoryProvider);
  final res = await repo.list();
  return res.items.take(10).toList();
});

/// Latest open announcements (public order feed) for the home carousel —
/// "see all" leads to /announcements which shows the full paginated list.
final homeAnnouncementsProvider =
    FutureProvider.autoDispose<List<PublicOrderItem>>((ref) async {
  final res = await ref.watch(ordersRepositoryProvider).publicFeed();
  return res.items.take(10).toList();
});
