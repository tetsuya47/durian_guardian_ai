import '../../../../core/network/result.dart';
import '../../../../core/errors/failure.dart' as err;
import '../../../../core/network/environment_config.dart';
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

      final totalTrees = dashboard.kpi.totalTrees;
      final healthyTrees = dashboard.kpi.healthyTrees;
      final healthPercent = totalTrees > 0 ? ((healthyTrees / totalTrees) * 100).toStringAsFixed(1) : "0.0";

      final statistics = [
        StatItemEntity(
          label: 'TỔNG SỐ CÂY',
          value: '$totalTrees cây',
          icon: 'park',
          color: 'primary',
          subtitle: '+0 Cây tháng này',
        ),
        StatItemEntity(
          label: 'DIỆN TÍCH CANH TÁC',
          value: '${dashboard.kpi.areaHectare} ha',
          icon: 'landscape',
          color: 'success',
          subtitle: '${dashboard.kpi.totalFarms} Trang trại · ${dashboard.kpi.totalZones} Khu vực',
        ),
        StatItemEntity(
          label: 'SỨC KHỎE VƯỜN CÂY',
          value: '$healthPercent%',
          icon: 'favorite',
          color: 'success',
          subtitle: 'Tỷ lệ cây khỏe mạnh',
        ),
        StatItemEntity(
          label: 'CẢNH BÁO NGUY CƠ CAO',
          value: '${dashboard.kpi.highRiskTrees} cây',
          icon: 'warning',
          color: 'warning',
          subtitle: 'Cây nguy cơ cao (>80%)',
          isPositiveTrend: false,
        ),
        StatItemEntity(
          label: 'ƯỚC TÍNH SẢN LƯỢNG',
          value: '${dashboard.kpi.estimatedYield} Tấn',
          icon: 'trending_up',
          color: 'primary',
          subtitle: 'Ước tính vụ 2026',
          isPositiveTrend: true,
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
          imageUrl: _resolveUrl(e.imageUrl),
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

  String _resolveUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return '';
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }
    var cleaned = relativePath.replaceAll(r'\', '/');
    if (cleaned.contains('/uploads/')) {
      cleaned = cleaned.substring(cleaned.indexOf('/uploads/') + '/uploads/'.length);
    } else if (cleaned.startsWith('uploads/')) {
      cleaned = cleaned.substring('uploads/'.length);
    }
    cleaned = cleaned.replaceFirst(RegExp(r'^\.\/'), '').replaceFirst(RegExp(r'^\/'), '');
    return '${EnvironmentConfig.uploadsBaseUrl}/$cleaned';
  }
}
