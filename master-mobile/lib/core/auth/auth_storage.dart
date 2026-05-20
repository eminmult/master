import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the bearer token + refresh metadata.
///
/// Primary backend is OS keychain via flutter_secure_storage. On some Xiaomi /
/// Qualcomm devices the hardware keystore returns `-22` (TEE init failure)
/// for every keypair generation, breaking secure storage entirely. We catch
/// that and fall back to plain SharedPreferences so the user can still log
/// in — token then lives inside the app's sandbox (which is already isolated
/// from other apps by Android), at the lower bar that a rooted user with
/// filesystem access could extract it.
class AuthStorage {
  AuthStorage(this._storage, this._prefs);
  final FlutterSecureStorage _storage;
  final SharedPreferences _prefs;

  static const _kToken = 'auth.token';
  static const _kIssuedAt = 'auth.issued_at';

  Future<String?> readToken() async {
    try {
      final v = await _storage.read(key: _kToken);
      if (v != null) return v;
    } catch (_) {/* fall through to prefs */}
    return _prefs.getString(_kToken);
  }

  Future<DateTime?> readIssuedAt() async {
    String? raw;
    try {
      raw = await _storage.read(key: _kIssuedAt);
    } catch (_) {/* fall through */}
    raw ??= _prefs.getString(_kIssuedAt);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> writeToken(String token) async {
    final issued = DateTime.now().toIso8601String();
    try {
      await _storage.write(key: _kToken, value: token);
      await _storage.write(key: _kIssuedAt, value: issued);
      await _prefs.remove(_kToken);
      await _prefs.remove(_kIssuedAt);
    } catch (_) {
      await _prefs.setString(_kToken, token);
      await _prefs.setString(_kIssuedAt, issued);
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _kToken);
      await _storage.delete(key: _kIssuedAt);
    } catch (_) {/* ignore */}
    await _prefs.remove(_kToken);
    await _prefs.remove(_kIssuedAt);
  }
}
