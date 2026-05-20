import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:master_mobile/core/api/api_client.dart';
import 'package:master_mobile/core/api/api_exception.dart';

part 'notifications_repository.freezed.dart';
part 'notifications_repository.g.dart';

/// Backend stores `title`/`body` as JSON-encoded localized maps. The mobile UI
/// picks the active locale's value via `localized()` / `bodyLocalized()`.
///
/// `fromJson` is the canonical Freezed-detected one-liner so json_serializable
/// can generate the `.g.dart`. Server payloads with stringified maps go
/// through `AppNotification.fromApiJson` instead, which normalises before
/// calling fromJson.
@freezed
class AppNotification with _$AppNotification {
  const AppNotification._();

  const factory AppNotification({
    required int id,
    required String type,
    required Map<String, String> title,
    required Map<String, String> body,
    @Default({}) Map<String, dynamic> data,
    @JsonKey(name: 'is_read') @Default(false) bool isRead,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);

  /// Real backend factory — title/body may arrive as JSON strings or already
  /// decoded maps, and (depending on which controller built the response)
  /// either under singular `title`/`body` keys or pluralised `titles`/`bodies`
  /// keys. Both shapes are normalised before delegating to fromJson.
  factory AppNotification.fromApiJson(Map<String, dynamic> json) {
    return AppNotification.fromJson({
      ...json,
      'title': _decodeLocalised(json['title'] ?? json['titles']),
      'body': _decodeLocalised(json['body'] ?? json['bodies']),
    });
  }

  static Map<String, String> _decodeLocalised(dynamic v) {
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val.toString()));
    if (v is String && v.startsWith('{')) {
      try {
        final m = jsonDecode(v);
        if (m is Map) return m.map((k, val) => MapEntry(k.toString(), val.toString()));
      } catch (_) {}
    }
    if (v is String) return {'az': v, 'ru': v, 'en': v};
    return {};
  }

  String localized(String code, [String fallback = 'az']) =>
      title[code] ?? title[fallback] ?? title.values.firstOrNull ?? '';

  String bodyLocalized(String code, [String fallback = 'az']) =>
      body[code] ?? body[fallback] ?? body.values.firstOrNull ?? '';
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(apiClientProvider));
});

class NotificationsRepository {
  NotificationsRepository(this._dio);
  final Dio _dio;

  Future<List<AppNotification>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/notifications');
      final list = (res.data!['notifications'] as List?) ?? [];
      return list.map((e) => AppNotification.fromApiJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<int> unreadCount() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/notifications/unread-count');
      // Backend sends `unread`; tolerate `count` for older responses.
      final n = (res.data!['unread'] ?? res.data!['count']) as num?;
      return n?.toInt() ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _dio.post<void>('/notifications/$id/read');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.post<void>('/notifications/read-all');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
