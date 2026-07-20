import '../models/history_dtos.dart';

abstract class HistoryLocalDataSource {
  Future<void> saveHistoryLogs(HistoryResponseDto history);
  Future<HistoryResponseDto?> getCachedHistoryLogs();
}

class HistoryLocalDataSourceImpl implements HistoryLocalDataSource {
  const HistoryLocalDataSourceImpl();

  @override
  Future<void> saveHistoryLogs(HistoryResponseDto history) => throw UnimplementedError();

  @override
  Future<HistoryResponseDto?> getCachedHistoryLogs() => throw UnimplementedError();
}
