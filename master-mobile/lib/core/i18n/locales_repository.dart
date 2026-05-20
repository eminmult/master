import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:master_mobile/core/api/api_client.dart';
import 'package:master_mobile/core/api/api_exception.dart';

part 'locales_repository.freezed.dart';
part 'locales_repository.g.dart';

@freezed
class AppLocale with _$AppLocale {
  const factory AppLocale({
    required String code,
    required String name,
    @Default('ltr') String dir,
    @JsonKey(name: 'is_default') @Default(false) bool isDefault,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
  }) = _AppLocale;

  factory AppLocale.fromJson(Map<String, dynamic> json) => _$AppLocaleFromJson(json);
}

final localesRepositoryProvider = Provider<LocalesRepository>((ref) {
  return LocalesRepository(ref.watch(apiClientProvider));
});

class LocalesRepository {
  LocalesRepository(this._dio);
  final Dio _dio;

  /// Public list of active locales — used to populate the language switcher
  /// and validate the persisted preference.
  Future<List<AppLocale>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/i18n/locales');
      final list = (res.data!['locales'] as List?) ?? [];
      return list.map((e) => AppLocale.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Persist on the backend; called on every language switch when the user
  /// is authenticated. Failures are non-fatal — the local choice still applies.
  Future<void> updateMyLocale(String code) async {
    try {
      await _dio.patch<Map<String, dynamic>>('/me/locale', data: {'locale': code});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

/// Cached fetch of the active locale list. Both the language selector and
/// the controller use this — fallback to the hardcoded supported set if the
/// request fails (e.g. cold start without network).
final localesListProvider = FutureProvider<List<AppLocale>>((ref) async {
  try {
    final repo = ref.watch(localesRepositoryProvider);
    return await repo.list();
  } catch (_) {
    return const [
      AppLocale(code: 'az', name: 'Azərbaycan', dir: 'ltr', isDefault: true),
      AppLocale(code: 'ru', name: 'Русский'),
      AppLocale(code: 'en', name: 'English'),
      AppLocale(code: 'tr', name: 'Türkçe'),
      AppLocale(code: 'ar', name: 'العربية', dir: 'rtl'),
    ];
  }
});
