import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itez_mobile/core/constants/app_colors.dart';

/// Тёмная Material 3-тема itez.app.
///
/// — Dark-only (как Bolt/Uber): второй theme не нужен.
/// — Фонт: Space Grotesk через google_fonts.
/// — Pill-кнопки (radius 9999), pill-инпуты.
/// — Полупрозрачный AppBar поверх фона с центровкой заголовка.
abstract class AppTheme {
  /// Единственная тема. `ConfigBloc.themeMode` оставлен ради API,
  /// но `darkTheme` совпадает с `theme` — приложение не знает light.
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.accent,
      onPrimary: AppColors.black,
      secondary: AppColors.accent,
      onSecondary: AppColors.black,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.danger,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      dividerColor: AppColors.border,
      splashColor: AppColors.accentSoft,
      highlightColor: AppColors.accentSoft,
    );

    final textTheme = _textTheme();

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: const IconThemeData(color: AppColors.text, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xCC0A0A0A),
        surfaceTintColor: AppColors.transparent,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          fontSize: 18.sp,
          color: AppColors.text,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md.w,
          vertical: 14.h,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.text5),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.text4),
        border: _pillBorder(AppColors.border2),
        enabledBorder: _pillBorder(AppColors.border2),
        focusedBorder: _pillBorder(AppColors.accent, width: 1.5),
        errorBorder: _pillBorder(AppColors.danger),
        focusedErrorBorder: _pillBorder(AppColors.danger, width: 1.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.black,
          disabledBackgroundColor: AppColors.accentDark.withOpacity(0.4),
          disabledForegroundColor: AppColors.text5,
          minimumSize: Size(double.infinity, 54.h),
          shape: const StadiumBorder(),
          elevation: 0,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
            fontSize: 15.sp,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          minimumSize: Size(double.infinity, 54.h),
          shape: const StadiumBorder(),
          side: const BorderSide(color: AppColors.border2),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15.sp,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.black,
          minimumSize: Size(double.infinity, 54.h),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 15.sp,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 14.sp,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface2,
        selectedColor: AppColors.accent,
        secondarySelectedColor: AppColors.accent,
        disabledColor: AppColors.surface3,
        labelStyle: textTheme.labelMedium?.copyWith(color: AppColors.text),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.black,
          fontWeight: FontWeight.w700,
        ),
        side: const BorderSide(color: AppColors.border2),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          side: const BorderSide(color: AppColors.border2),
        ),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.text3),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.banner)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.text),
        shape: const StadiumBorder(),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.black
              : AppColors.text4,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.surface2,
        ),
      ),
    );
  }

  /// `light()` оставлен для совместимости — возвращает ту же dark-тему.
  static ThemeData light() => dark();

  // ───────── helpers ─────────
  static OutlineInputBorder _pillBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        borderSide: BorderSide(color: color, width: width),
      );

  static TextTheme _textTheme() {
    final base = GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme);
    TextStyle s(double size, FontWeight w, {double? ls, double? h, Color? c}) =>
        base.bodyLarge!.copyWith(
          fontSize: size.sp,
          fontWeight: w,
          letterSpacing: ls,
          height: h,
          color: c ?? AppColors.text,
        );

    return base.copyWith(
      displayLarge: s(38, FontWeight.w800, ls: -1.2, h: 1.1),
      displayMedium: s(30, FontWeight.w800, ls: -1.0, h: 1.15),
      displaySmall: s(26, FontWeight.w700, ls: -0.5, h: 1.2),
      headlineLarge: s(22, FontWeight.w700, ls: -0.3, h: 1.25),
      headlineMedium: s(20, FontWeight.w700, ls: -0.2, h: 1.3),
      headlineSmall: s(18, FontWeight.w700, ls: -0.2, h: 1.3),
      titleLarge: s(17, FontWeight.w700, ls: -0.2, h: 1.3),
      titleMedium: s(15, FontWeight.w600, h: 1.4),
      titleSmall: s(13, FontWeight.w600, h: 1.4, c: AppColors.text3),
      bodyLarge: s(15, FontWeight.w500, h: 1.5),
      bodyMedium: s(14, FontWeight.w500, h: 1.55, c: AppColors.text3),
      bodySmall: s(12, FontWeight.w500, h: 1.5, c: AppColors.text4),
      labelLarge: s(15, FontWeight.w800, ls: 0.1),
      labelMedium: s(13, FontWeight.w700, ls: 0.1),
      labelSmall: s(11, FontWeight.w700, ls: 0.2, c: AppColors.text4),
    );
  }
}
