import '../models/disease_detection_models.dart';

class MockDetectionDatasource {
  MockDetectionDatasource._();

  static const List<MockImageInfo> mockImages = [
    MockImageInfo(
      fileName: 'sau_rieng_benh_01.jpg',
      fileSize: '1.4 MB',
      dimensions: '1920x1080',
      createdDate: '13/07/2026 14:05',
      device: 'iPhone 14 Pro',
      imageUrl: 'https://images.unsplash.com/photo-1598902108854-10e335adac99?auto=format&fit=crop&w=600&q=80',
    ),
    MockImageInfo(
      fileName: 'la_sau_rieng_dom_la.jpg',
      fileSize: '950 KB',
      dimensions: '1280x720',
      createdDate: '13/07/2026 10:12',
      device: 'Samsung Galaxy S23',
      imageUrl: 'https://images.unsplash.com/photo-1597423498219-04418210827d?auto=format&fit=crop&w=600&q=80',
    ),
    MockImageInfo(
      fileName: 'la_khoe_manh_01.jpg',
      fileSize: '1.8 MB',
      dimensions: '2048x1536',
      createdDate: '12/07/2026 16:20',
      device: 'Sony Xperia 1 V',
      imageUrl: 'https://images.unsplash.com/photo-1502082553048-f009c37129b9?auto=format&fit=crop&w=600&q=80',
    ),
  ];

  static const List<MockDiseaseInfo> mockDiseases = [
    MockDiseaseInfo(
      diseaseName: 'Bệnh Thán Thư (Colletotrichum)',
      symptoms: 'Xuất hiện các đốm tròn màu nâu hoặc xám đen lan rộng trên bề mặt lá sầu riêng. Vùng vết bệnh thường bị khô, giòn và rách dần tạo lỗ thủng trên lá.',
      causes: 'Gây ra bởi nấm Colletotrichum gloeosporioides. Nấm phát triển mạnh trong điều kiện nóng ẩm, độ ẩm không khí cao và vườn rậm rạp thiếu ánh sáng.',
      impactLevel: 'Làm rụng lá hàng loạt, suy giảm khả năng quang hợp của cây, khiến cây còi cọc và giảm nghiêm trọng năng suất quả sầu riêng.',
      spreadMethod: 'Bào tử nấm lây lan qua nước mưa, nước tưới bắn lên lá hoặc nhờ gió đưa từ lá bệnh sang lá khỏe mạnh xung quanh.',
      quickRecommendations: [
        'Cắt bỏ toàn bộ cành và lá bệnh đem tiêu hủy xa khu vực vườn.',
        'Hạn chế tối đa việc tưới nước trực tiếp lên tán lá vào buổi tối.',
        'Theo dõi liên tục tình trạng cây trong 7 ngày tiếp theo.',
        'Liên hệ kỹ sư nông nghiệp hoặc cán bộ kỹ thuật nếu vết bệnh tiếp tục lan rộng ra các cây khác.',
      ],
    ),
    MockDiseaseInfo(
      diseaseName: 'Xì Mủ Thân & Cháy Lá (Phytophthora)',
      symptoms: 'Lá xuất hiện đốm bỏng nước màu nâu sẫm, sau đó cháy khô từng mảng lớn từ mép lá vào trong. Thân cây xuất hiện các vết nứt xì nhựa đỏ đục.',
      causes: 'Do nấm Phytophthora palmivora gây ra, đây là loại nấm đất cực kỳ nguy hiểm hoạt động mạnh vào mùa mưa hoặc đất ngập úng thoát nước kém.',
      impactLevel: 'Rất nghiêm trọng, có thể làm chết cây nhanh chóng nếu nấm tấn công vào cổ rễ hoặc xì mủ diện rộng trên thân chính.',
      spreadMethod: 'Lây lan cực nhanh qua nguồn nước chảy trong đất vườn, dụng cụ làm vườn chưa sát trùng và bào tử nấm bắn nhờ gió mưa.',
      quickRecommendations: [
        'Cách ly cây bệnh và rải vôi bột khử trùng gốc cây.',
        'Cắt tỉa tạo độ thông thoáng dưới gốc, khơi thông rãnh thoát nước ngay.',
        'Quét thuốc gốc đồng lên các vết loét nứt xì mủ trên thân.',
        'Dừng ngay việc bón phân đạm và các loại phân bón lá cho cây bệnh.',
      ],
    ),
    MockDiseaseInfo(
      diseaseName: 'Cây Khỏe Mạnh - Không Phát Hiện Bệnh',
      symptoms: 'Lá xanh mướt, không có đốm lạ hoặc dấu hiệu khô cháy. Bề mặt lá bóng khỏe, cành phát triển bình thường.',
      causes: 'Chế độ chăm sóc tốt, phân bón cân đối và phòng ngừa nấm bệnh định kỳ hiệu quả.',
      impactLevel: 'Tuyệt vời. Cây giữ được hiệu suất quang hợp tối đa để nuôi quả và tích lũy chất dinh dưỡng nuôi cây.',
      spreadMethod: 'Không áp dụng.',
      quickRecommendations: [
        'Tiếp tục duy trì lịch bón phân và tưới nước hiện tại.',
        'Phun thuốc phòng ngừa nấm bệnh định kỳ trước khi bắt đầu mùa mưa.',
        'Theo dõi định kỳ tình hình vườn sầu riêng hàng tuần.',
      ],
    ),
  ];
}
