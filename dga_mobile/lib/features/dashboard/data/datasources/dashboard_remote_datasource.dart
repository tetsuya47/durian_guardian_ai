import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_api_client.dart';
import '../models/dashboard_dtos.dart';

class DashboardData {
  final DashboardOutDto dashboard;
  final String userName;

  const DashboardData({required this.dashboard, required this.userName});
}

class _UserOutDto {
  final String fullName;

  const _UserOutDto({required this.fullName});

  factory _UserOutDto.fromJson(Map<String, dynamic> json) {
    return _UserOutDto(
      fullName: json['full_name'] as String? ?? '',
    );
  }
}

abstract class DashboardRemoteDataSource {
  Future<DashboardData> getDashboardData();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final DioApiClient _apiClient;

  const DashboardRemoteDataSourceImpl(this._apiClient);

  @override
  Future<DashboardData> getDashboardData() async {
    final dashboardResponse = await _apiClient.request<DashboardOutDto>(
      path: ApiEndpoints.dashboard,
      method: 'GET',
      decoder: (json) => DashboardOutDto.fromJson(json as Map<String, dynamic>),
    );

    final userResponse = await _apiClient.request<_UserOutDto>(
      path: ApiEndpoints.me,
      method: 'GET',
      decoder: (json) => _UserOutDto.fromJson(json as Map<String, dynamic>),
    );

    return DashboardData(
      dashboard: dashboardResponse.data ?? const DashboardOutDto(
        kpi: KpiDataDto(totalFarms: 0, totalTrees: 0, healthyTrees: 0, diseasedTrees: 0, highRiskTrees: 0),
        recentDetection: [],
        alerts: [],
        riskTrend: [],
      ),
      userName: userResponse.data?.fullName ?? '',
    );
  }
}
