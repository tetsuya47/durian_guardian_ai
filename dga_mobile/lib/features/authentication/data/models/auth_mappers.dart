import '../../domain/entities/auth_entities.dart';
import '../../../profile/data/models/profile_dtos.dart';

extension FarmInfoDtoMapper on FarmInfoDto {
  FarmEntity toEntity() {
    return FarmEntity(
      farmName: farmName,
      farmCode: farmCode,
      address: address,
      treeCount: treeCount,
      joinedDate: joinedDate,
    );
  }
}

extension FarmEntityMapper on FarmEntity {
  FarmInfoDto toDto() {
    return FarmInfoDto(
      farmName: farmName,
      farmCode: farmCode,
      address: address,
      treeCount: treeCount,
      joinedDate: joinedDate,
    );
  }
}

extension UserEntityMapper on UserEntity {
  UserProfileResponseDto toDto(String avatarUrl, ProfileStatsDto stats) {
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
      farmInfo: farmInfo != null
          ? farmInfo!.toDto()
          : const FarmInfoDto(
              farmName: '',
              farmCode: '',
              address: '',
              treeCount: 0,
              joinedDate: '',
            ),
      stats: stats,
    );
  }
}
