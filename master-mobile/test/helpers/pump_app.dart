import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:master_mobile/core/i18n/supported_locales.dart';
import 'package:master_mobile/core/theme/app_theme.dart';
import 'package:master_mobile/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:master_mobile/features/addresses/data/active_address_controller.dart';

/// Boots a minimum MaterialApp wrapper for widget tests so callers don't
/// need to copy-paste localisation delegates, theme setup and a hydrated
/// SharedPreferences override in every file.
///
/// Usage:
///   await pumpApp(tester, child: const MyWidget(), overrides: [
///     mastersRepositoryProvider.overrideWithValue(MockRepo()),
///   ]);
Future<void> pumpApp(
  WidgetTester tester, {
  required Widget child,
  List<Override> overrides = const [],
  Locale locale = const Locale('en'),
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        ...overrides,
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        locale: locale,
        supportedLocales: SupportedLocale.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
