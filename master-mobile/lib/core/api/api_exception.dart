import 'package:dio/dio.dart';

/// Normalised view of API errors. Built from DioException + the Laravel error
/// shape so feature code can `switch` on a single class instead of digging
/// through nested response maps.
sealed class ApiException implements Exception {
  ApiException(this.message, this.statusCode);
  final String message;
  final int? statusCode;

  factory ApiException.fromDio(DioException e) {
    final res = e.response;
    final code = res?.statusCode;
    final data = res?.data;

    if (data is Map<String, dynamic>) {
      final msg = (data['message'] as String?) ?? e.message ?? 'Network error';

      // 422 validation
      if (code == 422 && data['errors'] is Map) {
        final errors = (data['errors'] as Map).map(
          (k, v) => MapEntry(k.toString(), (v as List).map((e) => e.toString()).toList()),
        );
        return ValidationException(msg, errors);
      }

      // 402 subscription gate
      if (code == 402 && data['code'] == 'subscription_required') {
        return SubscriptionRequiredException(
          msg,
          DateTime.tryParse((data['subscription_expires_at'] as String?) ?? ''),
        );
      }

      if (code == 401) return UnauthenticatedException(msg);
      if (code == 403) return ForbiddenException(msg);
      if (code == 404) return NotFoundException(msg);
      if (code == 429) return ThrottledException(msg);
      if (code != null && code >= 500) return ServerException(msg, code);

      return GenericApiException(msg, code);
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return NetworkException(e.message ?? 'No connection');
    }

    return GenericApiException(e.message ?? 'Unknown error', code);
  }

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

class UnauthenticatedException extends ApiException {
  UnauthenticatedException(String msg) : super(msg, 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException(String msg) : super(msg, 403);
}

class NotFoundException extends ApiException {
  NotFoundException(String msg) : super(msg, 404);
}

class ThrottledException extends ApiException {
  ThrottledException(String msg) : super(msg, 429);
}

class ServerException extends ApiException {
  ServerException(String msg, int code) : super(msg, code);
}

class NetworkException extends ApiException {
  NetworkException(String msg) : super(msg, null);
}

class GenericApiException extends ApiException {
  GenericApiException(String msg, int? code) : super(msg, code);
}

class ValidationException extends ApiException {
  ValidationException(String msg, this.errors) : super(msg, 422);
  final Map<String, List<String>> errors;

  String? firstError(String field) => errors[field]?.firstOrNull;
}

class SubscriptionRequiredException extends ApiException {
  SubscriptionRequiredException(String msg, this.expiresAt) : super(msg, 402);
  final DateTime? expiresAt;
}
