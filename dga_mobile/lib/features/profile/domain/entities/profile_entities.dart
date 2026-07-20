import 'package:flutter/foundation.dart';
import '../../../authentication/domain/entities/auth_entities.dart';

@immutable
class ProfileStatsEntity {
  final int totalInspections;
  final int detectedDiseases;
  final int viewedRecommendations;
  final double healthyTreeRate;

  const ProfileStatsEntity({
    required this.totalInspections,
    required this.detectedDiseases,
    required this.viewedRecommendations,
    required this.healthyTreeRate,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfileStatsEntity &&
        other.totalInspections == totalInspections &&
        other.detectedDiseases == detectedDiseases &&
        other.viewedRecommendations == viewedRecommendations &&
        other.healthyTreeRate == healthyTreeRate;
  }

  @override
  int get hashCode {
    return Object.hash(
      totalInspections,
      detectedDiseases,
      viewedRecommendations,
      healthyTreeRate,
    );
  }
}

@immutable
class UserProfileEntity {
  final String avatarUrl;
  final String fullName;
  final String role;
  final String email;
  final String phoneNumber;
  final String workUnit;
  final String address;
  final String dob;
  final String gender;
  final FarmEntity? farmInfo;
  final ProfileStatsEntity stats;

  const UserProfileEntity({
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

  UserProfileEntity copyWith({
    String? avatarUrl,
    String? fullName,
    String? role,
    String? email,
    String? phoneNumber,
    String? workUnit,
    String? address,
    String? dob,
    String? gender,
    FarmEntity? farmInfo,
    ProfileStatsEntity? stats,
  }) {
    return UserProfileEntity(
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      workUnit: workUnit ?? this.workUnit,
      address: address ?? this.address,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      farmInfo: farmInfo ?? this.farmInfo,
      stats: stats ?? this.stats,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfileEntity &&
        other.avatarUrl == avatarUrl &&
        other.fullName == fullName &&
        other.role == role &&
        other.email == email &&
        other.phoneNumber == phoneNumber &&
        other.workUnit == workUnit &&
        other.address == address &&
        other.dob == dob &&
        other.gender == gender &&
        other.farmInfo == farmInfo &&
        other.stats == stats;
  }

  @override
  int get hashCode {
    return Object.hash(
      avatarUrl,
      fullName,
      role,
      email,
      phoneNumber,
      workUnit,
      address,
      dob,
      gender,
      farmInfo,
      stats,
    );
  }
}
