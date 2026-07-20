import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_api_client.dart';
import '../../../authentication/data/models/auth_dtos.dart';
import '../models/profile_dtos.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileResponseDto> getUserProfile();
  Future<UserProfileResponseDto> updateUserProfile(String fullName, String email, String phoneNumber);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final DioApiClient _apiClient;

  const ProfileRemoteDataSourceImpl(this._apiClient);

  @override
  Future<UserProfileResponseDto> getUserProfile() async {
    final response = await _apiClient.request<UserOutDto>(
      path: ApiEndpoints.me,
      method: 'GET',
      decoder: (json) => UserOutDto.fromJson(json as Map<String, dynamic>),
    );
    final userDto = response.data;
    if (userDto == null) throw Exception('Không thể tải thông tin người dùng.');
    
    return UserProfileResponseDto(
      avatarUrl: '',
      fullName: userDto.fullName,
      role: _mapRoleToUi(userDto.role),
      email: userDto.email,
      phoneNumber: '',
      workUnit: '',
      address: '',
      dob: '',
      gender: '',
      farmInfo: null,
      stats: const ProfileStatsDto(
        totalInspections: 0,
        detectedDiseases: 0,
        viewedRecommendations: 0,
        healthyTreeRate: 0.0,
      ),
    );
  }

  @override
  Future<UserProfileResponseDto> updateUserProfile(
      String fullName, String email, String phoneNumber) async {
    final response = await _apiClient.request<UserOutDto>(
      path: ApiEndpoints.profile,
      method: 'PUT',
      data: {
        'full_name': fullName,
        'email': email,
      },
      decoder: (json) => UserOutDto.fromJson(json as Map<String, dynamic>),
    );
    final userDto = response.data;
    if (userDto == null) throw Exception('Không thể cập nhật thông tin người dùng.');

    return UserProfileResponseDto(
      avatarUrl: '',
      fullName: userDto.fullName,
      role: _mapRoleToUi(userDto.role),
      email: userDto.email,
      phoneNumber: phoneNumber,
      workUnit: '',
      address: '',
      dob: '',
      gender: '',
      farmInfo: null,
      stats: const ProfileStatsDto(
        totalInspections: 0,
        detectedDiseases: 0,
        viewedRecommendations: 0,
        healthyTreeRate: 0.0,
      ),
    );
  }

  String _mapRoleToUi(String backendRole) {
    switch (backendRole) {
      case 'enterprise_admin':
      case 'Admin':
        return 'Quản trị viên';
      case 'farm_manager':
      case 'Farm Manager':
      case 'Company Manager':
        return 'Quản lý';
      case 'field_technician':
      case 'Inspector':
      case 'Technician':
        return 'Kỹ thuật viên';
      case 'farmer':
      default:
        return 'Nông dân';
    }
  }
}
