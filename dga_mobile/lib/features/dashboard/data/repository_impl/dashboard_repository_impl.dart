import '../../../../core/network/result.dart';
import '../../../../core/errors/failure.dart' as err;
import '../../domain/entities/dashboard_entities.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remoteDataSource;

  const DashboardRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<DashboardFullData>> getDashboardData() async {
    try {
      final data = await _remoteDataSource.getDashboardData();
      final dashboard = data.dashboard;

      final farmStatus = FarmStatusEntity(
        healthyTrees: dashboard.kpi.healthyTrees,
        diseasedTrees: dashboard.kpi.diseasedTrees,
        highRiskTrees: dashboard.kpi.highRiskTrees,
        totalTrees: dashboard.kpi.totalTrees,
      );

      final statistics = [
        StatItemEntity(
          label: 'Tổng số cây',
          value: dashboard.kpi.totalTrees.toString(),
          icon: _mapIcon('qr_code_scanner'),
          color: _mapColor('primary'),
        ),
        StatItemEntity(
          label: 'Cây khỏe mạnh',
          value: dashboard.kpi.healthyTrees.toString(),
          icon: _mapIcon('check_circle_outline'),
          color: _mapColor('success'),
        ),
        StatItemEntity(
          label: 'Cây nhiễm bệnh',
          value: dashboard.kpi.diseasedTrees.toString(),
          icon: _mapIcon('error_outline'),
          color: _mapColor('error'),
        ),
        StatItemEntity(
          label: 'Nguy cơ cao',
          value: dashboard.kpi.highRiskTrees.toString(),
          icon: _mapIcon('warning_amber_outlined'),
          color: _mapColor('warning'),
        ),
      ];

      final recentInspections = dashboard.recentDetection.map((e) {
        String dateStr = '';
        String timeStr = '';
        try {
          final parsed = DateTime.parse(e.createdAt).toLocal();
          dateStr = '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
          timeStr = '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
        } catch (_) {
          dateStr = e.createdAt;
        }
        return InspectionItemEntity(
          id: e.treeCode,
          diseaseName: e.disease,
          confidence: e.confidence,
          date: dateStr,
          time: timeStr,
          imageUrl: '',
        );
      }).toList();

      final alerts = dashboard.alerts.map((a) => AlertEntity(
        title: a.title,
        content: a.content,
        createdAt: a.createdAt,
      )).toList();

      return Success(DashboardFullData(
        farmStatus: farmStatus,
        statistics: statistics,
        recentInspections: recentInspections,
        alerts: alerts,
        userName: data.userName,
      ));
    } catch (e) {
      return Failure(err.Failure.fromException(e).message, e);
    }
  }

  dynamic _mapIcon(String name) {
    return name;
  }

  dynamic _mapColor(String name) {
    return name;
  }
}
