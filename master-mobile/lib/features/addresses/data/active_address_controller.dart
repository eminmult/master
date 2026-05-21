import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_mobile/features/addresses/data/addresses_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Synchronous access to SharedPreferences. The instance is awaited in
/// `main()` and injected via a `ProviderScope` override, so anything
/// downstream can `ref.read(sharedPrefsProvider)` without async juggling.
final sharedPrefsProvider = Provider<SharedPreferences>((_) {
  throw UnimplementedError(
    'sharedPrefsProvider must be overridden in main.dart with a hydrated SharedPreferences instance.',
  );
});

/// Tracks which of the user's saved addresses is the "active" one — the
/// one shown in the home header and used as the default for new orders.
/// Persisted to SharedPreferences so the choice survives across sessions.
///
/// Migrated to Riverpod 2.5+ Notifier from StateNotifier (deprecated path).
class ActiveAddressNotifier extends Notifier<int?> {
  static const _key = 'active_address_id';

  late final SharedPreferences _prefs;

  @override
  int? build() {
    _prefs = ref.watch(sharedPrefsProvider);
    return _prefs.getInt(_key);
  }

  Future<void> setActive(int id) async {
    state = id;
    await _prefs.setInt(_key, id);
  }

  Future<void> clear() async {
    state = null;
    await _prefs.remove(_key);
  }
}

final activeAddressIdProvider =
    NotifierProvider<ActiveAddressNotifier, int?>(ActiveAddressNotifier.new);

/// Resolved active Address: respects the user's explicit choice, falls
/// back to `is_default` from the server-side list, then to the first
/// address. Null when the user has zero saved addresses.
final activeAddressProvider = Provider<Address?>((ref) {
  final list = ref.watch(addressesListProvider).valueOrNull ?? const <Address>[];
  if (list.isEmpty) return null;

  final selectedId = ref.watch(activeAddressIdProvider);
  if (selectedId != null) {
    final match = list.where((a) => a.id == selectedId).toList();
    if (match.isNotEmpty) return match.first;
  }

  final defaults = list.where((a) => a.isDefault).toList();
  if (defaults.isNotEmpty) return defaults.first;
  return list.first;
});
