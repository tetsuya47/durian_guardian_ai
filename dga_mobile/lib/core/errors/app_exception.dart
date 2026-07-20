class AppException implements Exception {
  final String message;
  final dynamic details;

  const AppException(this.message, [this.details]);

  @override
  String toString() => 'AppException: $message${details != null ? ' ($details)' : ''}';
}

class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    required String message,
    this.statusCode,
    dynamic details,
  }) : super(message, details);

  @override
  String toString() => 'ServerException [$statusCode]: $message';
}

class CacheException extends AppException {
  const CacheException({required String message, dynamic details})
      : super(message, details);
}

class NetworkException extends AppException {
  const NetworkException({required String message, dynamic details})
      : super(message, details);
}

class ValidationException extends AppException {
  const ValidationException({required String message, dynamic details})
      : super(message, details);
}

class TimeoutException extends AppException {
  const TimeoutException({required String message, dynamic details})
      : super(message, details);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({required String message, dynamic details})
      : super(message, details);
}

class PermissionException extends AppException {
  const PermissionException({required String message, dynamic details})
      : super(message, details);
}

class AuthException extends AppException {
  const AuthException({required String message, dynamic details})
      : super(message, details);
}
