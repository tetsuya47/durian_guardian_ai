import 'package:flutter/material.dart';

class QuickAccessRow extends StatelessWidget {
  const QuickAccessRow({super.key});

  static const List<Map<String, dynamic>> _knowledgeBase = [
    {
      'category': 'Tin tức',
      'icon': Icons.newspaper_rounded,
      'color': Color(0xFF1E8E4A),
      'bg': Color(0xFFE8F5ED),
      'articles': [
        {
          'title': 'Dự báo giá sầu riêng xuất khẩu Tây Nguyên & Miền Tây tháng 8',
          'snippet': 'Giá sầu riêng Monthong Thái giữ mức 85.000 - 95.000đ/kg; Ri6 đạt 55.000 - 65.000đ/kg nhờ thị trường Trung Quốc ăn hàng mạnh.',
          'detail': 'Theo thông tin từ các vựa thu mua lớn tại Krông Pắc (Đắk Lắk) và Cai Lậy (Tiền Giang), nhu cầu sầu riêng xuất khẩu chính ngạch sang Trung Quốc tiếp tục tăng cao. Các nhà vườn đạt chuẩn mã số vùng trồng (PUC) và không vướng dư lượng hóa chất (PHI) được thương lái thu mua với giá ưu đãi cao hơn 10-15%.',
          'time': 'Hôm nay',
          'readTime': '3 phút đọc',
        },
        {
          'title': 'Tổng cục Hải quan Trung Quốc duyệt thêm 45 mã số vùng trồng sầu riêng',
          'snippet': 'Bộ NN&PTNT thông báo thêm 45 vùng trồng sầu riêng tại Việt Nam vừa được cấp mã xuất khẩu chính ngạch.',
          'detail': 'Việc bổ sung thêm 45 mã số vùng trồng và 18 cơ sở đóng gói giúp mở rộng dư địa xuất khẩu sầu riêng tươi cho Việt Nam trong niên vụ 2026. Bà con nông dân được khuyến cáo ghi chép nhật ký nông trại đầy đủ trên ứng dụng Vie-farm AI để phục vụ kiểm tra định kỳ.',
          'time': '2 ngày trước',
          'readTime': '4 phút đọc',
        },
        {
          'title': 'Khuyến cáo kiểm soát chặt dư lượng thuốc BVTV mùa thu hoạch',
          'snippet': 'Cục Trồng trọt yêu cầu ngừng phun các dòng thuốc hóa học độc hại trước thu hoạch tối thiểu 14-21 ngày.',
          'detail': 'Để bảo vệ uy tín thương hiệu sầu riêng Việt Nam, các cơ quan chức năng sẽ tăng cường lấy mẫu ngẫu nhiên tại vựa. Nông dân nên ưu tiên sử dụng các chế phẩm sinh học như Agrifos 400 hoặc Trichoderma giai đoạn cận thu hoạch.',
          'time': '4 ngày trước',
          'readTime': '5 phút đọc',
        },
        {
          'title': 'Hội thảo kỹ thuật trồng sầu riêng VietGAP & GlobalGAP tại Đắk Lắk',
          'snippet': 'Hơn 300 nhà vườn tham dự chương trình tập huấn kỹ thuật quản lý dịch hại tổng hợp IPM.',
          'detail': 'Chương trình nhấn mạnh việc kết hợp cảm biến IoT theo dõi pH đất và ứng dụng AI chẩn đoán bệnh sớm để giảm thiểu 35% chi phí thuốc bảo vệ thực vật hàng năm.',
          'time': '1 tuần trước',
          'readTime': '4 phút đọc',
        },
      ],
    },
    {
      'category': 'Kỹ thuật canh tác',
      'icon': Icons.eco_rounded,
      'color': Color(0xFF16A34A),
      'bg': Color(0xFFDCFCE7),
      'articles': [
        {
          'title': '[Giai đoạn Kiến thiết] Tạo tán & tỉa cành định hình sầu riêng 1-3 tuổi',
          'snippet': 'Cắt bỏ cành bơi, cành mọc sà sát đất và giữ các cành mang trái cấp 1 góc 90 độ khỏe mạnh.',
          'detail': 'Cành sầu riêng chuẩn cần mọc ngang phân bố đều 4 hướng, khoảng cách giữa các cành 30-40cm. Cắt tỉa cành vô hiệu giúp cây thông thoáng, tập trung dinh dưỡng nuôi thân chính và hạn chế nấm bệnh trú ngụ.',
          'time': 'Hôm qua',
          'readTime': '5 phút đọc',
        },
        {
          'title': '[Giai đoạn Siết nước] Kỹ thuật dỡ bạt & tạo khô hạn kích mầm hoa',
          'snippet': 'Siết nước mương 15-20 ngày kết hợp phun MKP 0-52-34 giúp mắt cua nhú sáng đồng loạt.',
          'detail': 'Khi đọt non đã già lá lụa chuyển màu xanh đậm, tiến hành rút cạn nước trong mương vườn. Phun phân bón lá MKP (0-52-34) nồng độ 1kg/200 lít nước kết hợp ức chế sinh trưởng Paclobutrazol để kích thích cây phân hóa mầm hoa.',
          'time': '3 ngày trước',
          'readTime': '6 phút đọc',
        },
        {
          'title': '[Giai đoạn Xổ nhụy] Hướng dẫn thụ phấn bổ sung ban đêm tăng đậu trái',
          'snippet': 'Dùng chổi cọ mềm quét nhẹ chùm bông từ 19h - 21h đêm giúp trái tròn đều, không bị lép hộc.',
          'detail': 'Hoa sầu riêng xở nhụy chủ yếu vào ban đêm. Việc thụ phấn bổ sung nhân tạo giúp tỷ lệ đậu trái tăng hơn 40%, hạn chế hiện tượng rụng trái non và giúp quả phát triển hộc cơm cân đối 5 hộc.',
          'time': '5 ngày trước',
          'readTime': '4 phút đọc',
        },
        {
          'title': '[Giai đoạn Nuôi cơm] Quy trình bón Kali Sunfat (K2SO4) cơm vàng ngọt đậm',
          'snippet': 'Trái từ 70-90 ngày tuổi bón K2SO4 tỉ lệ 200g/gốc giúp cơm béo dẻo, ngọt đậm, hạt lép.',
          'detail': 'Tránh sử dụng phân Kali Clorua (KCl) vì gốc Clo dễ gây cháy lá và làm cơm sầu riêng bị nhão, sượng. Sử dụng Kali Sunfat (K2SO4) kết hợp vi lượng Bo và Canxi giúp cơm lên màu vàng óng, mùi thơm đặc trưng.',
          'time': '1 tuần trước',
          'readTime': '5 phút đọc',
        },
        {
          'title': '[Sau Thu Hoạch] Kỹ thuật rửa vườn, phục hồi bộ rễ & dàn lá chân',
          'snippet': 'Phun gốc bằng Vôi bột + Ridomil Gold, tưới Humic kích rễ tơ phục hồi cây kiệt sức.',
          'detail': 'Sau khi cắt hết trái, cây sầu riêng bị suy kiệt nặng. Tiến hành rửa vườn bằng vôi bột 500g/gốc, tỉa bỏ cuống trái cũ và cuống hoa khô, sau đó tưới Acid Humic + Chế phẩm vi sinh để kích thích mầm rễ mới.',
          'time': '2 tuần trước',
          'readTime': '6 phút đọc',
        },
      ],
    },
    {
      'category': 'Sâu bệnh hại',
      'icon': Icons.bug_report_rounded,
      'color': Color(0xFFDC2626),
      'bg': Color(0xFFFEE2E2),
      'articles': [
        {
          'title': 'Đặc trị nấm Phytophthora: Xì mủ gốc, thối rễ & thối trái sầu riêng',
          'snippet': 'Vết bệnh thâm đen ướt sũng trên thân gốc. Cạo sạch vết bệnh và quét Aliette 800WG hoặc Ridomil Gold.',
          'detail': 'Nấm Phytophthora palmivora là kẻ thù số 1 của sầu riêng. Khi phát hiện vết xì mủ, dùng dao cạo sạch phần vỏ thối đến phần gỗ khỏe mạnh, quét dung dịch Ridomil Gold đậm đặc (50g/1 lít nước) hoặc tiêm trực tiếp Agrifos 400 vào thân.',
          'time': 'Hôm nay',
          'readTime': '5 phút đọc',
        },
        {
          'title': 'Phòng trừ Rầy phấn trắng chích hút đọt non sầu riêng',
          'snippet': 'Rầy phấn chích hút làm đọt bị co quắp, rụng lá hàng loạt. Phun Confidor 200SL hoặc Movento 150OD.',
          'detail': 'Rầy phấn xuất hiện ngay khi cơi đọt vừa nhú lá cờ (lá vừa nhú 2-3cm). Cần phun thuốc trừ rầy 2 lần cách nhau 5-7 ngày để cắt đợt sinh sản. Kết hợp bổ sung phân bón lá Amino Acid giúp đọt vươn mập mạp.',
          'time': '2 ngày trước',
          'readTime': '4 phút đọc',
        },
        {
          'title': 'Nhận biết & tiêu diệt Rệp sáp xơ gây thâm vắt cuống trái',
          'snippet': 'Lớp phấn trắng bám chặt vào gai trái và cuống bông. Phun Movento 150OD kết hợp dầu khoáng SK Enspray.',
          'detail': 'Rệp sáp tiết ra chất dịch ngọt thu hút nấm bồ hóng làm đen gai sầu riêng, giảm giá trị thương phẩm. Dùng vòi nước áp lực cao xịt rửa bớt rệp sáp, sau đó phun Movento kết hợp bám dính dầu khoáng.',
          'time': '4 ngày trước',
          'readTime': '4 phút đọc',
        },
        {
          'title': 'Khống chế Bọ trĩ & Nhện đỏ gây cháy lá sầu riêng mùa nắng',
          'snippet': 'Lá sầu riêng bị bạc màu gỉ sắt, rụng lá chân. Phun Comda 250EC hoặc Yamida 100EC luân phiên.',
          'detail': 'Nhện đỏ và bọ trĩ phát triển cực nhanh trong mùa nắng hạn. Cần luôn giữ ẩm mương vườn và phun luân phiên các hoạt chất trừ nhện (Abamectin, Imidacloprid) để tránh hiện tượng kháng thuốc.',
          'time': '1 tuần trước',
          'readTime': '5 phút đọc',
        },
        {
          'title': 'Phòng chống Sâu đục quả sầu riêng giai đoạn trái trứng gà',
          'snippet': 'Sâu đục sâu vào vỏ trái thải phân đùn ra ngoài. Phun Preventon 5SC định kỳ bảo vệ trái.',
          'detail': 'Bướm đẻ trứng vào khe gai sầu riêng. Khi sâu non nở ra sẽ đục ngay vào bên trong trái làm trái thối rụng. Tiến hành tỉa bớt trái chùm chạm nhau và phun Preventon 5SC khi trái đạt 30 ngày tuổi.',
          'time': '1 tuần trước',
          'readTime': '4 phút đọc',
        },
      ],
    },
    {
      'category': 'Phòng trừ sinh học',
      'icon': Icons.verified_user_rounded,
      'color': Color(0xFF059669),
      'bg': Color(0xFFD1FAE5),
      'articles': [
        {
          'title': 'Ứng dụng nấm đối kháng Trichoderma harzianum tiêu diệt nấm thối rễ',
          'snippet': 'Tưới Trichoderma 1kg/400 lít nước định kỳ 2-3 tháng/lần tiêu diệt Phytophthora & Pythium trong đất.',
          'detail': 'Chủng nấm Trichoderma tiết ra enzym chitinase phân hủy vách tế bào nấm hại. Nên kết hợp ủ Trichoderma với phân chuồng hoai mục để tăng hiệu quả vi sinh có lợi.',
          'time': 'Hôm qua',
          'readTime': '5 phút đọc',
        },
        {
          'title': 'Sử dụng Nấm xanh Metarhizium diệt rệp sáp & ve sầu sinh học',
          'snippet': 'Nấm ký sinh Metarhizium anisopliae diệt ấu trùng ve sầu và rệp sáp rễ dưới đất an toàn tuyệt đối.',
          'detail': 'Tưới nấm xanh vào đầu mùa mưa khi đất đủ ẩm. Bào tử nấm xanh xâm nhập vào cơ thể ấu trùng sâu/rệp dưới gốc cây, làm chúng bị bệnh và chết tự nhiên mà không gây nhiễm độc nguồn nước.',
          'time': '3 ngày trước',
          'readTime': '4 phút đọc',
        },
        {
          'title': 'Kích kháng tự nhiên bằng Potassium Phosphonate (Agrifos 400)',
          'snippet': 'Lưu dẫn 2 chiều giúp cây sầu riêng tự tiết Phytoalexin tiêu diệt nấm bệnh từ bên trong.',
          'detail': 'Agrifos 400 không phải là thuốc hóa học độc hại mà là dạng muối Phosphonate kích thích hệ miễn dịch tự nhiên của cây sầu riêng. Có thể dùng tưới gốc, phun lá hoặc tiêm trực tiếp vào thân cây.',
          'time': '5 ngày trước',
          'readTime': '5 phút đọc',
        },
        {
          'title': 'Kỹ thuật rải vôi bột (CaCO3) nâng pH đất & khử trùng toàn vườn',
          'snippet': 'Rải 500g - 1kg vôi bột/gốc trước mùa mưa giúp nâng pH đất từ < 5.0 lên > 6.0.',
          'detail': 'Đất chua (pH < 5.5) là môi trường phát triển lý tưởng của nấm Phytophthora. Rải vôi bột cân bằng pH giúp rễ sầu riêng hấp thụ phân bón tốt hơn 50% và ức chế nấm hại sinh trưởng.',
          'time': '1 tuần trước',
          'readTime': '4 phút đọc',
        },
      ],
    },
    {
      'category': 'Thời tiết nông vụ',
      'icon': Icons.wb_sunny_rounded,
      'color': Color(0xFFD97706),
      'bg': Color(0xFFFEF3C7),
      'articles': [
        {
          'title': 'Cảnh báo mưa dầm diện rộng Tây Nguyên & Miền Tây',
          'snippet': 'Độ ẩm không khí > 90% kéo dài 4-6 ngày tới, rủi ro bùng phát nấm thối trái sầu riêng rất cao.',
          'detail': 'Dữ liệu thời tiết Vie-farm cảnh báo mưa dầm kéo dài. Bà con cần xẻ mương thoát nước ngay, không để nước đọng quanh mô đất sầu riêng. Phun phòng nấm thối trái bằng Antracol 700WP hoặc Agrifos 400 ráo sương.',
          'time': 'Hôm nay',
          'readTime': '3 phút đọc',
        },
        {
          'title': 'Khắc phục hiện tượng sương muối & rét ngọt giai đoạn nhú mầm hoa',
          'snippet': 'Nhiệt độ ban đêm xuống < 20°C gây nghẹn bông, rụng mầm hoa sầu riêng.',
          'detail': 'Khi có sương muối hoặc rét đậm, tưới xả sương trên tán lá vào sáng sớm trước khi mặt trời mọc. Phun bổ sung phân bón lá chứa Bo, Canxi và Humic để tăng sức chịu đựng cho mầm hoa.',
          'time': '2 ngày trước',
          'readTime': '4 phút đọc',
        },
        {
          'title': 'Thời điểm phun thuốc BVTV né mưa rào: Khuyên dùng từ Vie-farm AI',
          'snippet': 'Nên phun thuốc từ 6h00 - 8h30 sáng khi nắng vừa lên, ráo sương trên mặt lá.',
          'detail': 'Tránh phun thuốc vào chiều tối vì độ ẩm ban đêm cao dễ làm đọng thuốc gây cháy mép lá lụa, đồng thời dễ bị mưa rào chiều tối rửa trôi lãng phí 100% chi phí thuốc.',
          'time': '4 ngày trước',
          'readTime': '3 phút đọc',
        },
        {
          'title': 'Ứng phó hạn mặn Miền Tây: Kỹ thuật đắp bờ ngăn mặn & trữ nước ngọt',
          'snippet': 'Độ mặn mương vườn > 1.0‰ tuyệt đối không tưới sầu riêng kẻo gây cháy lá rụng rễ.',
          'detail': 'Sầu riêng là loại cây đặc biệt nhạy cảm với độ mặn. Khi độ mặn nước mương bạt > 0.5‰, đóng chặt cống đập, sử dụng túi trữ nước ngọt và phủ gốc bằng rơm rạ hoặc cỏ khô để hạn chế thoát hơi nước.',
          'time': '1 tuần trước',
          'readTime': '5 phút đọc',
        },
      ],
    },
  ];

  void _showKnowledgeModal(BuildContext context, [String? initialCategory]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          String selectedTab = initialCategory ?? 'Tất cả';

          List<Map<String, dynamic>> displayedCategories;
          if (selectedTab == 'Tất cả') {
            displayedCategories = _knowledgeBase;
          } else {
            displayedCategories = _knowledgeBase.where((c) {
              final cat = c['category'] as String;
              return cat == selectedTab || selectedTab.contains(cat) || cat.contains(selectedTab);
            }).toList();
          }

          final categoriesList = ['Tất cả', 'Tin tức', 'Kỹ thuật canh tác', 'Sâu bệnh hại', 'Phòng trừ sinh học', 'Thời tiết nông vụ'];

          return Container(
            height: MediaQuery.of(context).size.height * 0.86,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle Bar
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Modal Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.explore_rounded, color: Color(0xFF16A34A), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Khám Phá Cẩm Nang Nông Nghiệp',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Kiến thức & giải pháp kỹ thuật chuẩn Vie-farm AI',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Category Horizontal Filter Tabs
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categoriesList.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final tab = categoriesList[index];
                      final isSelected = selectedTab == tab;

                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedTab = tab;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            tab,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const Divider(height: 20),

                // Articles List
                Expanded(
                  child: ListView.separated(
                    itemCount: displayedCategories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 20),
                    itemBuilder: (context, catIndex) {
                      final cat = displayedCategories[catIndex];
                      final articles = cat['articles'] as List<Map<String, String>>;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: cat['bg'] as Color,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 18),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cat['category'] as String,
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(${articles.length} bài viết)',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...articles.map((art) => GestureDetector(
                                onTap: () => _showArticleDetailDialog(context, art),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color.fromRGBO(0, 0, 0, 0.03),
                                        blurRadius: 10,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        art['title']!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        art['snippet']!,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Color(0xFF475569),
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF94A3B8)),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${art['time']} • ${art['readTime']}',
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                              ),
                                            ],
                                          ),
                                          const Row(
                                            children: [
                                              Text(
                                                'Đọc chi tiết',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF16A34A),
                                                ),
                                              ),
                                              Icon(Icons.chevron_right, size: 14, color: Color(0xFF16A34A)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showArticleDetailDialog(BuildContext context, Map<String, String> article) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          article['title']!,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    '${article['time']} • ${article['readTime']}',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const Divider(height: 20),
              Text(
                article['detail'] ?? article['snippet']!,
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155), height: 1.45),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'title': 'Tin tức',
        'rawCategory': 'Tin tức',
        'icon': Icons.newspaper_rounded,
        'color': const Color(0xFF16A34A),
        'bg': const Color(0xFFDCFCE7),
      },
      {
        'title': 'Kỹ thuật\ncanh tác',
        'rawCategory': 'Kỹ thuật canh tác',
        'icon': Icons.eco_rounded,
        'color': const Color(0xFF16A34A),
        'bg': const Color(0xFFDCFCE7),
      },
      {
        'title': 'Sâu bệnh\nhại',
        'rawCategory': 'Sâu bệnh hại',
        'icon': Icons.bug_report_rounded,
        'color': const Color(0xFFDC2626),
        'bg': const Color(0xFFFEE2E2),
      },
      {
        'title': 'Phòng trừ\nsinh học',
        'rawCategory': 'Phòng trừ sinh học',
        'icon': Icons.verified_user_rounded,
        'color': const Color(0xFF059669),
        'bg': const Color(0xFFD1FAE5),
      },
      {
        'title': 'Thời tiết\nnông vụ',
        'rawCategory': 'Thời tiết nông vụ',
        'icon': Icons.wb_sunny_rounded,
        'color': const Color(0xFFD97706),
        'bg': const Color(0xFFFEF3C7),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Khám phá nhanh',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () => _showKnowledgeModal(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'Xem tất cả',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFF16A34A),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.map((item) {
            final title = item['title'] as String;
            final rawCat = item['rawCategory'] as String;
            final icon = item['icon'] as IconData;
            final color = item['color'] as Color;
            final bg = item['bg'] as Color;

            return Expanded(
              child: GestureDetector(
                onTap: () => _showKnowledgeModal(context, rawCat),
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: color,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
