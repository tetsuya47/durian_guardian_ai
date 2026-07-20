import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_api_client.dart';
import '../models/auth_dtos.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponseDto> login(LoginRequestDto request);
  Future<UserOutDto> register(RegisterRequestDto request);
  Future<void> forgotPassword(ForgotPasswordRequestDto request);
  Future<LoginResponseDto> refreshToken(String refreshToken);
  Future<void> logout();
  Future<UserOutDto> getMe();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioApiClient _apiClient;

  const AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<LoginResponseDto> login(LoginRequestDto request) async {
    final response = await _apiClient.request<LoginResponseDto>(
      path: ApiEndpoints.login,
      method: 'POST',
      data: request.toJson(),
      decoder: (json) => LoginResponseDto.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  @override
  Future<UserOutDto> register(RegisterRequestDto request) async {
    final response = await _apiClient.request<UserOutDto>(
      path: ApiEndpoints.register,
      method: 'POST',
      data: request.toJson(),
      decoder: (json) => UserOutDto.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  @override
  Future<void> forgotPassword(ForgotPasswordRequestDto request) async {
    throw Exception('Tính năng quên mật khẩu chưa khả dụng.');
  }

  @override
  Future<LoginResponseDto> refreshToken(String refreshToken) async {
    final response = await _apiClient.request<LoginResponseDto>(
      path: ApiEndpoints.refresh,
      method: 'POST',
      data: {'refresh_token': refreshToken},
      decoder: (json) => LoginResponseDto.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  @override
  Future<void> logout() async {
    await _apiClient.request<void>(
      path: ApiEndpoints.logout,
      method: 'POST',
      decoder: (_) {},
    );
  }

  @override
  Future<UserOutDto> getMe() async {
    final response = await _apiClient.request<UserOutDto>(
      path: ApiEndpoints.me,
      method: 'GET',
      decoder: (json) => UserOutDto.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }
}
