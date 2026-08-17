abstract class ApiClient {
  Future<ResponseWrapper<T>> request<T>({
    required String path,
    required String method,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    RequestOptions? options,
    required T Function(dynamic json) decoder,
  });
}

class NetworkConfig {
  NetworkConfig._();
  static const String baseUrl = 'https://api.durian-guardian.ai/v1';
  static const String apiVersion = 'v1';
}

class TimeoutConfig {
  TimeoutConfig._();
  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);
}

class RequestOptions {
  final Map<String, dynamic>? headers;
  final Duration? connectTimeout;
  final Duration? receiveTimeout;

  const RequestOptions({
    this.headers,
    this.connectTimeout,
    this.receiveTimeout,
  });
}

class ResponseWrapper<T> {
  final T? data;
  final String message;
  final int statusCode;
  final bool success;

  const ResponseWrapper({
    this.data,
    required this.message,
    required this.statusCode,
    required this.success,
  });

  factory ResponseWrapper.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) decoder,
  ) {
    return ResponseWrapper(
      data: json['data'] != null ? decoder(json['data']) : null,
      message: json['message'] as String? ?? '',
      statusCode: json['status_code'] as int? ?? 200,
      success: json['success'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson(Object? Function(T value) encoder) {
    return {
      'data': data != null ? encoder(data as T) : null,
      'message': message,
      'status_code': statusCode,
      'success': success,
    };
  }
}
