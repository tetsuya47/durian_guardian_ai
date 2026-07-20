class MockFarmInfo {
  final String farmName;
  final String farmCode;
  final String address;
  final int treeCount;
  final String joinedDate; // dd/MM/yyyy

  const MockFarmInfo({
    required this.farmName,
    required this.farmCode,
    required this.address,
    required this.treeCount,
    required this.joinedDate,
  });
}

class MockProfileStats {
  final int totalInspections;
  final int detectedDiseases;
  final int viewedRecommendations;
  final double healthyTreeRate; // 0.0 to 100.0

  const MockProfileStats({
    required this.totalInspections,
    required this.detectedDiseases,
    required this.viewedRecommendations,
    required this.healthyTreeRate,
  });
}

class MockUserProfile {
  final String avatarUrl;
  final String fullName;
  final String role;
  final String email;
  final String phoneNumber;
  final String workUnit;
  final String address;
  final String dob; // dd/MM/yyyy
  final String gender;
  final MockFarmInfo farmInfo;
  final MockProfileStats stats;

  const MockUserProfile({
    required this.avatarUrl,
    required this.fullName,
    required this.role,
    required this.email,
    required this.phoneNumber,
    required this.workUnit,
    required this.address,
    required this.dob,
    required this.gender,
    required this.farmInfo,
    required this.stats,
  });

  MockUserProfile copyWith({
    String? avatarUrl,
    String? fullName,
    String? role,
    String? email,
    String? phoneNumber,
    String? workUnit,
    String? address,
    String? dob,
    String? gender,
    MockFarmInfo? farmInfo,
    MockProfileStats? stats,
  }) {
    return MockUserProfile(
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
}
