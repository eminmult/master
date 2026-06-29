import 'package:flutter/material.dart';

/// Палитра itez.app — dark-only по дизайну оригинального master-mobile.
/// Светлая тема не используется (приложение всегда тёмное, как Bolt/Uber).
abstract class AppColors {
  // ───────── Surfaces ─────────
  /// Главный фон.
  static const bg = Color(0xFF0A0A0A);

  /// Альтернативный, более тёмный фон (модалки, дальние слои).
  static const bg2 = Color(0xFF000000);

  /// Базовая поверхность карточек.
  static const surface = Color(0xFF1A1A1A);

  /// Полупрозрачная поверхность поверх bg (chips, nav-bar overlay).
  /// Цвет = white @ 5%.
  static const surface2 = Color(0x0DFFFFFF);

  /// Ещё прозрачнее — для границ внутри surface2-блоков.
  /// white @ 3%.
  static const surface3 = Color(0x08FFFFFF);

  // ───────── Brand accent ─────────
  /// Брендовый жёлтый — единственный акцент во всём UI.
  static const accent = Color(0xFFFFFF00);

  /// Hover/pressed состояние.
  static const accentDark = Color(0xFFCA8A04);

  /// Полупрозрачный жёлтый для soft-фонов (chips, highlights).
  /// accent @ 10%.
  static const accentSoft = Color(0x1AFFFF00);

  /// Жёлтый @ 30% — glow-тень.
  static const accentGlow = Color(0x4DFFFF00);

  // ───────── Text ─────────
  /// Главный белый.
  static const text = Color(0xFFFFFFFF);

  /// Чуть менее белый (заголовки секций).
  static const text2 = Color(0xFFF1F5F9);

  /// Серо-белый (подзаголовки).
  static const text3 = Color(0xFFCBDBEF);

  /// Серый (вторичный текст).
  static const text4 = Color(0xFF94A3B8);

  /// Глубокий серый (плейсхолдеры).
  static const text5 = Color(0xFF6B7280);

  /// Тёмно-серый (disabled).
  static const text6 = Color(0xFF64748B);

  // ───────── Status ─────────
  static const success = Color(0xFF22C55E);
  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);

  // ───────── Borders / dividers ─────────
  /// Тонкий бордер (white @ 5%).
  static const border = Color(0x0DFFFFFF);

  /// Чуть более заметный бордер (white @ 10%).
  static const border2 = Color(0x1AFFFFFF);

  // ───────── Common ─────────
  static const transparent = Colors.transparent;
  static const black = Colors.black;
  static const white = Colors.white;

  // ───────── Legacy aliases (для кода, ещё не переехавшего на новый набор) ─
  static const brandPrimary = accent;
  static const brandPrimaryDark = accentDark;
  static const brandSecondary = bg2;
  static const surfaceLight = surface;
  static const surfaceDark = surface;
  static const scaffoldLight = bg;
  static const scaffoldDark = bg;
  static const textLight = text;
  static const textDark = text;
  static const textMutedLight = text4;
  static const textMutedDark = text4;
  static const borderLight = border2;
  static const borderDark = border2;
  static const dividerLight = border;
  static const dividerDark = border;
}

/// Радиусы скруглений — фиксированный набор для консистентности.
abstract class AppRadius {
  /// Pill / stadium — для кнопок, полей, чипов.
  static const pill = 9999.0;

  /// Карточки списков, тайлов.
  static const card = 16.0;

  /// Большие карточки (recommended grid, баннеры).
  static const cardLarge = 22.0;

  /// Огромные баннеры hero.
  static const banner = 32.0;

  /// Маленькие inline-элементы (badges, mini-tags).
  static const sm = 8.0;
}

/// Шкала отступов — 4-пиксельная сетка.
abstract class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
}

/// Тени.
abstract class AppShadows {
  /// Жёлтый glow вокруг акцентных кнопок (FAB, primary).
  static const accentGlow = <BoxShadow>[
    BoxShadow(
      color: AppColors.accentGlow,
      blurRadius: 15,
      offset: Offset(0, 4),
    ),
  ];

  /// Сильный glow для FAB-подобных элементов.
  static const fabAccent = <BoxShadow>[
    BoxShadow(
      color: Color(0x66FFFF00),
      blurRadius: 50,
    ),
  ];

  /// Тень навигационной панели (затемнение под floating pill).
  static const navBar = <BoxShadow>[
    BoxShadow(
      color: Color(0x80000000),
      blurRadius: 50,
      offset: Offset(0, -10),
    ),
  ];
}
