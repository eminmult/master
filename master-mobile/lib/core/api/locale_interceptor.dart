import 'dart:ui';
import 'package:dio/dio.dart';

/// Sends Accept-Language so the server returns content in the user's locale.
/// Uses a callback so the locale can change at runtime when the user switches
/// languages without rebuilding Dio.
class LocaleInterceptor extends Interceptor {
  LocaleInterceptor(this._localeProvider);

  final Locale Function() _localeProvider;

  static const supportedCodes = {'az', 'ru', 'en', 'tr', 'ar'};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final code = _localeProvider().languageCode;
    options.headers['Accept-Language'] = supportedCodes.contains(code) ? code : 'az';
    options.headers['Accept'] = 'application/json';
    handler.next(options);
  }
}
