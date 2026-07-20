import 'app_exception.dart';

abstract class Failure {
  final String message;
  final dynamic originalError;

  const Failure(this.message, [this.originalError]);

  @override
  String toString() => '$runtimeType: $message';

  factory Failure.fromException(dynamic exception) {
    if (exception is ServerException) {
      return ServerFailure(exception.message, exception.statusCode, exception);
    } else if (exception is NetworkException) {
      return NetworkFailure(exception.message, exception);
    } else if (exception is TimeoutException) {
      return NetworkFailure('Kết nối quá hạn: ${exception.message}', exception);
    } else if (exception is UnauthorizedException) {
      return UnauthorizedFailure(exception.message, exception);
    } else if (exception is CacheException) {
      return CacheFailure(exception.message, exception);
    } else if (exception is ValidationException) {
      return ValidationFailure(exception.message, exception);
    } else if (exception is AppException) {
      return UnknownFailure(exception.message, exception);
    }
    return UnknownFailure(exception.toString(), exception);
  }
}

class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure(String message, [this.statusCode, dynamic originalError])
      : super(message, originalError);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message, [dynamic originalError])
      : super(message, originalError);
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message, [dynamic originalError])
      : super(message, originalError);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(String message, [dynamic originalError])
      : super(message, originalError);
}

class CacheFailure extends Failure {
  const CacheFailure(String message, [dynamic originalError])
      : super(message, originalError);
}

class UnknownFailure extends Failure {
  const UnknownFailure(String message, [dynamic originalError])
      : super(message, originalError);
}
