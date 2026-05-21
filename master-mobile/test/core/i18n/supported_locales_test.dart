import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:master_mobile/core/i18n/supported_locales.dart';

void main() {
  group('SupportedLocale', () {
    test('fromCode returns the matching enum or null', () {
      expect(SupportedLocale.fromCode('az'), SupportedLocale.az);
      expect(SupportedLocale.fromCode('en'), SupportedLocale.en);
      expect(SupportedLocale.fromCode('ZZ'), isNull);
      expect(SupportedLocale.fromCode(null), isNull);
    });

    test('allCodes contains every supported language code', () {
      expect(SupportedLocale.allCodes, {'az', 'ru', 'en', 'tr', 'ar'});
    });

    test('supportedLocales mirrors SupportedLocale.values', () {
      expect(SupportedLocale.supportedLocales.length, SupportedLocale.values.length);
      expect(SupportedLocale.supportedLocales, contains(const Locale('az')));
      expect(SupportedLocale.supportedLocales, contains(const Locale('ar')));
    });

    test('Arabic uses RTL direction', () {
      expect(SupportedLocale.ar.direction, TextDirection.rtl);
      expect(SupportedLocale.en.direction, TextDirection.ltr);
    });

    test('English maps to GB flag asset (locale ≠ country)', () {
      expect(SupportedLocale.en.countryFlag, 'gb');
      expect(SupportedLocale.en.flagAsset, 'assets/flags/gb.svg');
    });
  });
}
