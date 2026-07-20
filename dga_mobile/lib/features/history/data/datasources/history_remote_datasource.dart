import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_api_client.dart';
import '../models/history_dtos.dart';

abstract class HistoryRemoteDataSource {
  Future<List<Map<String, dynamic>>> getTrees();
  Future<TreeHistoryResponseDto> getTreeHistory(String treeId);
}

class HistoryRemoteDataSourceImpl implements HistoryRemoteDataSource {
  final DioApiClient _apiClient;

  const HistoryRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<Map<String, dynamic>>> getTrees() async {
    final response = await _apiClient.request<Map<String, dynamic>>(
      path: '/trees',
      method: 'GET',
      decoder: (json) => json as Map<String, dynamic>,
    );
    final items = response.data?['items'] as List<dynamic>? ?? [];
    return items.map((item) => item as Map<String, dynamic>).toList();
  }

  @override
  Future<TreeHistoryResponseDto> getTreeHistory(String treeId) async {
    final response = await _apiClient.request<TreeHistoryResponseDto>(
      path: ApiEndpoints.historyByTree(treeId),
      method: 'GET',
      decoder: (json) => TreeHistoryResponseDto.fromJson(json as Map<String, dynamic>),
    );
    return response.data ?? TreeHistoryResponseDto(treeId: treeId, diseaseHistory: []);
  }
}
