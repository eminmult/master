import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_mobile/core/i18n/locales_repository.dart';
import 'package:master_mobile/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth for the active app locale.
///
/// Behaviour mirrors the website:
///   1. saved choice (SharedPreferences key `i18n_lang`, same as the site cookie)
///   2. else default to `az` — system/browser locale is intentionally ignored.
///
/// On login the controller pulls `user.locale` from the server to make the
/// language follow the account across devices. On every user-initiated change
/// we PATCH `/me/locale` so the next session anywhere starts in the same
/// language.
class LocaleController extends StateNotifier<Locale> {
  LocaleController(this._ref) : super(_default) {
    _loadSaved();
  }

  final Ref _ref;

  static const _kKey = 'i18n_lang';
  static const _default = Locale('az');
  static const supported = <Locale>[
    Locale('az'),
    Locale('ru'),
    Locale('en'),
    Locale('tr'),
    Locale('ar'),
  ];
  static const _supportedCodes = {'az', 'ru', 'en', 'tr', 'ar'};

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kKey);
      if (saved != null && _supportedCodes.contains(saved)) {
        state = Locale(saved);
      }
    } catch (_) {/* fail-open: keep default `az` locale */}
  }

  /// Apply locale received from the server (after login or /auth/me).
  /// Skips persisting back to the server — that would echo the same value.
  Future<void> applyServerLocale(String? code) async {
    if (code == null || !_supportedCodes.contains(code)) return;
    if (state.languageCode == code) return;
    state = Locale(code);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kKey, code);
    } catch (_) {/* in-memory state is enough */}
  }

  /// User-initiated change. Persists locally, then mirrors to the server
  /// when an authenticated session exists. Server failure is non-fatal —
  /// next start will still pick up the local choice.
  Future<void> setLocale(Locale locale) async {
    if (!_supportedCodes.contains(locale.languageCode)) return;
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kKey, locale.languageCode);
    } catch (_) {/* state still updated in memory */}

    // Best-effort server sync — keep the language consistent across clients.
    try {
      await _ref.read(localesRepositoryProvider).updateMyLocale(locale.languageCode);
    } catch (_) {/* unauthenticated or offline — ignore */}
  }
}

final localeControllerProvider =
    StateNotifierProvider<LocaleController, Locale>((ref) => LocaleController(ref));

/// Concise getter for localized strings: `context.l10n.auth_login_title`.
extension L10nExt on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
