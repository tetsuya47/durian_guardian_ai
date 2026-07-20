import 'dart:math';
import '../models/history_models.dart';

class MockHistoryDatasource {
  MockHistoryDatasource._();

  static List<MockHistoryLog> generate30Logs() {
    final rand = Random(42); // Seed để dữ liệu cố định, không nhảy lung tung
    final List<MockHistoryLog> logs = [];

    final diseaseNames = [
      'Bệnh Thán Thư (Colletotrichum)',
      'Xì Mủ Thân & Cháy Lá (Phytophthora)',
      'Đốm Mắt Cua (Phyllosticta)',
      'Khỏe mạnh'
    ];

    final treeNames = [
      'Ri6 Gốc 01', 'Ri6 Gốc 02', 'Monthong Gốc 03', 'Ri6 Gốc 04', 'Monthong Gốc 05',
      'Ri6 Gốc 06', 'Ri6 Gốc 07', 'Monthong Gốc 08', 'Monthong Gốc 09', 'Ri6 Gốc 10'
    ];

    final imageUrls = [
      'https://images.unsplash.com/photo-1598902108854-10e335adac99?auto=format&fit=crop&w=150&q=80',
      'https://images.unsplash.com/photo-1597423498219-04418210827d?auto=format&fit=crop&w=150&q=80',
      'https://images.unsplash.com/photo-1502082553048-f009c37129b9?auto=format&fit=crop&w=150&q=80',
    ];

    final listRecommendations = [
      ['Cắt tỉa cành bệnh tiêu hủy.', 'Tránh tưới nước đêm.', 'Phun Coc 85 ngừa nấm.'],
      ['Phết thuốc gốc đồng vết xì mủ.', 'Tạo rãnh thoát nước gốc.', 'Bón Trichoderma đối kháng.'],
      ['Phun thuốc phòng ngừa nấm.', 'Duy trì chăm sóc định kỳ.'],
      ['Cây khỏe mạnh, tiếp tục theo dõi chăm sóc định kỳ hàng tuần.']
    ];

    final inspectors = ['Nguyễn Văn Nông', 'Trần Thị Vườn', 'Lê Văn Rẫy'];

    // Tạo 30 bản ghi
    for (int i = 1; i <= 30; i++) {
      // Phân chia ngày: i <= 5 là hôm nay, i <= 12 là hôm qua, còn lại là tuần trước/tháng trước
      String date;
      if (i <= 5) {
        date = '13/07/2026'; // Hôm nay
      } else if (i <= 12) {
        date = '12/07/2026'; // Hôm qua
      } else {
        // Tuần trước từ 01/07 tới 10/07
        final day = (i % 10) + 1;
        date = '${day.toString().padLeft(2, '0')}/07/2026';
      }

      final treeIndex = rand.nextInt(treeNames.length);
      final disIndex = rand.nextInt(diseaseNames.length);
      final isHealthy = disIndex == 3;

      // Độ tin cậy: Khỏe mạnh thường cao, bệnh dao động từ 75% đến 99%
      final confidence = isHealthy ? 0.95 + rand.nextDouble() * 0.04 : 0.75 + rand.nextDouble() * 0.23;

      // Mức độ
      String severity;
      if (isHealthy) {
        severity = 'Khỏe mạnh';
      } else {
        final sevRand = rand.nextInt(3);
        severity = sevRand == 0 ? 'Nhẹ' : (sevRand == 1 ? 'Trung bình' : 'Nặng');
      }

      logs.add(
        MockHistoryLog(
          id: 'DGA-${i.toString().padLeft(3, '0')}',
          treeName: treeNames[treeIndex],
          imageUrl: imageUrls[i % imageUrls.length],
          diseaseName: diseaseNames[disIndex],
          confidence: confidence,
          severity: severity,
          date: date,
          time: '${(8 + rand.nextInt(10)).toString().padLeft(2, '0')}:${rand.nextInt(60).toString().padLeft(2, '0')}',
          inspectorName: inspectors[rand.nextInt(inspectors.length)],
          weather: MockHistoryWeather(
            temperature: 28.0 + rand.nextDouble() * 6.0,
            humidity: 70.0 + rand.nextDouble() * 25.0,
          ),
          recommendations: listRecommendations[disIndex],
        ),
      );
    }

    return logs;
  }
}
