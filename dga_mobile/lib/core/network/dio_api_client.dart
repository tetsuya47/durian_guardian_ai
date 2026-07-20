import 'package:dio/dio.dart' hide RequestOptions;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/app_exception.dart';
import '../constants/storage_keys.dart';
import '../../services/storage_service.dart';
import 'environment_config.dart';
import 'interceptors.dart';
import 'network_foundation.dart';

/// Concrete implementation of [ApiClient] using Dio.
///
/// Features:
///   - Base URL driven by [EnvironmentConfig]
///   - Timeouts (connect / receive / send)
///   - Auth interceptor (Bearer injection + 401 refresh)
///   - Logging interceptor (debug builds only)
///   - Error interceptor (DioException → AppException)
///   - Multipart form-data support via [requestMultipart]
///   - Generic JSON GET / POST / PUT / DELETE via [request]
class DioApiClient implements ApiClient {
  DioApiClient({
    required Future<String?> Function() tokenReader,
    required Future<void> Function(String) tokenWriter,
    required Future<String?> Function() refreshTokenReader,
    required Future<void> Function(String) refreshTokenWriter,
    required Future<void> Function() sessionClearer,
  }) : _dio = _buildDio() {
    _dio.interceptors.addAll([
      LoggingInterceptor(),
      AuthInterceptor(
        tokenReader: tokenReader,
        tokenWriter: tokenWriter,
        refreshTokenReader: refreshTokenReader,
        refreshTokenWriter: refreshTokenWriter,
        sessionClearer: sessionClearer,
        dio: _dio,
      ),
      ErrorInterceptor(),
    ]);
  }

  final Dio _dio;

  static Dio _buildDio() {
    return Dio(
      BaseOptions(
        baseUrl: EnvironmentConfig.baseUrl,
        connectTimeout: TimeoutConfig.connectTimeout,
        receiveTimeout: TimeoutConfig.receiveTimeout,
        sendTimeout: TimeoutConfig.sendTimeout,
        responseType: ResponseType.json,
        contentType: 'application/json',
        headers: {
          'Accept': 'application/json',
        },
      ),
    );
  }

  // ─── ApiClient contract ───────────────────────────────────────────────────

  @override
  Future<ResponseWrapper<T>> request<T>({
    required String path,
    required String method,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    RequestOptions? options,
    required T Function(dynamic json) decoder,
  }) async {
    try {
      final dioOptions = Options(
        method: method,
        headers: options?.headers,
        receiveTimeout: options?.receiveTimeout,
      );

      final response = await _dio.request<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: dioOptions,
      );

      return ResponseWrapper.fromJson(
        response.data as Map<String, dynamic>,
        decoder,
      );
    } on DioException catch (e) {
      throw _dioToAppException(e);
    }
  }

  /// Multipart POST request (e.g. for AI disease detection uploads).
  Future<ResponseWrapper<T>> requestMultipart<T>({
    required String path,
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) decoder,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: Options(contentType: 'multipart/form-data'),
      );

      return ResponseWrapper.fromJson(
        response.data as Map<String, dynamic>,
        decoder,
      );
    } on DioException catch (e) {
      throw _dioToAppException(e);
    }
  }

  // ─── Convenience helpers ──────────────────────────────────────────────────

  Future<ResponseWrapper<T>> get<T>({
    required String path,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) decoder,
  }) =>
      request(
        path: path,
        method: 'GET',
        queryParameters: queryParameters,
        decoder: decoder,
      );

  Future<ResponseWrapper<T>> post<T>({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) decoder,
  }) =>
      request(
        path: path,
        method: 'POST',
        data: data,
        queryParameters: queryParameters,
        decoder: decoder,
      );

  Future<ResponseWrapper<T>> put<T>({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) decoder,
  }) =>
      request(
        path: path,
        method: 'PUT',
        data: data,
        queryParameters: queryParameters,
        decoder: decoder,
      );

  Future<ResponseWrapper<T>> delete<T>({
    required String path,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) decoder,
  }) =>
      request(
        path: path,
        method: 'DELETE',
        queryParameters: queryParameters,
        decoder: decoder,
      );

  // ─── Private ──────────────────────────────────────────────────────────────

  AppException _dioToAppException(DioException e) {
    // The ErrorInterceptor already wraps the error; retrieve it.
    if (e.error is AppException) return e.error as AppException;
    return AppException(e.message ?? 'Network error', e);
  }
}

/// Riverpod provider for [DioApiClient].
///
/// Requires [storageServiceProvider] to be overridden in [ProviderScope].
/// See [main.dart] for how StorageService is wired.
///
/// Usage:
///   final client = ref.read(dioApiClientProvider);
final dioApiClientProvider = Provider<DioApiClient>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return DioApiClient(
    tokenReader: () => storageService.readSecure(StorageKeys.token),
    tokenWriter: (token) => storageService.writeSecure(StorageKeys.token, token),
    refreshTokenReader: () => storageService.readSecure(StorageKeys.refreshToken),
    refreshTokenWriter: (token) => storageService.writeSecure(StorageKeys.refreshToken, token),
    sessionClearer: () async {
      await storageService.deleteSecure(StorageKeys.token);
      await storageService.deleteSecure(StorageKeys.refreshToken);
      await storageService.remove('latest_scanned_disease');
    },
  );
});
