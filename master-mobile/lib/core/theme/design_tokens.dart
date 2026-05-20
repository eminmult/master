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
