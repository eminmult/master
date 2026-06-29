/// Базовое исключение приложения. Все ошибки в бизнес-слое должны быть
/// подклассами [AppException] — это даёт single point of pattern-match в BLoC.
class AppException implements Exception {
  const AppException({this.message, this.statusCode});

  final String? message;
  final int? statusCode;

  @override
  String toString() => '$runtimeType(${statusCode ?? '-'}): ${message ?? ''}';
}

class NetworkException extends AppException {
  const NetworkException({super.message = 'Нет соединения с интернетом'});
}

class ServerException extends AppException {
  const ServerException({
    super.message = 'Ошибка на сервере',
    super.statusCode,
  });
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({super.message = 'Требуется авторизация'})
      : super(statusCode: 401);
}

class ForbiddenException extends AppException {
  const ForbiddenException({super.message = 'Доступ запрещён'})
      : super(statusCode: 403);
}

class NotFoundException extends AppException {
  const NotFoundException({super.message = 'Не найдено'})
      : super(statusCode: 404);
}

class ValidationException extends AppException {
  const ValidationException({
    super.message = 'Некорректные данные',
    this.errors,
  }) : super(statusCode: 422);

  final Map<String, List<String>>? errors;
}

class UnknownException extends AppException {
  const UnknownException({super.message = 'Что-то пошло не так'});
}
