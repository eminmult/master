part of 'config_bloc.dart';

sealed class ConfigEvent {
  const ConfigEvent();
}

class ChangeThemeMode extends ConfigEvent {
  const ChangeThemeMode(this.mode);
  final ThemeMode mode;
}

class ToggleThemeMode extends ConfigEvent {
  const ToggleThemeMode();
}

class ChangeLocale extends ConfigEvent {
  const ChangeLocale(this.locale);
  final Locale locale;
}
