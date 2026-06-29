import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:itez_mobile/core/api_client/api_client.dart';
import 'package:itez_mobile/core/api_client/urls.dart';

/// FCM подписка + регистрация устройства на бэке.
/// Зовётся один раз из [AuthBloc] после успешной авторизации, и при logout
/// — `unregister(token)` чтобы старый юзер не получал уведомления.
///
/// Класс намеренно не хранит state: токен у FCM глобально один, мы его
/// читаем по запросу.
class PushService {
  PushService(this._api);
  final ApiClient _api;

  bool _initialized = false;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  /// Колбэк, который тригерится при тапе по push (foreground / background).
  /// Прокидываем из App, где есть доступ к роутеру.
  void Function(RemoteMessage message)? onMessageTap;

  Future<void> bootstrap() async {
    if (_initialized) return;
    _initialized = true;

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    await messaging.subscribeToTopic('all');

    // foreground-сообщения превращаем в локальные уведомления внутри UI
    // (UI пусть сам решает: snackbar/badge).
    _onMessageSub = FirebaseMessaging.onMessage.listen((msg) {
      log('FCM foreground: ${msg.messageId}');
      // foreground notifications are surfaced via NotificationsBloc badge.
    });

    // Тап по push когда приложение в background.
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      onMessageTap?.call(msg);
    });

    // Cold start через push.
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      onMessageTap?.call(initial);
    }

    _onTokenRefreshSub = messaging.onTokenRefresh.listen(_registerToken);
  }

  /// Регистрирует текущий FCM-токен на бэке. Вызывается после login.
  Future<void> registerCurrentToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _registerToken(token);
    } catch (e) {
      log('push registerCurrentToken failed: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await _api.postJson(
        Urls.devicesRegister,
        body: {
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
        requireAuth: true,
      );
    } catch (e) {
      log('push register failed: $e');
    }
  }

  Future<void> unregister() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _api.postJson(
        Urls.devicesUnregister,
        body: {'token': token},
        requireAuth: true,
      );
    } catch (e) {
      log('push unregister failed: $e');
    }
  }

  Future<void> dispose() async {
    await _onMessageSub?.cancel();
    await _onTokenRefreshSub?.cancel();
  }
}
