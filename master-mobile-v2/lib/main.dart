import 'dart:async';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:itez_mobile/app/app.dart';
import 'package:itez_mobile/app/config_model.dart';
import 'package:itez_mobile/app/di_container.dart';
import 'package:itez_mobile/core/api_client/api_client.dart';
import 'package:itez_mobile/core/push/push_service.dart';
import 'package:itez_mobile/core/realtime/realtime_service.dart';
import 'package:itez_mobile/core/services/local_storage.dart';

/// Deep-link URL, сохранённый ДО первого build'a — позже Uri.base.fragment
/// может быть очищен по мере того как Flutter web обрабатывает URL.
/// Читается из SplashPage._resolveNext, чтобы понять, нужно ли redirect'ить
/// на конкретный экран (а не на дефолтный MainRoute).
String? initialDeepLink;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Снимаем snapshot deep-link ДО setUrlStrategy — после переключения
  // стратегии Flutter может перепарсить URL и обнулить fragment.
  final fragment = Uri.base.fragment;
  final path = Uri.base.path;
  if (fragment.isNotEmpty && fragment != '/') {
    initialDeepLink = fragment;
  } else if (path.isNotEmpty && path != '/' && path != '/master-mobile-v2/') {
    final stripped = path.replaceFirst('/master-mobile-v2', '');
    if (stripped.isNotEmpty && stripped != '/') initialDeepLink = stripped;
  }
  // Hash routing: deep-link URL вида /master-mobile-v2/#/main/orders/164 .
  setUrlStrategy(const HashUrlStrategy());

  setupLocator();
  await LocalStorage.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final locale = await LocalStorage.getLocale();
  final themeMode = await LocalStorage.getThemeMode();

  locator<ApiClient>().setLocale(locale.languageCode);

  // Firebase + Push. Toleнce: если конфига Firebase нет (web/dev), просто
  // продолжаем без push — не валим запуск.
  try {
    await Firebase.initializeApp();
    await locator<PushService>().bootstrap();
  } catch (e) {
    log('Firebase/push init failed (продолжаем без push): $e');
  }

  // Realtime подключаем сразу, токен берёт из LocalStorage по запросу.
  unawaited(locator<RealtimeService>().start());

  runApp(App(configModel: ConfigModel(themeMode: themeMode, locale: locale)));
}
