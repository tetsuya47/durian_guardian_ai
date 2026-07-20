import '../models/recommendation_models.dart';

class MockRecommendationDatasource {
  MockRecommendationDatasource._();

  static const MockWeather mockWeather = MockWeather(
    temperature: 31.5,
    humidity: 82.0,
    rainfall: 12.5,
    windSpeed: 8.4,
  );

  static const List<MockCareRecommendation> mockCareRecommendations = [
    MockCareRecommendation(
      title: 'Tưới nước vừa phải',
      description: 'Độ ẩm không khí đang cao (82%), chỉ nên tưới nhẹ vào sáng sớm để tránh ẩm ướt tán lá tạo điều kiện cho nấm Phytophthora phát triển.',
      priority: 'Trung bình',
    ),
    MockCareRecommendation(
      title: 'Bón phân Kali & Vi lượng',
      description: 'Tăng cường bón phân giàu Kali và các yếu tố vi lượng (Kẽm, Magie) để tăng sức đề kháng và độ cứng cáp cho tế bào lá sầu riêng chống chịu bệnh hại.',
      priority: 'Cao',
    ),
    MockCareRecommendation(
      title: 'Phun thuốc ngừa nấm gốc Đồng',
      description: 'Do lượng mưa đạt 12.5mm và có rủi ro cao nấm bệnh lan rộng, cần phun phòng ngừa nấm gốc đồng (như Coc 85 hoặc Norshield) đều tán lá.',
      priority: 'Khẩn cấp',
    ),
    MockCareRecommendation(
      title: 'Tỉa cành sát mặt đất',
      description: 'Loại bỏ toàn bộ các cành phụ nằm sát mặt đất dưới 50cm để tạo độ thông thoáng tốt cho gốc cây, tránh ẩm ướt tích tụ.',
      priority: 'Thấp',
    ),
    MockCareRecommendation(
      title: 'Theo dõi độ ẩm đất',
      description: 'Đặt ẩm kế kiểm tra độ ẩm đất nông nghiệp vùng gốc định kỳ 2 ngày một lần để điều chỉnh lượng nước tưới phù hợp nhất.',
      priority: 'Trung bình',
    ),
  ];

  static const List<MockCareSchedule> mockCareSchedules = [
    MockCareSchedule(
      date: '14/07/2026',
      task: 'Phun thuốc ngừa nấm gốc Đồng toàn tán lá',
      status: 'Chờ thực hiện',
    ),
    MockCareSchedule(
      date: '15/07/2026',
      task: 'Tưới nước nhẹ sáng sớm & bón phân Kali gốc',
      status: 'Chờ thực hiện',
    ),
    MockCareSchedule(
      date: '16/07/2026',
      task: 'Cắt tỉa các cành sát gốc tạo thông thoáng',
      status: 'Chờ thực hiện',
    ),
    MockCareSchedule(
      date: '18/07/2026',
      task: 'Đánh giá lại tình trạng sức khỏe lá sầu riêng',
      status: 'Chờ thực hiện',
    ),
  ];

  static const List<MockMaterialDetail> mockMaterials = [
    MockMaterialDetail(
      name: 'Norshield 86.2WG',
      type: 'Thuốc trừ nấm gốc Đồng',
      dosage: '20g cho bình 16 lít nước',
      purpose: 'Phòng ngừa hiệu quả nấm Phytophthora gây cháy lá và xì mủ thân sầu riêng.',
    ),
    MockMaterialDetail(
      name: 'Phân bón lá MKP (0-52-34)',
      type: 'Phân bón vô cơ bổ sung P, K',
      dosage: '50-80g cho bình 20 lít nước',
      purpose: 'Giúp lá già nhanh, tăng cường khả năng tự chống chịu sâu bệnh và nấm hại.',
    ),
    MockMaterialDetail(
      name: 'Chế phẩm Trichoderma',
      type: 'Nấm đối kháng sinh học',
      dosage: '1kg trộn với 100kg phân hữu cơ bón gốc',
      purpose: 'Ức chế và tiêu diệt các loại nấm gây hại rễ sầu riêng trong đất trồng.',
    ),
  ];

  static const MockRecommendationResult mockResult = MockRecommendationResult(
    riskLevel: 'Nguy cơ trung bình',
    weather: mockWeather,
    careRecommendations: mockCareRecommendations,
    careSchedules: mockCareSchedules,
    materialDetails: mockMaterials,
    aiNotes: [
      'Nên kiểm tra lại tình trạng lá sầu riêng sau 7 ngày.',
      'Nếu phát hiện bệnh loét thân xì mủ tiếp tục lan rộng, hãy lập tức liên hệ với kỹ sư để nhận phác đồ điều trị đặc hiệu.',
      'Chú ý khơi thông rãnh thoát nước xung quanh gốc cây để ngăn ngập úng đất cục bộ khi trời mưa.',
    ],
  );
}
