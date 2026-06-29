import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itez_mobile/app/config_model.dart';
import 'package:itez_mobile/core/services/local_storage.dart';

part 'config_event.dart';
part 'config_state.dart';

class ConfigBloc extends Bloc<ConfigEvent, ConfigState> {
  ConfigBloc(ConfigModel initial) : super(ConfigState(initial)) {
    on<ChangeThemeMode>(_changeThemeMode);
    on<ToggleThemeMode>(_toggleThemeMode);
    on<ChangeLocale>(_changeLocale);
  }

  Future<void> _changeThemeMode(
    ChangeThemeMode event,
    Emitter<ConfigState> emit,
  ) async {
    if (state.configModel.themeMode == event.mode) return;
    final model = state.configModel.copyWith(themeMode: event.mode);
    unawaited(LocalStorage.setThemeMode(event.mode));
    emit(ConfigState(model));
  }

  Future<void> _toggleThemeMode(
    ToggleThemeMode event,
    Emitter<ConfigState> emit,
  ) async {
    final next = state.configModel.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    final model = state.configModel.copyWith(themeMode: next);
    unawaited(LocalStorage.setThemeMode(next));
    emit(ConfigState(model));
  }

  Future<void> _changeLocale(
    ChangeLocale event,
    Emitter<ConfigState> emit,
  ) async {
    if (state.configModel.locale == event.locale) return;
    final model = state.configModel.copyWith(locale: event.locale);
    unawaited(LocalStorage.setLocale(event.locale.languageCode));
    emit(ConfigState(model));
  }
}
