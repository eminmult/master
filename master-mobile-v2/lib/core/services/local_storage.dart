import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Тонкий wrapper над OS keychain с fallback на SharedPreferences.
/// Причина fallback: некоторые Xiaomi / Qualcomm устройства возвращают -22
/// на инициализации TEE keystore — `secure_storage` падает, авторизация ломается.
/// В таком случае мы храним данные в sandbox приложения (изоляция уровня Android).
class LocalStorage {
  LocalStorage._();

  static const _secure = FlutterSecureStorage();
  static SharedPreferences? _prefs;

  static const _kLocale = 'app.locale';
  static const _kTheme = 'app.theme';
  static const _kOnboardingDone = 'app.onboarding_done';
  static const _kAuthToken = 'auth.token';
  static const _kAuthIssuedAt = 'auth.issued_at';
  static const _kAuthExpiresAt = 'auth.expires_at';
  static const _kActiveAddressId = 'address.active_id';

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ───────── locale ─────────
  static Future<Locale> getLocale() async {
    final raw = await _safeRead(_kLocale);
    // Дефолт `az` совпадает с SupportedLocale.fallback и Laravel default.
    if (raw == null || raw.isEmpty) return const Locale('az');
    return Locale(raw);
  }

  static Future<void> setLocale(String code) => _safeWrite(_kLocale, code);

  // ───────── theme ─────────
  static Future<ThemeMode> getThemeMode() async {
    final raw = await _safeRead(_kTheme);
    return switch (raw) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
  }

  static Future<void> setThemeMode(ThemeMode mode) =>
      _safeWrite(_kTheme, mode.name);

  // ───────── onboarding ─────────
  static Future<bool> getOnboardingDone() async {
    final raw = await _safeRead(_kOnboardingDone);
    return raw == 'true';
  }

  static Future<void> setOnboardingDone() =>
      _safeWrite(_kOnboardingDone, 'true');

  // ───────── auth (Sanctum: один Bearer-токен с rotation) ─────────
  static Future<String?> getAuthToken() => _safeRead(_kAuthToken);

  static Future<DateTime?> getAuthIssuedAt() async {
    final raw = await _safeRead(_kAuthIssuedAt);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  static Future<DateTime?> getAuthExpiresAt() async {
    final raw = await _safeRead(_kAuthExpiresAt);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  static Future<void> setAuthToken({
    required String token,
    DateTime? expiresAt,
  }) async {
    await _safeWrite(_kAuthToken, token);
    await _safeWrite(_kAuthIssuedAt, DateTime.now().toIso8601String());
    if (expiresAt != null) {
      await _safeWrite(_kAuthExpiresAt, expiresAt.toIso8601String());
    } else {
      await _safeDelete(_kAuthExpiresAt);
    }
  }

  static Future<void> clearAuth() async {
    await _safeDelete(_kAuthToken);
    await _safeDelete(_kAuthIssuedAt);
    await _safeDelete(_kAuthExpiresAt);
  }

  // ───────── active address ─────────
  static Future<int?> getActiveAddressId() async {
    final raw = await _safeRead(_kActiveAddressId);
    return raw == null ? null : int.tryParse(raw);
  }

  static Future<void> setActiveAddressId(int? id) async {
    if (id == null) {
      await _safeDelete(_kActiveAddressId);
    } else {
      await _safeWrite(_kActiveAddressId, id.toString());
    }
  }

  // ───────── primitives ─────────
  static Future<String?> _safeRead(String key) async {
    try {
      final v = await _secure.read(key: key);
      if (v != null) return v;
    } catch (_) {/* fall through */}
    return _prefs?.getString(key);
  }

  static Future<void> _safeWrite(String key, String value) async {
    try {
      await _secure.write(key: key, value: value);
      await _prefs?.remove(key);
      return;
    } catch (_) {
      await _prefs?.setString(key, value);
    }
  }

  static Future<void> _safeDelete(String key) async {
    try {
      await _secure.delete(key: key);
    } catch (_) {/* ignore */}
    await _prefs?.remove(key);
  }
}
