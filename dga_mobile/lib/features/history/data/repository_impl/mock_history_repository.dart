import '../../../../core/network/result.dart';
import '../../domain/entities/history_entities.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/mock_history_datasource.dart';
import '../models/history_dtos.dart';

class MockHistoryRepository implements HistoryRepository {
  const MockHistoryRepository();

  @override
  Future<Result<List<HistoryLogEntity>>> getHistoryLogs() async {
    // Giả lập độ trễ mạng trơn tru 1.2 giây
    await Future.delayed(const Duration(milliseconds: 1200));
    try {
      final mockList = MockHistoryDatasource.generate30Logs();
      final dtos = mockList.map((mock) => HistoryLogDto(
        id: mock.id,
        treeName: mock.treeName,
        imageUrl: mock.imageUrl,
        diseaseName: mock.diseaseName,
        confidence: mock.confidence,
        severity: mock.severity,
        date: mock.date,
        time: mock.time,
        inspectorName: mock.inspectorName,
        weather: HistoryWeatherDto(
          temperature: mock.weather.temperature,
          humidity: mock.weather.humidity,
        ),
        recommendations: mock.recommendations,
        riskScore: mock.severity == 'Nặng' ? 90.0 : (mock.severity == 'Trung bình' ? 55.0 : 20.0),
      )).toList();
      return Success(dtos.map((dto) => dto.toDomain()).toList());
    } catch (e) {
      return Failure('Không thể tải lịch sử chẩn đoán', e);
    }
  }
}
