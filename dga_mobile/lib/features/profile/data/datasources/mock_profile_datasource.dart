import '../models/profile_models.dart';

class MockProfileDatasource {
  MockProfileDatasource._();

  static const MockFarmInfo mockFarm = MockFarmInfo(
    farmName: 'Vườn Sầu Riêng Phong Điền',
    farmCode: 'DGA-FARM-99',
    address: 'Mỹ Khánh, Phong Điền, Cần Thơ',
    treeCount: 368,
    joinedDate: '15/03/2025',
  );

  static const MockProfileStats mockStats = MockProfileStats(
    totalInspections: 142,
    detectedDiseases: 18,
    viewedRecommendations: 35,
    healthyTreeRate: 94.5,
  );

  static const MockUserProfile mockUser = MockUserProfile(
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80',
    fullName: 'Nguyễn Văn Nông',
    role: 'Chủ trang trại',
    email: 'nong.nguyen@durianai.vn',
    phoneNumber: '0987 654 321',
    workUnit: 'Hợp tác xã Sầu riêng Phong Điền',
    address: 'Mỹ Khánh, Phong Điền, Cần Thơ',
    dob: '12/10/1982',
    gender: 'Nam',
    farmInfo: mockFarm,
    stats: mockStats,
  );
}
