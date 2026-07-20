import '../../domain/entities/profile_entities.dart';
import '../../../authentication/domain/entities/auth_entities.dart';

class FarmInfoDto {
  final String farmName;
  final String farmCode;
  final String address;
  final int treeCount;
  final String joinedDate;

  const FarmInfoDto({
    required this.farmName,
    required this.farmCode,
    required this.address,
    required this.treeCount,
    required this.joinedDate,
  });

  factory FarmInfoDto.fromJson(Map<String, dynamic> json) {
    return FarmInfoDto(
      farmName: json['farm_name'] as String? ?? '',
      farmCode: json['farm_code'] as String? ?? '',
      address: json['address'] as String? ?? '',
      treeCount: json['tree_count'] as int? ?? 0,
      joinedDate: json['joined_date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farm_name': farmName,
      'farm_code': farmCode,
      'address': address,
      'tree_count': treeCount,
      'joined_date': joinedDate,
    };
  }

  FarmEntity toDomain() {
    return FarmEntity(
      farmName: farmName,
      farmCode: farmCode,
      address: address,
      treeCount: treeCount,
      joinedDate: joinedDate,
    );
  }
}

class ProfileStatsDto {
  final int totalInspections;
  final int detectedDiseases;
  final int viewedRecommendations;
  final double healthyTreeRate;

  const ProfileStatsDto({
    required this.totalInspections,
    required this.detectedDiseases,
    required this.viewedRecommendations,
    required this.healthyTreeRate,
  });

  factory ProfileStatsDto.fromJson(Map<String, dynamic> json) {
    return ProfileStatsDto(
      totalInspections: json['total_inspections'] as int? ?? 0,
      detectedDiseases: json['detected_diseases'] as int? ?? 0,
      viewedRecommendations: json['viewed_recommendations'] as int? ?? 0,
      healthyTreeRate: (json['healthy_tree_rate'] as num?)?.toDouble() ?? 100.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_inspections': totalInspections,
      'detected_diseases': detectedDiseases,
      'viewed_recommendations': viewedRecommendations,
      'healthy_tree_rate': healthyTreeRate,
    };
  }

  ProfileStatsEntity toDomain() {
    return ProfileStatsEntity(
      totalInspections: totalInspections,
      detectedDiseases: detectedDiseases,
      viewedRecommendations: viewedRecommendations,
      healthyTreeRate: healthyTreeRate,
    );
  }
}

class UserProfileResponseDto {
  final String avatarUrl;
  final String fullName;
  final String role;
  final String email;
  final String phoneNumber;
  final String workUnit;
  final String address;
  final String dob;
  final String gender;
  final FarmInfoDto? farmInfo;
  final ProfileStatsDto stats;

  const UserProfileResponseDto({
    required this.avatarUrl,
    required this.fullName,
    required this.role,
    required this.email,
    required this.phoneNumber,
    required this.workUnit,
    required this.address,
    required this.dob,
    required this.gender,
    this.farmInfo,
    required this.stats,
  });

  factory UserProfileResponseDto.fromJson(Map<String, dynamic> json) {
    return UserProfileResponseDto(
      avatarUrl: json['avatar_url'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      role: json['role'] as String? ?? 'Nông dân',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      workUnit: json['work_unit'] as String? ?? '',
      address: json['address'] as String? ?? '',
      dob: json['dob'] as String? ?? '',
      gender: json['gender'] as String? ?? 'Nam',
      farmInfo: json['farm_info'] != null
          ? FarmInfoDto.fromJson(json['farm_info'] as Map<String, dynamic>)
          : null,
      stats: ProfileStatsDto.fromJson(
          json['stats'] as Map<String, dynamic>? ?? const {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avatar_url': avatarUrl,
      'full_name': fullName,
      'role': role,
      'email': email,
      'phone_number': phoneNumber,
      'work_unit': workUnit,
      'address': address,
      'dob': dob,
      'gender': gender,
      'farm_info': farmInfo?.toJson(),
      'stats': stats.toJson(),
    };
  }

  UserProfileEntity toDomain() {
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
      farmInfo: farmInfo?.toDomain(),
      stats: stats.toDomain(),
    );
  }
}
