import '../../../../core/network/result.dart';
import '../../domain/entities/profile_entities.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/mock_profile_datasource.dart';
import '../models/profile_dtos.dart';

class MockProfileRepository implements ProfileRepository {
  const MockProfileRepository();

  @override
  Future<Result<UserProfileEntity>> getUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    try {
      final mock = MockProfileDatasource.mockUser;
      final dto = UserProfileResponseDto(
        avatarUrl: mock.avatarUrl,
        fullName: mock.fullName,
        role: mock.role,
        email: mock.email,
        phoneNumber: mock.phoneNumber,
        workUnit: mock.workUnit,
        address: mock.address,
        dob: mock.dob,
        gender: mock.gender,
        farmInfo: FarmInfoDto(
          farmName: mock.farmInfo.farmName,
          farmCode: mock.farmInfo.farmCode,
          address: mock.farmInfo.address,
          treeCount: mock.farmInfo.treeCount,
          joinedDate: mock.farmInfo.joinedDate,
        ),
        stats: ProfileStatsDto(
          totalInspections: mock.stats.totalInspections,
          detectedDiseases: mock.stats.detectedDiseases,
          viewedRecommendations: mock.stats.viewedRecommendations,
          healthyTreeRate: mock.stats.healthyTreeRate,
        ),
      );
      return Success(dto.toDomain());
    } catch (e) {
      return Failure('Không thể tải hồ sơ người dùng', e);
    }
  }

  @override
  Future<Result<UserProfileEntity>> updateUserProfile(String fullName, String email, String phoneNumber) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    try {
      final mock = MockProfileDatasource.mockUser;
      final dto = UserProfileResponseDto(
        avatarUrl: mock.avatarUrl,
        fullName: fullName,
        role: mock.role,
        email: email,
        phoneNumber: phoneNumber,
        workUnit: mock.workUnit,
        address: mock.address,
        dob: mock.dob,
        gender: mock.gender,
        farmInfo: FarmInfoDto(
          farmName: mock.farmInfo.farmName,
          farmCode: mock.farmInfo.farmCode,
          address: mock.farmInfo.address,
          treeCount: mock.farmInfo.treeCount,
          joinedDate: mock.farmInfo.joinedDate,
        ),
        stats: ProfileStatsDto(
          totalInspections: mock.stats.totalInspections,
          detectedDiseases: mock.stats.detectedDiseases,
          viewedRecommendations: mock.stats.viewedRecommendations,
          healthyTreeRate: mock.stats.healthyTreeRate,
        ),
      );
      return Success(dto.toDomain());
    } catch (e) {
      return Failure('Không thể cập nhật hồ sơ người dùng', e);
    }
  }
}
