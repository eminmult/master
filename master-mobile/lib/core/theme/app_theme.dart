import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:master_mobile/core/theme/design_tokens.dart';

/// Handyman design — dark by default. Light mode follows Material defaults so
/// system pickers / map controls don't look broken if user forces light, but
/// the app is designed-for-dark.
class AppTheme {
  AppTheme._();

  /// Use iOS-style page transitions on every platform so users get the
  /// edge-swipe-back gesture (drag from the left edge to pop) on Android too.
  /// CupertinoPageTransitionsBuilder is the only Material builder that ships
  /// with the back-swipe gesture detector wired in.
  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
    },
  );

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final txt = GoogleFonts.spaceGroteskTextTheme(base.textTheme).apply(
      bodyColor: HmColors.text,
      displayColor: HmColors.text,
    );

    return base.copyWith(
      scaffoldBackgroundColor: HmColors.bg,
      canvasColor: HmColors.bg,
      cardColor: HmColors.surface,
      dividerColor: HmColors.border2,
      colorScheme: const ColorScheme.dark(
        primary: HmColors.accent,
        onPrimary: Colors.black,
        secondary: HmColors.accent,
        surface: HmColors.surface,
        onSurface: HmColors.text,
        error: HmColors.danger,
      ),
      pageTransitionsTheme: _pageTransitions,
      textTheme: txt,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xCC0A0A0A),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: txt.titleMedium?.copyWith(
          fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: HmColors.accent,
          foregroundColor: Colors.black,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: txt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HmColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        hintStyle: const TextStyle(color: HmColors.text5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HmRadius.pill),
          borderSide: const BorderSide(color: HmColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HmRadius.pill),
          borderSide: const BorderSide(color: HmColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HmRadius.pill),
          borderSide: const BorderSide(color: HmColors.accentBorder, width: 1.5),
        ),
      ),
    );
  }

  /// Light variant — minimal; we follow Handyman's dark-first design and only
  /// expose this so MaterialApp.themeMode = system doesn't crash.
  static ThemeData light() {
    return ThemeData.light(useMaterial3: true).copyWith(
      textTheme: GoogleFonts.spaceGroteskTextTheme(),
      pageTransitionsTheme: _pageTransitions,
    );
  }
}
