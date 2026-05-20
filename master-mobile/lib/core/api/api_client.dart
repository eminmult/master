import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:master_mobile/core/api/auth_interceptor.dart';
import 'package:master_mobile/core/api/locale_interceptor.dart';
import 'package:master_mobile/core/auth/auth_storage.dart';
import 'package:master_mobile/core/config/app_config.dart';
import 'package:master_mobile/core/i18n/locale_controller.dart';
import 'package:master_mobile/features/addresses/data/active_address_controller.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

/// One Dio instance shared across the app. Composes:
///   1. LocaleInterceptor — Accept + Accept-Language
///   2. AuthInterceptor   — bearer token + refresh-on-401
///   3. PrettyDioLogger   — debug only
final apiClientProvider = Provider<Dio>((ref) {
  final storage = ref.watch(authStorageProvider);
  final localeProvider = ref.watch(localeControllerProvider);

  final base = BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
    contentType: 'application/json',
    responseType: ResponseType.json,
  );

  final dio = Dio(base);

  // Refresh dio: same base URL, NO auth interceptor (avoids recursion).
  // Locale interceptor still applied so refreshed responses honor language.
  final refreshDio = Dio(base)
    ..interceptors.add(LocaleInterceptor(() => localeProvider));

  dio.interceptors.addAll([
    LocaleInterceptor(() => localeProvider),
    AuthInterceptor(storage, refreshDio, () async {
      // Force re-login by clearing storage; UI listens to authStateProvider
      // and routes to /login when token disappears.
      await storage.clear();
    }),
    if (!AppConfig.isProduction)
      PrettyDioLogger(requestBody: true, responseBody: true, error: true),
  ]);

  return dio;
});

final authStorageProvider = Provider<AuthStorage>((ref) {
  return AuthStorage(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
    ref.watch(sharedPrefsProvider),
  );
});

