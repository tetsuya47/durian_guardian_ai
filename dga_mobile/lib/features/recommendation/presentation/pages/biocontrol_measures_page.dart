import 'package:flutter/material.dart';

class BiocontrolItem {
  final String id;
  final String name;
  final String biologicalAgent;
  final String seasonId; // 'rainy', 'dry', 'flowering', 'fruiting', 'recovery'
  final String seasonName;
  final String targetPests;
  final String mechanism;
  final String preparationGuide;
  final String usageTiming;
  final String organicNotes;
  final IconData icon;

  const BiocontrolItem({
    required this.id,
    required this.name,
    required this.biologicalAgent,
    required this.seasonId,
    required this.seasonName,
    required this.targetPests,
    required this.mechanism,
    required this.preparationGuide,
    required this.usageTiming,
    required this.organicNotes,
    required this.icon,
  });
}

class BiocontrolMeasuresPage extends StatefulWidget {
  final String varietyId;
  final String varietyName;

  const BiocontrolMeasuresPage({
    super.key,
    this.varietyId = 'ri6',
    this.varietyName = 'Sầu riêng Ri6',
  });

  @override
  State<BiocontrolMeasuresPage> createState() => _BiocontrolMeasuresPageState();
}

class _BiocontrolMeasuresPageState extends State<BiocontrolMeasuresPage> {
  String _searchQuery = '';
  String _selectedSeason = 'all';

  final List<BiocontrolItem> _measures = const [
    BiocontrolItem(
      id: 'bio_1',
      name: 'Nấm Đối Kháng Trichoderma + Bacillus subtilis',
      biologicalAgent: 'Trichoderma hazianum & Bacillus subtilis',
      seasonId: 'rainy',
      seasonName: '🌧️ Mùa mưa ẩm',
      targetPests: 'Nấm Phytophthora palmivora (Nứt thân xì mủ, thối rễ), Nấm Pythium, Rhizoctonia solani (Cháy lá chết ngọn)',
      mechanism: 'Tiết enzyme Chitinase và Glucanase phá hủy vách tế bào nấm bệnh hại, cạnh tranh không gian sống và kích thích rễ tơ tiết kháng sinh tự nhiên.',
      preparationGuide: 'Pha 1kg Trichoderma + 500g Bacillus subtilis với 200 lít nước sạch (kèm 200ml mật rỉ đường ngâm 2-4 tiếng kích hoạt bào tử).',
      usageTiming: 'Tưới sục đều quanh tán gốc và quét trực tiếp lên vết thương thân cây. Định kỳ 20-30 ngày/lần trong suốt mùa mưa.',
      organicNotes: 'Tuyệt đối KHÔNG pha chung với thuốc trừ nấm hóa học hoặc vôi chưa tôi trong vòng 7 ngày.',
      icon: Icons.shield_outlined,
    ),
    BiocontrolItem(
      id: 'bio_2',
      name: 'Chế Phẩm Nấm Ký Sinh (Nấm Xanh Metarhizium + Nấm Trắng Beauveria)',
      biologicalAgent: 'Metarhizium anisopliae & Beauveria bassiana',
      seasonId: 'dry',
      seasonName: '☀️ Mùa khô & Nắng nóng',
      targetPests: 'Rầy nhảy (rầy phấn), bọ trĩ chích hút đọt non, rệp sáp, nhện đỏ, sâu đục thân',
      mechanism: 'Bào tử nấm bám vào biểu bì côn trùng, nảy mầm xuyên qua lớp cutin, sinh sôi trong máu côn trùng làm cơ thể cứng đờ và chết sau 3-5 ngày (mọc mốc xanh/trắng lây lan sang cả bầy đàn).',
      preparationGuide: 'Pha 500g Nấm xanh + 500g Nấm trắng với 200 lít nước. Bổ sung 50ml dầu khoáng hoặc chất bám dính sinh học.',
      usageTiming: 'Phun khi đọt non vừa nhú (mũi giáo). Phun vào chiều mát (sau 16h) để tránh tia UV làm chết bào tử nấm.',
      organicNotes: 'Hiệu quả diệt rầy triệt để, an toàn 100% cho bọ rùa và kiến vàng thiên địch.',
      icon: Icons.bug_report_outlined,
    ),
    BiocontrolItem(
      id: 'bio_3',
      name: 'Nuôi Thả & Bảo Vệ Kiến Vàng Trong Vườn',
      biologicalAgent: 'Oecophylla smaragdina (Kiến vàng vườn cây ăn trái)',
      seasonId: 'dry',
      seasonName: '☀️ Mùa khô & Quanh năm',
      targetPests: 'Bọ xít muỗi, rầy nhảy, sâu ăn bông, bọ cánh cứng cắn phá lá non',
      mechanism: 'Kiến vàng là loài thiên địch săn mồi hung dữ, liên tục tuần tra cành lá để săn bắt trứng sâu và ấu trùng gây hại, đồng thời tiết axit formic xua đuổi bướm đêm.',
      preparationGuide: 'Căng dây thép/dây nilon nối liền các tán cây trong vườn làm cầu di chuyển cho đàn kiến. Treo mồi thịt vụn hoặc lòng gà để dẫn dụ tổ kiến mới.',
      usageTiming: 'Duy trì tổ kiến vàng quanh năm, đặc biệt giai đoạn cơi đọt và nuôi trái non.',
      organicNotes: 'Tránh phun thuốc trừ sâu phổ rộng gốc cúc tổng hợp (Pyrethroid) làm suy giảm bầy kiến.',
      icon: Icons.emoji_nature_outlined,
    ),
    BiocontrolItem(
      id: 'bio_4',
      name: 'Vi Khuẩn Sinh Học Bacillus thuringiensis (Bt)',
      biologicalAgent: 'Bacillus thuringiensis kurstaki (Bt)',
      seasonId: 'flowering',
      seasonName: '🌸 Mùa làm bông & Xổ nhụy',
      targetPests: 'Sâu ăn bông (sâu đo, sâu xanh), sâu ăn cánh hoa, bọ xít muỗi chích hút nụ hoa',
      mechanism: 'Vi khuẩn Bt tạo ra tinh thể độc tố Protein Delta-endotoxin. Khi sâu non ăn phải, độc tố kích hoạt trong ruột sâu làm sâu tê liệt tiêu hóa và chết sau 24-48 giờ.',
      preparationGuide: 'Pha 100g chế phẩm Bt tinh khiết với 200 lít nước sạch.',
      usageTiming: 'Phun ướt đều các chùm nụ hoa trước xổ nhụy 7-10 ngày và ngay sau khi rụng hết cánh hoa.',
      organicNotes: 'Hoàn toàn vô hại đối với ong mật thụ phấn và không gây dị tật cuống hoa sầu riêng.',
      icon: Icons.local_florist_outlined,
    ),
    BiocontrolItem(
      id: 'bio_5',
      name: 'Bẫy Sinh Học Pheromone Giới Tính & Dịch Men Chua',
      biologicalAgent: 'Synthetic Sex Pheromone (Dẫn dụ con đực) + Protein thủy phân',
      seasonId: 'fruiting',
      seasonName: '🍈 Mùa nuôi trái & Thu hoạch',
      targetPests: 'Bướm sâu đục trái (Conogethes punctiferalis), ruồi đục trái',
      mechanism: 'Phát tán mùi hương pheromone giống hệt mùi con cái để dẫn dụ bướm đực bay vào bẫy dính hoặc bẫy nước tiêu diệt, triệt tiêu khả năng giao phối và đẻ trứng.',
      preparationGuide: 'Treo bẫy pheromone hình tam giác hoặc bẫy lồng tại độ cao 1.5 - 2.5m trong tán cây. Mật độ: 15-20 bẫy/ha.',
      usageTiming: 'Đặt bẫy liên tục từ khi trái non đạt 30 ngày tuổi cho đến khi thu hoạch.',
      organicNotes: 'Không tồn dư bất kỳ hóa chất nào trên gai và vỏ trái, đạt chuẩn 100% kiểm dịch xuất khẩu GACC.',
      icon: Icons.eco_outlined,
    ),
    BiocontrolItem(
      id: 'bio_6',
      name: 'Nấm Rễ Cộng Sinh Mycorrhiza & Men Vi Sinh Ủ Phân',
      biologicalAgent: 'Arbuscular Mycorrhizal Fungi (AMF) + Xạ khuẩn Streptomyces',
      seasonId: 'recovery',
      seasonName: '🍂 Mùa phục hồi sau thu hoạch',
      targetPests: 'Tuyến trùng hại rễ (Meloidogyne spp.), nấm thối rễ Fusarium, hiện tượng chai đất phèn',
      mechanism: 'Sợi nấm cộng sinh bám sâu vào tế bào rễ sầu riêng, mở rộng mạng lưới hút dinh dưỡng gấp 10 lần, tiết enzyme tiêu diệt trứng tuyến trùng và phục hồi đất phèn suy kiệt.',
      preparationGuide: 'Trộn 1kg Mycorrhiza với 500kg phân chuồng hoai mục hoặc phân trùn quế rải đều theo hình chiếu tán cây.',
      usageTiming: 'Bón lót ngay sau khi cắt tỉa cành sau thu hoạch và trước khi tưới nước xả mặn/rửa vườn.',
      organicNotes: 'Giúp bộ rễ tơ sầu riêng bung nhanh gấp đôi và tăng khả năng chịu hạn trong mùa khô kế tiếp.',
      icon: Icons.yard_outlined,
    ),
    BiocontrolItem(
      id: 'bio_7',
      name: 'Dịch Chiết Thảo Mộc Sinh Học (Neem Oil + Tỏi Ớt Gừng)',
      biologicalAgent: 'Azadirachtin (tinh dầu sầu đâu/Neem) + Capsaicin & Allicin',
      seasonId: 'dry',
      seasonName: '☀️ Mùa khô & Giai đoạn cơi đọt',
      targetPests: 'Rầy phấn, rệp sáp bông, nhện đỏ, bọ trĩ, kiến tha rệp',
      mechanism: 'Mùi cay nồng xua đuổi côn trùng đẻ trứng, hoạt chất Azadirachtin ức chế hormone lột xác Ecdysone của sâu non và rầy làm chúng không thể trưởng thành.',
      preparationGuide: 'Pha 50ml dầu Neem ép lạnh + 100ml dịch tỏi ớt gừng ngâm rượu với 100 lít nước sạch (thêm 20ml nước rửa chén sinh học làm chất nhũ hóa).',
      usageTiming: 'Phun định kỳ 7-10 ngày/lần khi cơi lá non bắt đầu hé mở.',
      organicNotes: 'Sản phẩm 100% thảo mộc hữu cơ, thời gian cách ly 0 ngày.',
      icon: Icons.spa_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredMeasures = _measures.where((m) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          m.name.toLowerCase().contains(query) ||
          m.biologicalAgent.toLowerCase().contains(query) ||
          m.targetPests.toLowerCase().contains(query) ||
          m.seasonName.toLowerCase().contains(query) ||
          m.mechanism.toLowerCase().contains(query);

      final matchesSeason = _selectedSeason == 'all' || m.seasonId == _selectedSeason;

      return matchesSearch && matchesSeason;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Phòng Trừ Sinh Học: ${widget.varietyName}',
          style: const TextStyle(
            fontSize: 17.5,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search & Seasonal Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                // Search Input Field
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: const InputDecoration(
                      hintText: 'Tìm chế phẩm vi sinh, nấm đối kháng, thiên địch...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 13.5),
                      prefixIcon: Icon(Icons.search, color: Color(0xFF2E7D32), size: 22),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Seasonal Filter Chips (Bộ lọc theo mùa vụ)
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildSeasonChip('all', 'Tất cả mùa vụ'),
                      const SizedBox(width: 8),
                      _buildSeasonChip('rainy', '🌧️ Mùa mưa (Nấm xì mủ)'),
                      const SizedBox(width: 8),
                      _buildSeasonChip('dry', '☀️ Mùa khô (Rầy, bọ trĩ)'),
                      const SizedBox(width: 8),
                      _buildSeasonChip('flowering', '🌸 Mùa làm bông & Xổ nhụy'),
                      const SizedBox(width: 8),
                      _buildSeasonChip('fruiting', '🍈 Mùa nuôi trái (Sâu đục trái)'),
                      const SizedBox(width: 8),
                      _buildSeasonChip('recovery', '🍂 Mùa phục hồi sau thu hoạch'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Measures Cards List
          Expanded(
            child: filteredMeasures.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredMeasures.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = filteredMeasures[index];
                      return _buildMeasureCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonChip(String id, String label) {
    final isSelected = _selectedSeason == id;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedSeason = id),
      selectedColor: const Color(0xFF2E7D32),
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF444444),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildMeasureCard(BiocontrolItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Name + Season Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE8F5E9),
                child: Icon(item.icon, color: const Color(0xFF2E7D32), size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B2E25),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Chủng vi sinh/Thiên địch: ${item.biologicalAgent}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Season Badge Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF00796B)),
                const SizedBox(width: 6),
                Text(
                  'Thời vụ áp dụng: ${item.seasonName}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004D40),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Target Pests & Diseases
          _buildInfoRow(
            icon: Icons.pest_control_outlined,
            iconColor: Colors.deepOrange,
            title: 'Đối tượng phòng trừ:',
            content: item.targetPests,
          ),
          const Divider(height: 20, thickness: 0.8),

          // Biological Mechanism
          _buildInfoRow(
            icon: Icons.psychology_outlined,
            iconColor: const Color(0xFF1565C0),
            title: 'Cơ chế tác động sinh học:',
            content: item.mechanism,
          ),
          const SizedBox(height: 12),

          // Preparation & Application Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC5E1A5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.science_outlined, color: Color(0xFF2E7D32), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Công thức pha & Hướng dẫn sử dụng:',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '• Cách pha: ${item.preparationGuide}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF2E2E2E), height: 1.3),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Thời điểm: ${item.usageTiming}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF1B5E20), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Organic Critical Notes
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 16, color: Color(0xFFF57C00)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Lưu ý: ${item.organicNotes}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFE65100), fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF333333),
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Không tìm thấy biện pháp sinh học phù hợp',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              'Vui lòng thử tìm kiếm với từ khóa khác',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
