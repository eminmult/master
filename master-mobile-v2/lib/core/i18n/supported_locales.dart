import 'package:flutter/widgets.dart';

/// Single source of truth для языков, которые поддерживает приложение.
/// Используется в:
///  - MaterialApp.supportedLocales
///  - language picker bottom-sheet
///  - ApiClient Accept-Language
///  - Hard-fallback в LocalStorage.getLocale
///
/// Точный порт `supported_locales.dart` из master-mobile.
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

  final String code;
  final String name;
  final String countryFlag;
  final TextDirection direction;

  Locale get locale => Locale(code);

  static const SupportedLocale fallback = SupportedLocale.az;

  static SupportedLocale? fromCode(String? code) {
    if (code == null) return null;
    for (final l in SupportedLocale.values) {
      if (l.code == code) return l;
    }
    return null;
  }

  static final Set<String> allCodes = {
    for (final l in SupportedLocale.values) l.code,
  };

  static final List<Locale> supportedLocales = [
    for (final l in SupportedLocale.values) l.locale,
  ];
}
