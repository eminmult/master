import 'package:flutter/widgets.dart';

/// Single source of truth for the locales the app supports.
///
/// Anywhere that needs to know "what languages exist" — the language
/// picker, MaterialApp.supportedLocales, the API client's
/// Accept-Language interceptor, the hreflang generator on the web side —
/// reads from here. Adding a sixth language is now a one-line change
/// instead of a treasure hunt across half a dozen files.
enum SupportedLocale {
  az(code: 'az', name: 'Azərbaycan', countryFlag: 'az', direction: TextDirection.ltr),
  ru(code: 'ru', name: 'Русский',   countryFlag: 'ru', direction: TextDirection.ltr),
  en(code: 'en', name: 'English',   countryFlag: 'gb', direction: TextDirection.ltr),
  tr(code: 'tr', name: 'Türkçe',    countryFlag: 'tr', direction: TextDirection.ltr),
  ar(code: 'ar', name: 'العربية',   countryFlag: 'sa', direction: TextDirection.rtl);

  const SupportedLocale({
    required this.code,
    required this.name,
    required this.countryFlag,
    required this.direction,
  });

  /// ISO 639-1 code (matches Laravel's `Accept-Language` + flutter
  /// `Locale.languageCode`).
  final String code;

  /// Human-readable name in its own language (rendered in the picker UI).
  final String name;

  /// ISO 3166-1 alpha-2 country code used as the asset slug for the flag
  /// SVG. Note that locale ≠ country — "en" maps to "gb" (UK flag),
  /// "ar" maps to "sa" (Saudi). Adjust per market.
  final String countryFlag;

  /// Layout direction — controls Flutter's Directionality widget.
  final TextDirection direction;

  /// Build a Flutter `Locale` value from the enum.
  Locale get locale => Locale(code);

  /// Path to the flag asset bundled in `assets/flags/`.
  String get flagAsset => 'assets/flags/$countryFlag.svg';

  /// Locale used when nothing else is known yet (matches Laravel default).
  static const SupportedLocale fallback = SupportedLocale.az;

  /// Lookup by ISO code. Returns null for unknown codes.
  static SupportedLocale? fromCode(String? code) {
    if (code == null) return null;
    for (final l in SupportedLocale.values) {
      if (l.code == code) return l;
    }
    return null;
  }

  /// All ISO codes as a Set for fast `contains` checks.
  static final Set<String> allCodes = {for (final l in SupportedLocale.values) l.code};

  /// Flutter `Locale` list for `MaterialApp.supportedLocales`.
  static final List<Locale> supportedLocales = [
    for (final l in SupportedLocale.values) l.locale,
  ];
}
