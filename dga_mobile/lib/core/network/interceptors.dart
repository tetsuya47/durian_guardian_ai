import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../errors/app_exception.dart';
import 'environment_config.dart';

final _logger = Logger(
  printer: PrettyPrinter(methodCount: 0, errorMethodCount: 5),
);

/// Auth-aware request interceptor.
///
/// Responsibilities:
///   1. Inject `Authorization: Bearer <token>` header on every request.
///   2. On 401 response → attempt token refresh → retry original request once.
///   3. On refresh failure → clear session tokens.
///
/// Requires [tokenReader], [tokenWriter], [refreshTokenReader] and
/// [refreshTokenWriter] for reading/writing tokens without creating
/// a hard Riverpod dependency here (avoids circular refs).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.tokenReader,
    required this.tokenWriter,
    required this.refreshTokenReader,
    required this.refreshTokenWriter,
    required this.sessionClearer,
    required Dio dio,
  }) : _dio = dio;

  /// Returns the current access token from secure storage.
  final Future<String?> Function() tokenReader;

  /// Writes a new access token to secure storage.
  final Future<void> Function(String token) tokenWriter;

  /// Returns the current refresh token from secure storage.
  final Future<String?> Function() refreshTokenReader;

  /// Writes a new refresh token to secure storage (token rotation).
  final Future<void> Function(String token) refreshTokenWriter;

  /// Clears all session data when refresh fails.
  final Future<void> Function() sessionClearer;

  /// Reference to the same Dio instance so we can retry requests.
  final Dio _dio;

  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenReader();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only handle 401 once; skip refresh endpoint itself.
    if (err.response?.statusCode == 401 &&
        !_isRefreshing &&
        !(err.requestOptions.path.contains('/auth/refresh')) &&
        !(err.requestOptions.path.contains('/auth/login'))) {
      _isRefreshing = true;
      try {
        final refreshToken = await refreshTokenReader();
        if (refreshToken == null || refreshToken.isEmpty) {
          await sessionClearer();
          handler.next(err);
          return;
        }

        // Attempt token refresh using a fresh Dio (avoid interceptor loop).
        final refreshDio = Dio(BaseOptions(
          baseUrl: EnvironmentConfig.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ));
        final refreshResponse = await refreshDio.post(
          '/auth/refresh',
          data: {'refresh_token': refreshToken},
        );

        final responseData = refreshResponse.data as Map<String, dynamic>?;
        final newData = responseData?['data'] as Map<String, dynamic>?;
        final newAccessToken = newData?['access_token'] as String?;
        final newRefreshToken = newData?['refresh_token'] as String?;

        if (newAccessToken == null || newAccessToken.isEmpty) {
          await sessionClearer();
          handler.next(err);
          return;
        }

        await tokenWriter(newAccessToken);
        // Save rotated refresh token if backend provides one
        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          await refreshTokenWriter(newRefreshToken);
        }

        // Retry the original request with new token.
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(retryOptions);
        handler.resolve(retryResponse);
      } catch (e) {
        await sessionClearer();
        handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }
}

/// Debug-only logging interceptor. No-op in production.
class LoggingInterceptor extends Interceptor {
  const LoggingInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (EnvironmentConfig.isDebug) {
      _logger.d(
        '[REQUEST] ${options.method} ${options.uri}\n'
        'Headers: ${_redactAuth(options.headers)}\n'
        'Data: ${_truncate(options.data.toString())}',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (EnvironmentConfig.isDebug) {
      _logger.d(
        '[RESPONSE] ${response.statusCode} ${response.requestOptions.uri}\n'
        'Body: ${_truncate(response.data.toString())}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (EnvironmentConfig.isDebug) {
      _logger.e(
        '[ERROR] ${err.response?.statusCode ?? "NO_STATUS"} '
        '${err.requestOptions.uri}\n'
        'Message: ${err.message}\n'
        'Response: ${_truncate(err.response?.data.toString() ?? "")}',
      );
    }
    handler.next(err);
  }

  Map<String, dynamic> _redactAuth(Map<String, dynamic> headers) {
    final copy = Map<String, dynamic>.from(headers);
    if (copy.containsKey('Authorization')) {
      copy['Authorization'] = 'Bearer [REDACTED]';
    }
    return copy;
  }

  String _truncate(String s, {int maxLen = 500}) {
    return s.length > maxLen ? '${s.substring(0, maxLen)}…' : s;
  }
}

/// Maps Dio errors to strongly-typed [AppException] subclasses.
class ErrorInterceptor extends Interceptor {
  const ErrorInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Wrap into AppException so callers never see raw DioException.
    final mapped = _mapDioException(err);
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: mapped,
        message: mapped.message,
      ),
    );
  }

  AppException _mapDioException(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          message: 'Kết nối quá thời gian chờ. Vui lòng thử lại.',
          details: err.message,
        );
      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'Không thể kết nối đến máy chủ. Kiểm tra kết nối mạng.',
          details: err.message,
        );
      case DioExceptionType.badResponse:
        return _mapStatusCode(err);
      case DioExceptionType.cancel:
        return AppException('Yêu cầu đã bị hủy.', err.message);
      default:
        return AppException(
          err.message ?? 'Đã xảy ra lỗi không xác định.',
          err.message,
        );
    }
  }

  AppException _mapStatusCode(DioException err) {
    final statusCode = err.response?.statusCode ?? 0;
    final responseData = err.response?.data;
    final serverMessage = _extractMessage(responseData);

    switch (statusCode) {
      case 400:
        return ValidationException(
          message: serverMessage ?? 'Dữ liệu không hợp lệ.',
          details: responseData,
        );
      case 401:
        return UnauthorizedException(
          message: serverMessage ?? 'Phiên đăng nhập đã hết hạn.',
          details: responseData,
        );
      case 403:
        return PermissionException(
          message: serverMessage ?? 'Bạn không có quyền thực hiện thao tác này.',
          details: responseData,
        );
      case 404:
        return AppException(serverMessage ?? 'Không tìm thấy tài nguyên.', responseData);
      case 409:
        return ValidationException(
          message: serverMessage ?? 'Dữ liệu đã tồn tại.',
          details: responseData,
        );
      case 422:
        return ValidationException(
          message: serverMessage ?? 'Dữ liệu đầu vào không hợp lệ.',
          details: responseData,
        );
      default:
        return ServerException(
          message: serverMessage ?? 'Lỗi máy chủ ($statusCode). Vui lòng thử lại sau.',
          statusCode: statusCode,
          details: responseData,
        );
    }
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) return msg;
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
    }
    return null;
  }
}
