import 'package:flutter/material.dart';

/// Глобальный конфиг приложения: тема и локаль.
/// Хранится в [LocalStorage], читается на старте в [main],
/// меняется через [ConfigBloc].
class ConfigModel {
  const ConfigModel({
    required this.themeMode,
    required this.locale,
  });

  final ThemeMode themeMode;
  final Locale locale;

  ConfigModel copyWith({ThemeMode? themeMode, Locale? locale}) => ConfigModel(
        themeMode: themeMode ?? this.themeMode,
        locale: locale ?? this.locale,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfigModel &&
          themeMode == other.themeMode &&
          locale == other.locale;

  @override
  int get hashCode => Object.hash(themeMode, locale);
}
