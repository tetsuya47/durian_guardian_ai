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

  static const Map<String, MockDiseaseInfo> diseaseDetailsMap = {
    'Healthy': MockDiseaseInfo(
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
    'anthracnose_disease': MockDiseaseInfo(
      diseaseName: 'Bệnh Thán Thư (Colletotrichum gloeosporioides)',
      symptoms: 'Vết bệnh bắt đầu từ chóp lá hoặc mép lá với đốm màu nâu sẫm, lan rộng thành dải màu chàm, có vòng đồng tâm. Lá bị khô giòn và dễ rách thủng.',
      causes: 'Gây ra bởi nấm Colletotrichum gloeosporioides trong điều kiện thời tiết nóng ẩm, mưa nhiều hoặc sương đêm kéo dài.',
      impactLevel: 'Gây cháy xơ xác tán lá, rụng lá hàng loạt làm giảm năng suất đậu quả và suy yếu sức sống của cây sầu riêng.',
      spreadMethod: 'Lây lan nhanh qua hạt nước mưa, nước tưới phun mưa và gió phát tán bào tử nấm.',
      quickRecommendations: [
        'Cắt tỉa lá cành bệnh và đem ra khỏi vườn tiêu hủy.',
        'Phun thuốc gốc đồng hoặc Luân phiên Mancozeb, Azoxystrobin.',
        'Tạo độ thông thoáng cho tán cây và giảm mật độ tưới phun lên lá.',
      ],
    ),
    'canker_disease': MockDiseaseInfo(
      diseaseName: 'Bệnh Sẹo Thân / Loét Thân (Canker)',
      symptoms: 'Vỏ thân hoặc cành xuất hiện các đốm nứt xù xì, chảy nhựa khô màu nâu đen. Vùng vỏ bị sần sùi bóc rộp, mô gỗ bên trong bị thâm đen.',
      causes: 'Nấm và vi khuẩn xâm nhập qua vết thương cơ học, vết cắt cành hoặc rầy rệp chích hút.',
      impactLevel: 'Làm gián đoạn quá trình vận chuyển nước và dinh dưỡng, làm cành bị khô héo và có thể gãy mục.',
      spreadMethod: 'Lây qua công cụ cắt tỉa chưa sát trùng, giọt bắn nước tưới và côn trùng truyền bệnh.',
      quickRecommendations: [
        'Dùng dao cạo sạch phần vỏ sẹo bị mục xốp đến phần gỗ khỏe.',
        'Quét dung dịch Bordeaux hoặc Metalaxyl + Mancozeb đặc lên vết thương.',
        'Khử trùng dụng cụ cắt tỉa bằng cồn 70 độ sau mỗi lần sử dụng.',
      ],
    ),
    'fruit_rot': MockDiseaseInfo(
      diseaseName: 'Bệnh Thối Quả / Thối Trái Sầu Riêng',
      symptoms: 'Trên vỏ trái xuất hiện đốm thối màu sẫm loang nổ, vùng thối nứt mềm nhũn và bốc mùi hôi chua, bên trên phủ lớp nấm trắng xám.',
      causes: 'Tác nhân chủ yếu do nấm Phytophthora palmivora tấn công quả vào mùa mưa bão.',
      impactLevel: 'Gây rụng trái hàng loạt trước khi thu hoạch, thất thu nặng nề về kinh tế.',
      spreadMethod: 'Hạt nước mưa văng từ đất chứa nấm lên quả thấp hoặc bào tử theo gió tiếp xúc vỏ quả.',
      quickRecommendations: [
        'Thu gom quả thối rụng đem chôn lấp cồn rải vôi bột.',
        'Kê đỡ quả gần mặt đất không cho chạm đất ẩm.',
        'Phun ngừa thuốc sinh học hoặc Metalaxyl khi trái đạt giai đoạn nuôi quả.',
      ],
    ),
    'mealybug_infestation': MockDiseaseInfo(
      diseaseName: 'Rệp Sáp Chích Hút (Mealybug Infestation)',
      symptoms: 'Lớp bông phấn màu trắng phủ bám dày đặc ở đọt non, cuống trái và kẽ lá. Lá bị xoăn nheo, còi cọc và có mật ngọt thu hút kiến.',
      causes: 'Rệp sáp (Pseudococcidae) sinh sản nhanh trong thời tiết khô hạn hoặc xen kẽ nắng mưa.',
      impactLevel: 'Hút nhựa cây làm kiệt sức đọt non, gây rụng hoa trái non và tạo điều kiện cho nấm bồ hóng phát triển.',
      spreadMethod: 'Kiến tha rệp di chuyển giữa các cành cây và gió đưa rệp non phát tán.',
      quickRecommendations: [
        'Phun xịt xà phòng sinh học hoặc dầu khoáng petroleum oil.',
        'Tiêu diệt tổ kiến xung quanh gốc cây để cắt đứt đường lây lan.',
        'Sử dụng thuốc sinh học chứa Abamectin hoặc Spirotetramat khi mật độ rệp cao.',
      ],
    ),
    'pink_disease': MockDiseaseInfo(
      diseaseName: 'Bệnh Hồng Thân / Nấm Hồng (Erythricium salmonicolor)',
      symptoms: 'Vỏ cành xuất hiện dải váng sợi nấm màu hồng nhạt hoặc phấn hồng. Cành bệnh bị nứt vỏ, khô cháy và khô héo lá.',
      causes: 'Nấm Erythricium salmonicolor phát triển trong mùa mưa ẩm ướt, vườn cây rậm rạp che khuất ánh sáng.',
      impactLevel: 'Làm chết khô cành mang trái chính, suy giảm nghiêm trọng bộ khung tán cây sầu riêng.',
      spreadMethod: 'Bào tử nấm nảy mầm lây lan theo gió và sương đọng trên vòm lá.',
      quickRecommendations: [
        'Cắt bỏ cành khô bệnh bên dưới vị trí nấm hồng 10cm.',
        'Quét thuốc Validamycin hoặc gốc đồng Hexaconazole lên cành.',
        'Rửa tán lá và tỉa cành định kỳ tạo độ thông thoáng.',
      ],
    ),
    'sooty_mold': MockDiseaseInfo(
      diseaseName: 'Bệnh Nấm Bồ Hóng (Sooty Mold)',
      symptoms: 'Bề mặt lá và vỏ trái bị bao phủ bởi lớp màng muội đen như muội than, bám chặt nhưng không ăn sâu vào mô cây.',
      causes: 'Nấm Meliola sp. phát triển dựa trên dịch mật ngọt do rệp sáp, rầy chích hút tiết ra trên lá.',
      impactLevel: 'Che giấu bề mặt lá làm cản trở nghiêm trọng quá trình quang hợp, làm lá bị còi và quả bị lem luốc mất giá trị.',
      spreadMethod: 'Bào tử nấm phân tán trong không khí và phát triển bất cứ đâu có chất mật ngọt của rầy rệp.',
      quickRecommendations: [
        'Phun rửa sạch lớp muội đen bằng nước áp lực hoặc dầu khoáng.',
        'Diệt triệt để rầy rệp chích hút (nguyên nhân chính tiết chất mật ngọt).',
        'Phun bổ sung vi sinh antagonistic để làm sạch tán lá.',
      ],
    ),
    'stem_blight': MockDiseaseInfo(
      diseaseName: 'Bệnh Cháy Thân / Cháy Lá (Stem Blight)',
      symptoms: 'Đoạn vỏ thân đọt mầm bị thâm đen, khô tóp. Lá non bị cháy xạm màu nâu xám, gãy rủ và khô héo nhanh chóng.',
      causes: 'Do nấm Rhizoctonia solani hoặc Phytophthora tấn công vào thời điểm đọt non búp mầm đang vươn dài.',
      impactLevel: 'Làm hỏng cợt đọt non, thui đọt sầu riêng khiến cây chậm ra tán và mất nhịp phát triển.',
      spreadMethod: 'Lây lan qua giọt bắn sương đêm và bào tử rơi từ tán trên xuống đọt dưới.',
      quickRecommendations: [
        'Cắt đọt cháy hỏng và dọn dẹp lá khô dưới gốc.',
        'Phun thuốc Carbendazim hoặc Difenoconazole phòng trị đọt non.',
        'Bổ sung vi lượng Kẽm và Bo giúp lá dày chắc cứng cáp.',
      ],
    ),
    'stem_cracking_ gummosis': MockDiseaseInfo(
      diseaseName: 'Bệnh Nứt Thân Chảy Nhựa (Gummosis)',
      symptoms: 'Vỏ thân cây bị nứt dọc, ứa ra các giọt nhựa màu nâu đỏ trong suốt sau đó khô cứng lại. Vùng gỗ dưới vỏ bị thâm đen bốc mùi ỉa.',
      causes: 'Chủ yếu do nấm Phytophthora spp. kết hợp với hiện tượng dư đạm, đất ngập úng ẩm thấp.',
      impactLevel: 'Gây thối vỏ mục gỗ thân chính, cây bị vàng lá toàn bộ và suy kiệt kiệt sức nặng.',
      spreadMethod: 'Bào tử nấm mầm bệnh từ đất di chuyển theo mạch dẫn hoặc bám vào các nốt nứt.',
      quickRecommendations: [
        'Dùng cạo vỏ làm sạch vết nứt nhựa chảy.',
        'Quét dung dịch Fosetyl-Aluminium hoặc Ridomil Gold đậm đặc.',
        'Tiêm dung dịch Phytophthora đặc trị vào thân cây nếu cây lớn bị nặng.',
      ],
    ),
    'thrips_disease': MockDiseaseInfo(
      diseaseName: 'Bọ Trĩ Hại Lá Non & Hoa (Thrips Disease)',
      symptoms: 'Lá non bị biến dạng cong queo, mặt dưới lá có màu đồng hoặc quăn mép. Búp hoa và quả non bị rạn sần bám màu xám.',
      causes: 'Côn trùng bọ trĩ (Thripidae) kích thước nhỏ bám chích hút nhựa ở đọt non và chùm hoa.',
      impactLevel: 'Làm lá non không phát triển được, hoa rụng sương và trái non bị sẹo da luộc.',
      spreadMethod: 'Bọ trĩ tự bay theo luồng gió và di chuyển rất nhanh giữa các chồi lá.',
      quickRecommendations: [
        'Tưới phun sương áp lực mạnh lên đọt non để rửa trôi bọ trĩ.',
        'Luân phiên phun Imidacloprid, Spinetoram hoặc dầu neem sinh học.',
        'Treo bẫy dính màu vàng để thu gom và dự báo mật độ côn trùng.',
      ],
    ),
    'yellow_leaf': MockDiseaseInfo(
      diseaseName: 'Bệnh Vàng Lá Thối Rễ (Yellow Leaf)',
      symptoms: 'Gân lá có màu vàng ươm, phiến lá chuyển vàng từ lá già đến lá non. Tán lá thưa thớt, rễ tơ dưới gốc bị thối đen đứt đoạn.',
      causes: 'Phức hợp nấm Fusarium, Pythium và tuyến trùng tấn công làm hỏng hệ thống rễ hút nước.',
      impactLevel: 'Cây không hút được dinh dưỡng, héo rũ lá và rụng lá dần dẫn đến chết cành.',
      spreadMethod: 'Tuyến trùng và bào tử nấm di chuyển trong đất ướt ngập tràn.',
      quickRecommendations: [
        'Xới nhẹ đất quanh gốc và tưới thuốc trị nấm mốc gốc rễ.',
        'Bổ sung nấm đối kháng Trichoderma + Phân hữu cơ vi sinh.',
        'Cắt bớt tán lá khô để giảm áp lực bốc thoát hơi nước của cây.',
      ],
    ),
  };

  static MockDiseaseInfo getDiseaseInfo(String key) {
    return diseaseDetailsMap[key] ?? diseaseDetailsMap['Healthy']!;
  }

  static List<MockDiseaseInfo> get mockDiseases => diseaseDetailsMap.values.toList();
}
