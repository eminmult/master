import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_mobile/core/api/api_client.dart';
import 'package:master_mobile/core/api/api_exception.dart';

/// Result returned by `POST /api/v1/smart-search` — the Gemini-backed
/// classifier that picks the best matching category for a free-text problem
/// description and an optional photo.
class SmartSearchResult {
  const SmartSearchResult({
    this.categoryId,
    this.categoryName,
    this.title,
    this.description,
    this.confidence = 0,
  });

  final int? categoryId;
  final String? categoryName;
  final String? title;
  final String? description;
  final double confidence;

  factory SmartSearchResult.fromJson(Map<String, dynamic> json) {
    return SmartSearchResult(
      categoryId: (json['category_id'] as num?)?.toInt(),
      categoryName: json['category_name']?.toString(),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    );
  }
}

final smartSearchRepositoryProvider = Provider<SmartSearchRepository>((ref) {
  return SmartSearchRepository(ref.watch(apiClientProvider));
});

class SmartSearchRepository {
  SmartSearchRepository(this._dio);
  final Dio _dio;

  /// `image` is base64-encoded bytes (no `data:` prefix). Backend also
  /// accepts a data-URL; we send the cleaner form to keep payload small.
  Future<SmartSearchResult> classify({
    required String description,
    String? image,
    String? imageMime,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/smart-search',
        data: {
          'description': description.trim(),
          if (image != null) 'image': image,
          if (imageMime != null) 'image_mime': imageMime,
        },
        options: Options(
          // Image classification can take a few seconds on Gemini.
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      return SmartSearchResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
