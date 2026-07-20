import '../../../../core/network/dio_api_client.dart';
import '../models/recommendation_dtos.dart';

abstract class RecommendationRemoteDataSource {
  Future<RecommendationResponseDto> getRecommendations(String diseaseName);
}

class RecommendationRemoteDataSourceImpl implements RecommendationRemoteDataSource {
  final DioApiClient _apiClient;

  const RecommendationRemoteDataSourceImpl(this._apiClient);

  @override
  Future<RecommendationResponseDto> getRecommendations(String diseaseName) async {
    String answer = '';
    try {
      final response = await _apiClient.request<Map<String, dynamic>>(
        path: '/chat',
        method: 'POST',
        data: {
          'question': 'Đưa ra lời khuyên chăm sóc cho cây sầu riêng bị bệnh $diseaseName',
          'tree_id': '60d5ec49f1b2c56b402c56b5', // Default dummy tree ID for query validation
        },
        decoder: (json) => json as Map<String, dynamic>,
      );
      answer = response.data?['answer'] as String? ?? '';
    } catch (_) {
      answer = 'Kiểm tra độ ẩm và cách ly cành bị bệnh $diseaseName ngay lập tức.';
    }

    final isHealthy = diseaseName.toLowerCase().contains('healthy') || diseaseName.toLowerCase().contains('không phát hiện');
    final riskLevel = isHealthy
        ? 'Nguy cơ thấp'
        : (diseaseName.toLowerCase().contains('rot') || diseaseName.toLowerCase().contains('phytophthora') ? 'Nguy cơ cao' : 'Nguy cơ trung bình');

    final careRecs = <CareRecommendationDto>[];
    final careSchedules = <CareScheduleDto>[];
    final materials = <MaterialDetailDto>[];

    if (isHealthy) {
      careRecs.add(const CareRecommendationDto(
        title: 'Theo dõi định kỳ',
        description: 'Vườn cây khỏe mạnh. Duy trì tưới nước đều đặn và dọn sạch cỏ dại.',
        priority: 'Thấp',
      ));
      careSchedules.add(const CareScheduleDto(
        date: 'Mỗi ngày',
        task: 'Tưới nước và kiểm tra lá',
        status: 'Chờ thực hiện',
      ));
    } else {
      careRecs.add(CareRecommendationDto(
        title: 'Phun thuốc đặc trị',
        description: 'Phun Metalaxyl hoặc Mancozeb lên lá/gốc cây bị $diseaseName.',
        priority: 'Cao',
      ));
      careSchedules.add(const CareScheduleDto(
        date: 'Hôm nay',
        task: 'Cách ly cành bệnh và tiêu hủy',
        status: 'Chờ thực hiện',
      ));
      materials.add(const MaterialDetailDto(
        name: 'Mancozeb 80WP',
        type: 'Thuốc trừ bệnh hại',
        dosage: '30g/bình 16L',
        purpose: 'Trị nấm bệnh đốm lá, thối gốc',
      ));
    }

    return RecommendationResponseDto(
      riskLevel: riskLevel,
      weather: const WeatherDto(
        temperature: 31.0,
        humidity: 80.0,
        rainfall: 2.0,
        windSpeed: 10.0,
      ),
      careRecommendations: careRecs,
      careSchedules: careSchedules,
      materialDetails: materials,
      aiNotes: [answer],
    );
  }
}
