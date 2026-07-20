import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_api_client.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../data/repository_impl/dashboard_repository_impl.dart';

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>((ref) {
  final apiClient = ref.watch(dioApiClientProvider);
  return DashboardRemoteDataSourceImpl(apiClient);
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final remoteDataSource = ref.watch(dashboardRemoteDataSourceProvider);
  return DashboardRepositoryImpl(remoteDataSource);
});

final dashboardDataProvider = FutureProvider<DashboardFullData>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  final result = await repo.getDashboardData();
  return result.when(
    success: (data) => data,
    failure: (msg, err) => throw Exception(msg),
    loading: () => throw Exception('Đang tải...'),
    empty: () => throw Exception('Không có dữ liệu'),
  );
});
