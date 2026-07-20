import '../../../../core/network/result.dart';
import '../entities/dashboard_entities.dart';

class DashboardFullData {
  final FarmStatusEntity farmStatus;
  final List<StatItemEntity> statistics;
  final List<InspectionItemEntity> recentInspections;
  final List<AlertEntity> alerts;
  final String userName;

  const DashboardFullData({
    required this.farmStatus,
    required this.statistics,
    required this.recentInspections,
    required this.alerts,
    required this.userName,
  });
}

abstract class DashboardRepository {
  Future<Result<DashboardFullData>> getDashboardData();
}
