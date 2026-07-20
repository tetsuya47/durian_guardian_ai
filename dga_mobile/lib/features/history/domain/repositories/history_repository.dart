import '../../../../core/network/result.dart';
import '../entities/history_entities.dart';

abstract class HistoryRepository {
  Future<Result<List<HistoryLogEntity>>> getHistoryLogs();
}
