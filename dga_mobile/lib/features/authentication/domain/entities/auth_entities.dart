import 'package:flutter/foundation.dart';

@immutable
class FarmEntity {
  final String farmName;
  final String farmCode;
  final String address;
  final int treeCount;
  final String joinedDate;

  const FarmEntity({
    required this.farmName,
    required this.farmCode,
    required this.address,
    required this.treeCount,
    required this.joinedDate,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FarmEntity &&
        other.farmName == farmName &&
        other.farmCode == farmCode &&
        other.address == address &&
        other.treeCount == treeCount &&
        other.joinedDate == joinedDate;
  }

  @override
  int get hashCode {
    return Object.hash(farmName, farmCode, address, treeCount, joinedDate);
  }

  @override
  String toString() {
    return 'FarmEntity(farmName: $farmName, farmCode: $farmCode, treeCount: $treeCount)';
  }
}

@immutable
class UserEntity {
  final String fullName;
  final String email;
  final String role;
  final String phoneNumber;
  final String workUnit;
  final String address;
  final String dob;
  final String gender;
  final FarmEntity? farmInfo;

  const UserEntity({
    required this.fullName,
    required this.email,
    required this.role,
    required this.phoneNumber,
    required this.workUnit,
    required this.address,
    required this.dob,
    required this.gender,
    this.farmInfo,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEntity &&
        other.fullName == fullName &&
        other.email == email &&
        other.role == role &&
        other.phoneNumber == phoneNumber &&
        other.workUnit == workUnit &&
        other.address == address &&
        other.dob == dob &&
        other.gender == gender &&
        other.farmInfo == farmInfo;
  }

  @override
  int get hashCode {
    return Object.hash(
      fullName,
      email,
      role,
      phoneNumber,
      workUnit,
      address,
      dob,
      gender,
      farmInfo,
    );
  }

  @override
  String toString() {
    return 'UserEntity(fullName: $fullName, email: $email, role: $role)';
  }
}
