import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_mobile/core/i18n/locales_repository.dart';
import 'package:master_mobile/core/i18n/supported_locales.dart';
import 'package:master_mobile/core/onboarding/onboarding_state.dart';
import 'package:master_mobile/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth for the active app locale.
///
/// Behaviour mirrors the website:
///   1. saved choice (SharedPreferences key `i18n_lang`, same as the site cookie)
///   2. else default to `az` — system/browser locale is intentionally ignored.
///
/// On login the controller pulls `user.locale` from the server to make the
/// language follow the account across devices. On every user-initiated
/// change we PATCH `/me/locale` so the next session on a different device
/// starts in the same language.
class LocaleController extends Notifier<Locale> {
  static const _kKey = 'i18n_lang';
  // Defer to SupportedLocale.fallback so adding/removing locales is one edit.
  static final Locale _default = SupportedLocale.fallback.locale;

  /// Re-exported so MaterialApp.supportedLocales has somewhere to read.
  static final List<Locale> supported = SupportedLocale.supportedLocales;

  @override
  Locale build() {
    // Kick off the SharedPreferences load asynchronously — initial state
    // is the fallback, which gets replaced once the saved value lands.
    Future.microtask(_loadSaved);
    return _default;
  }

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kKey);
      if (saved != null && SupportedLocale.allCodes.contains(saved)) {
        state = Locale(saved);
      }
    } catch (_) {/* fail-open: keep fallback locale */}
  }

  /// Apply locale received from the server (after login or /auth/me).
  /// Skips persisting back to the server — that would echo the same value.
  Future<void> applyServerLocale(String? code) async {
    if (code == null || !SupportedLocale.allCodes.contains(code)) return;
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
    if (!SupportedLocale.allCodes.contains(locale.languageCode)) return;
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kKey, locale.languageCode);
      // OnboardingGuard reads onboardingFlagsProvider, which caches the
      // SharedPreferences snapshot. Invalidate so the next router redirect
      // (immediately after the picker pops) sees localePicked=true.
      ref.invalidate(onboardingFlagsProvider);
    } catch (_) {/* state still updated in memory */}

    // Best-effort server sync — keep the language consistent across clients.
    try {
      await ref.read(localesRepositoryProvider).updateMyLocale(locale.languageCode);
    } catch (_) {/* unauthenticated or offline — ignore */}
  }
}

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);

/// Concise getter for localized strings: `context.l10n.auth_login_title`.
extension L10nExt on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
