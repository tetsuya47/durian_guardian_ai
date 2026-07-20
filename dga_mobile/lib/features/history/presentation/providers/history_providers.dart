import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_api_client.dart';
import '../../../../services/storage_service.dart';
import '../../data/datasources/history_remote_datasource.dart';
import '../../domain/repositories/history_repository.dart';
import '../../data/repository_impl/history_repository_impl.dart';
import '../../domain/entities/history_entities.dart';

final historyRemoteDataSourceProvider = Provider<HistoryRemoteDataSource>((ref) {
  final apiClient = ref.watch(dioApiClientProvider);
  return HistoryRemoteDataSourceImpl(apiClient);
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final remoteDataSource = ref.watch(historyRemoteDataSourceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return HistoryRepositoryImpl(remoteDataSource, storageService);
});

// Providers cho Tìm kiếm, Lọc và Sắp xếp
final historyQueryProvider = StateProvider<String>((ref) => '');
final historyFilterProvider = StateProvider<String>((ref) => 'Tất cả');
final historyTimeFilterProvider = StateProvider<String>((ref) => 'Tất cả');
final historySortProvider = StateProvider<String>((ref) => 'Mới nhất');

// Raw logs provider
final historyRawLogsProvider = FutureProvider<List<HistoryLogEntity>>((ref) async {
  final repo = ref.watch(historyRepositoryProvider);
  final result = await repo.getHistoryLogs();
  return result.when(
    success: (data) => data,
    failure: (msg, err) => throw Exception(msg),
    loading: () => throw Exception('Đang tải...'),
    empty: () => <HistoryLogEntity>[],
  );
});

// Computed filtered logs provider
final filteredHistoryLogsProvider = Provider<List<HistoryLogEntity>>((ref) {
  final rawLogsAsync = ref.watch(historyRawLogsProvider);
  return rawLogsAsync.when(
    data: (logs) {
      final query = ref.watch(historyQueryProvider).toLowerCase();
      final filter = ref.watch(historyFilterProvider);
      final timeFilter = ref.watch(historyTimeFilterProvider);
      final sort = ref.watch(historySortProvider);

      List<HistoryLogEntity> filtered = List.from(logs);

      // 1. Lọc theo từ khóa tìm kiếm (Tên cây)
      if (query.isNotEmpty) {
        filtered = filtered.where((log) => log.treeName.toLowerCase().contains(query)).toList();
      }

      // 2. Lọc theo bệnh lý (Tất cả / Khỏe mạnh / Có bệnh / Nguy cơ cao)
      if (filter == 'Khỏe mạnh') {
        filtered = filtered.where((log) =>
            log.diseaseName.contains('Không phát hiện') || log.diseaseName.toLowerCase().contains('khỏe mạnh')).toList();
      } else if (filter == 'Có bệnh') {
        filtered = filtered.where((log) =>
            !log.diseaseName.contains('Không phát hiện') && !log.diseaseName.toLowerCase().contains('khỏe mạnh')).toList();
      } else if (filter == 'Nguy cơ cao') {
        filtered = filtered.where((log) => log.severity == 'Nặng').toList();
      }

      // 3. Lọc theo thời gian (Hôm nay / 7 ngày / 30 ngày)
      final now = DateTime.now();
      final todayStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

      if (timeFilter == 'Hôm nay') {
        filtered = filtered.where((log) => log.date == todayStr).toList();
      } else       if (timeFilter == '7 ngày') {
        final cutoff = now.subtract(const Duration(days: 7));
        filtered = filtered.where((log) {
          final parts = log.date.split('/');
          if (parts.length != 3) return false;
          final day = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final year = int.tryParse(parts[2]);
          if (day == null || month == null || year == null) return false;
          if (month < 1 || month > 12 || day < 1 || day > 31) return false;
          final logDate = DateTime(year, month, day);
          return logDate.isAfter(cutoff);
        }).toList();
      } else if (timeFilter == '30 ngày') {
        final cutoff = now.subtract(const Duration(days: 30));
        filtered = filtered.where((log) {
          final parts = log.date.split('/');
          if (parts.length != 3) return false;
          final day = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final year = int.tryParse(parts[2]);
          if (day == null || month == null || year == null) return false;
          if (month < 1 || month > 12 || day < 1 || day > 31) return false;
          final logDate = DateTime(year, month, day);
          return logDate.isAfter(cutoff);
        }).toList();
      }

      // 4. Sắp xếp kết quả (Mới nhất / Cũ nhất / Độ tin cậy / Tên cây)
      if (sort == 'Mới nhất') {
        filtered.sort((a, b) => b.id.compareTo(a.id));
      } else if (sort == 'Cũ nhất') {
        filtered.sort((a, b) => a.id.compareTo(b.id));
      } else if (sort == 'Độ tin cậy') {
        filtered.sort((a, b) => b.confidence.compareTo(a.confidence));
      } else if (sort == 'Tên cây') {
        filtered.sort((a, b) => a.treeName.compareTo(b.treeName));
      }

      return filtered;
    },
    loading: () => [],
    error: (err, stack) => [],
  );
});
