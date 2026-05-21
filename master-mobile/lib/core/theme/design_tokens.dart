import 'package:flutter/material.dart';

/// Design tokens lifted 1:1 from the Handyman App design system
/// (`Handyman App.html` + `styles.css`). Use these everywhere — never
/// hard-code hex codes in feature code.
class HmColors {
  HmColors._();

  // Surfaces
  static const bg = Color(0xFF0A0A0A);
  static const bg2 = Color(0xFF000000);
  static const surface = Color(0xFF1A1A1A);
  static const surface2 = Color(0x0DFFFFFF); // rgba(255,255,255,0.05)
  static const surface3 = Color(0x08FFFFFF); // rgba(255,255,255,0.03)

  // Borders
  static const border = Color(0x0DFFFFFF); // rgba(255,255,255,0.05)
  static const border2 = Color(0x1AFFFFFF); // rgba(255,255,255,0.1)

  // Accent (yellow)
  static const accent = Color(0xFFFFFF00);
  static const accentDark = Color(0xFFCA8A04); // gradient stop / hover state
  static const accentSoft = Color(0x1AFFFF00); // rgba(255,255,0,0.1)
  static const accentBorder = Color(0x33FFFF00); // rgba(255,255,0,0.2)
  static const accentGlow = Color(0x66FFFF00); // rgba(255,255,0,0.4)

  // Text scale
  static const text = Color(0xFFFFFFFF);
  static const text2 = Color(0xFFF1F5F9);
  static const text3 = Color(0xFFCBD5E1);
  static const text4 = Color(0xFF94A3B8);
  static const text5 = Color(0xFF6B7280);
  static const text6 = Color(0xFF64748B);

  // Status
  static const success = Color(0xFF22C55E);
  static const danger = Color(0xFFEF4444);
}

/// Radius tokens — pills are 9999, used everywhere.
class HmRadius {
  HmRadius._();
  static const pill = 9999.0;
  static const card = 16.0;
  static const cardLarge = 22.0;
  static const banner = 32.0;
  static const bubbleMine = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(20),
  );
  static const bubbleTheirs = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomRight: Radius.circular(20),
  );
}

class HmSpacing {
  HmSpacing._();
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// Semantic colour layer — feature code should consume these names rather
/// than the brand-specific HmColors aliases below. A future re-skin only
/// needs to change the mapping in HmSem, leaving 80 feature files untouched.
///
/// Why both layers exist:
///   * `HmColors` is the design-system primitive: 'accent' is yellow, full
///     stop. The number of tokens stays low and rarely changes.
///   * `HmSem` is the semantic role: 'primary' is whatever colour means
///     "main action" today. Rebrand changes the role mapping; the role
///     names in widgets keep working.
class HmSem {
  HmSem._();

  // Surfaces
  static const Color surface = HmColors.bg;
  static const Color surfaceContainer = HmColors.surface;
  static const Color surfaceVariant = HmColors.surface2;
  static const Color outline = HmColors.border2;

  // Primary brand action
  static const Color primary = HmColors.accent;
  static const Color onPrimary = Color(0xFF0A0A0A);
  static const Color primaryContainer = HmColors.accentSoft;

  // Text scale (by emphasis, not by hex)
  static const Color onSurface = HmColors.text;
  static const Color onSurfaceMuted = HmColors.text3;
  static const Color onSurfaceFaint = HmColors.text4;
  static const Color onSurfaceDisabled = HmColors.text5;

  // Status (semantic, NOT brand)
  static const Color success = HmColors.success;
  static const Color error = HmColors.danger;
  static const Color warning = Color(0xFFEAB308);
  static const Color info = Color(0xFF3B82F6);
}

/// Typography scale — feature code uses these names, never raw TextStyle().
/// Roles match Material 3 type roles so we slot into MaterialApp themeData
/// without contortions if/when we adopt Material You theming.
class HmTextStyles {
  HmTextStyles._();

  static const TextStyle displayHero = TextStyle(
      fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1.2, height: 1.1);
  static const TextStyle display = TextStyle(
      fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1.0, height: 1.15);
  static const TextStyle headline = TextStyle(
      fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.25);
  static const TextStyle title = TextStyle(
      fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.2, height: 1.3);
  static const TextStyle body = TextStyle(
      fontSize: 14, fontWeight: FontWeight.w500, height: 1.55);
  static const TextStyle bodyMuted = TextStyle(
      fontSize: 14, fontWeight: FontWeight.w500, color: HmColors.text4, height: 1.55);
  static const TextStyle caption = TextStyle(
      fontSize: 12, fontWeight: FontWeight.w600, color: HmColors.text4, letterSpacing: 0.2);
  static const TextStyle button = TextStyle(
      fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.1);
}

/// Drop shadows reused across components.
class HmShadows {
  HmShadows._();

  static const accentGlow = [
    BoxShadow(color: Color(0x4DFFFF00), blurRadius: 15, offset: Offset(0, 4)),
  ];

  static const fabAccent = [
    BoxShadow(color: Color(0x66FFFF00), blurRadius: 50, spreadRadius: -12, offset: Offset(0, 25)),
  ];

  static const navBar = [
    BoxShadow(color: Color(0x80000000), blurRadius: 50, spreadRadius: -12, offset: Offset(0, 25)),
  ];

  static const accentDanger = [
    BoxShadow(color: Color(0x33EF4444), blurRadius: 15, offset: Offset(0, 4)),
  ];
}
