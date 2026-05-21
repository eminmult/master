import 'package:flutter/material.dart';

/// Third-party brand colours. These intentionally live OUTSIDE the
/// `HmColors` design system — they belong to other companies, not us, and
/// they shouldn't move when we tweak our own palette.
///
/// Use only on UI that explicitly identifies the third-party (e.g., a
/// "Open in Google Maps" button, a "VISA" card-type chip). Anywhere else
/// the regular HmColors / HmSem tokens apply.
class BrandColors {
  BrandColors._();

  // Navigation apps — tinted backgrounds + brand-correct icon fills used
  // in the "open route" sheet on the order detail page.
  static const googleMapsBg = Color(0xFFE8F5E9);
  static const googleMapsFg = Color(0xFF1A73E8);

  static const yandexMapsBg = Color(0xFFFFF3E0);
  static const yandexMapsFg = Color(0xFFFC3F1D);

  static const wazeBg = Color(0xFFE0F7FA);
  static const wazeFg = Color(0xFF33CCFF);

  // Card networks — shown on the saved payment-methods list.
  static const visaBlue = Color(0xFF1A1F71);
  static const visaYellow = Color(0xFFFFD200);
  static const mastercardRed = Color(0xFFEB001B);
  static const amexBlue = Color(0xFF2E77BB);
}
