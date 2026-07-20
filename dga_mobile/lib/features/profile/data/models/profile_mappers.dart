import '../../domain/entities/profile_entities.dart';
import '../../../authentication/data/models/auth_mappers.dart';
import 'profile_dtos.dart';

extension ProfileStatsDtoMapper on ProfileStatsDto {
  ProfileStatsEntity toEntity() {
    return ProfileStatsEntity(
      totalInspections: totalInspections,
      detectedDiseases: detectedDiseases,
      viewedRecommendations: viewedRecommendations,
      healthyTreeRate: healthyTreeRate,
    );
  }
}

extension ProfileStatsEntityMapper on ProfileStatsEntity {
  ProfileStatsDto toDto() {
    return ProfileStatsDto(
      totalInspections: totalInspections,
      detectedDiseases: detectedDiseases,
      viewedRecommendations: viewedRecommendations,
      healthyTreeRate: healthyTreeRate,
    );
  }
}

extension UserProfileResponseDtoMapper on UserProfileResponseDto {
  UserProfileEntity toEntity() {
    return UserProfileEntity(
      avatarUrl: avatarUrl,
      fullName: fullName,
      role: role,
      email: email,
      phoneNumber: phoneNumber,
      workUnit: workUnit,
      address: address,
      dob: dob,
      gender: gender,
      farmInfo: farmInfo?.toEntity(),
      stats: stats.toEntity(),
    );
  }
}

extension UserProfileEntityMapper on UserProfileEntity {
  UserProfileResponseDto toDto() {
    return UserProfileResponseDto(
      avatarUrl: avatarUrl,
      fullName: fullName,
      role: role,
      email: email,
      phoneNumber: phoneNumber,
      workUnit: workUnit,
      address: address,
      dob: dob,
      gender: gender,
      farmInfo: farmInfo?.toDto(),
      stats: stats.toDto(),
    );
  }
}
