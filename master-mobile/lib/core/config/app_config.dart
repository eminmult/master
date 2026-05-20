/// Centralised compile-time config. Read from --dart-define-from-file=.env so
/// the same source builds against staging / production with no code changes.
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://itez.app/api/v1',
  );

  // Reverb (WebSocket) host is a DNS-only subdomain that bypasses Cloudflare
  // entirely. Flexible SSL silently downgrades WSS → HTTP on the proxied
  // itez.app path, which mixed-content blocks in the browser.
  static const String wsHost = String.fromEnvironment('WS_HOST', defaultValue: 'realtime.itez.app');
  static const int wsPort = int.fromEnvironment('WS_PORT', defaultValue: 443);
  static const String wsScheme = String.fromEnvironment('WS_SCHEME', defaultValue: 'wss');
  static const String reverbAppKey = String.fromEnvironment(
    'REVERB_APP_KEY',
    defaultValue: '88457d12f00a60a993b63821e498ffc7e94661a6c807663b287cb74175956173',
  );

  static const String googleMapsKeyAndroid = String.fromEnvironment('GOOGLE_MAPS_API_KEY_ANDROID');
  static const String googleMapsKeyIos = String.fromEnvironment('GOOGLE_MAPS_API_KEY_IOS');

  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const String appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'production');

  static bool get isProduction => appEnv == 'production';

  /// Refresh the bearer token this much time before expiry. Server expiry is
  /// 30 days; we proactively refresh once a week to keep the user signed in.
  static const Duration refreshBeforeExpiry = Duration(days: 23);
}
