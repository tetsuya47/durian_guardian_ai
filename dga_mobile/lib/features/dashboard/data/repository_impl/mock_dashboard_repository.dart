import '../../../../core/network/result.dart';
import '../../domain/entities/dashboard_entities.dart';
import '../../domain/repositories/dashboard_repository.dart';

class MockDashboardRepository implements DashboardRepository {
  const MockDashboardRepository();

  @override
  Future<Result<DashboardFullData>> getDashboardData() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return const Success(DashboardFullData(
      farmStatus: FarmStatusEntity(
        healthyTrees: 150,
        diseasedTrees: 12,
        highRiskTrees: 5,
        totalTrees: 167,
      ),
      statistics: [
        StatItemEntity(label: 'Tổng số cây', value: '167', icon: 'qr_code_scanner', color: 'primary'),
        StatItemEntity(label: 'Cây khỏe mạnh', value: '150', icon: 'check_circle_outline', color: 'success'),
        StatItemEntity(label: 'Cây nhiễm bệnh', value: '12', icon: 'error_outline', color: 'error'),
        StatItemEntity(label: 'Nguy cơ cao', value: '5', icon: 'warning_amber_outlined', color: 'warning'),
      ],
      recentInspections: [],
      alerts: [],
      userName: 'Mock User',
    ));
  }
}
