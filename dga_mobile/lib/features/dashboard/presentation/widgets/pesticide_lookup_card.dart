import 'package:flutter/material.dart';

class PesticideLookupCard extends StatefulWidget {
  const PesticideLookupCard({super.key});

  @override
  State<PesticideLookupCard> createState() => _PesticideLookupCardState();
}

class _PesticideLookupCardState extends State<PesticideLookupCard> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';

  final List<Map<String, dynamic>> _pesticideData = [
    {
      'name': 'Ridomil Gold 68WG',
      'active_ingredient': 'Metalaxyl-M 40g/kg + Mancozeb 640g/kg',
      'category': 'fungicide',
      'category_name': 'Trị Nấm & Xì Mủ',
      'target': 'Đặc trị bệnh Xì mủ gốc, Thối rễ & Cháy lá sầu riêng (Phytophthora)',
      'dosage': 'Pha 500g cho phuy 200 lít nước (hoặc 50g cho bình 25L)',
      'usage': 'Quét trực tiếp vết cạo xì mủ gốc hoặc phun ướt đều 2 mặt lá khi vừa nhú cơi đọt.',
      'phi': '14 ngày trước thu hoạch',
      'safety_label': 'Nhãn Xanh Lá (GHS 5 - Độc nhẹ)',
      'company': 'Syngenta Thụy Sĩ',
    },
    {
      'name': 'Aliette 800WG',
      'active_ingredient': 'Fosetyl-Aluminium 800g/kg',
      'category': 'fungicide',
      'category_name': 'Trị Nấm & Xì Mủ',
      'target': 'Lưu dẫn 2 chiều phòng trị nấm Phytophthora & Pythium',
      'dosage': 'Pha 400g cho phuy 200 lít nước',
      'usage': 'Phun qua lá hoặc tưới gốc. Thuốc lưu dẫn 2 chiều từ lá xuống rễ và ngược lại.',
      'phi': '7 ngày trước thu hoạch',
      'safety_label': 'Nhãn Xanh Lá (An toàn cao)',
      'company': 'Bayer Đức',
    },
    {
      'name': 'Confidor 200SL / Imida 200',
      'active_ingredient': 'Imidacloprid 200g/l',
      'category': 'insecticide',
      'category_name': 'Trừ Sâu & Rầy',
      'target': 'Đặc trị Rầy nhảy, Rầy phấn trắng, Thrips (Bọ trĩ) hại cơi đọt sầu riêng',
      'dosage': 'Pha 150ml cho phuy 200 lít nước',
      'usage': 'Phun tập trung vào đọt non khi lá vừa nhú 2-3cm. Phun lúc sáng sớm.',
      'phi': '14 ngày trước thu hoạch',
      'safety_label': 'Nhãn Xanh Dương (GHS 4 - Độc trung bình)',
      'company': 'Bayer CropScience',
    },
    {
      'name': 'Nấm Đối Kháng Trichoderma Bio-Gold',
      'active_ingredient': 'Trichoderma harzianum 10^9 CFU/g + Humic',
      'category': 'biological',
      'category_name': 'Thuốc Sinh Học',
      'target': 'Ức chế nấm thối rễ, phân hủy hữu cơ nâng pH đất vườn sầu riêng',
      'dosage': 'Trộn 1kg với 200kg phân hữu cơ hoai mục hoặc pha 1kg/400L tưới gốc',
      'usage': 'Tưới gốc 2-3 lần/năm vào đầu và cuối mùa mưa. An toàn 100% không độc hại.',
      'phi': '0 ngày (Không cần cách ly)',
      'safety_label': 'Nhãn Trắng (Sinh học 100% an toàn)',
      'company': 'Viện Sinh Học Nông Nghiệp',
    },
    {
      'name': 'Rooting Max (Siêu Kích Rễ K-Humate)',
      'active_ingredient': 'Potassium Humate 85% + Fulvic Acid + Amino Acids',
      'category': 'nutrition',
      'category_name': 'Kích Rễ & Dinh Dưỡng',
      'target': 'Tái tạo rễ tơ, phục hồi cây sầu riêng sau thu hoạch hoặc sau bệnh xì mủ',
      'dosage': 'Pha 1kg cho 800 lít nước tưới quanh hình chiếu tán lá',
      'usage': 'Tưới định kỳ 15 ngày/lần giúp rễ cám ra rậm rạp, hấp thu NPK tối đa.',
      'phi': '0 ngày',
      'safety_label': 'Nhãn Xanh Lá (Phân bón sinh học)',
      'company': 'Omix Bio Tech',
    },
    {
      'name': 'Anvil 5SC',
      'active_ingredient': 'Hexaconazole 50g/l',
      'category': 'fungicide',
      'category_name': 'Trị Nấm & Xì Mủ',
      'target': 'Đặc trị Bệnh Nấm Hồng, Thán Thư & Rỉ Sắt trên cành lá sầu riêng',
      'dosage': 'Pha 300ml cho phuy 200 lít nước',
      'usage': 'Phun đều thân cành và tán lá khi xuất hiện lớp nấm màu hồng trên chạc cành.',
      'phi': '14 ngày trước thu hoạch',
      'safety_label': 'Nhãn Xanh Dương (GHS 4)',
      'company': 'Syngenta',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showPesticideDetailModal(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),

            // Header info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.science, color: Color(0xFF2E7D32), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      Text(
                        'Hãng SX: ${item['company']}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active Ingredient Box
                    _buildInfoSection(
                      title: '🧪 Hoạt chất chính:',
                      content: item['active_ingredient'] as String,
                      color: const Color(0xFFF1F8E9),
                      borderColor: const Color(0xFFC8E6C9),
                    ),
                    const SizedBox(height: 12),

                    // Target / Indication
                    _buildInfoSection(
                      title: '🎯 Đối tượng & Công dụng đặc trị:',
                      content: item['target'] as String,
                      color: const Color(0xFFFFF8E1),
                      borderColor: const Color(0xFFFFECB3),
                    ),
                    const SizedBox(height: 12),

                    // Dosage & Application Guide
                    _buildInfoSection(
                      title: '⚖️ Liều lượng & Kỹ thuật phun:',
                      content: '${item['dosage']}\n\n👉 Hướng dẫn: ${item['usage']}',
                      color: const Color(0xFFF3E5F5),
                      borderColor: const Color(0xFFE1BEE7),
                    ),
                    const SizedBox(height: 12),

                    // PHI & Safety Label
                    Row(
                      children: [
                        Expanded(
                          child: _buildBadgeCard(
                            label: '⏱️ Thời gian cách ly (PHI)',
                            value: item['phi'] as String,
                            bgColor: Colors.orange.shade50,
                            textColor: Colors.orange.shade900,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildBadgeCard(
                            label: '🛡️ Độ độc & An toàn',
                            value: item['safety_label'] as String,
                            bgColor: Colors.green.shade50,
                            textColor: Colors.green.shade900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check),
                label: const Text('Đã hiểu hướng dẫn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required String content,
    required Color color,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade900,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard({
    required String label,
    required String value,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: textColor.withAlpha(180)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredPesticides = _pesticideData.where((item) {
      final matchesCategory =
          _selectedCategory == 'all' || item['category'] == _selectedCategory;

      final query = _searchQuery.toLowerCase();
      final matchesQuery = query.isEmpty ||
          (item['name'] as String).toLowerCase().contains(query) ||
          (item['active_ingredient'] as String).toLowerCase().contains(query) ||
          (item['target'] as String).toLowerCase().contains(query);

      return matchesCategory && matchesQuery;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0EFE7), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.science_outlined,
                  color: Color(0xFF2E7D32),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tra Cứu Thuốc Bảo Vệ Thực Vật',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                    Text(
                      'Cẩm nang hoạt chất, liều lượng & thời gian cách ly',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Search Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAF8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD0E1D4)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
              decoration: const InputDecoration(
                hintText: 'Nhập tên thuốc, hoạt chất (Metalaxyl, Ridomil...)...',
                hintStyle: TextStyle(color: Color(0xFF8DA69B), fontSize: 13),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, color: Color(0xFF2E7D32), size: 20),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Category filter tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('all', 'Tất cả'),
                const SizedBox(width: 8),
                _buildCategoryChip('fungicide', 'Trị Nấm & Xì Mủ'),
                const SizedBox(width: 8),
                _buildCategoryChip('insecticide', 'Trừ Sâu & Rầy'),
                const SizedBox(width: 8),
                _buildCategoryChip('biological', 'Thuốc Sinh Học'),
                const SizedBox(width: 8),
                _buildCategoryChip('nutrition', 'Kích Rễ & Dinh Dưỡng'),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Pesticide items list
          if (filteredPesticides.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Không tìm thấy thuốc BVTV phù hợp với từ khóa.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredPesticides.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final item = filteredPesticides[index];

                return InkWell(
                  onTap: () => _showPesticideDetailModal(context, item),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.medication_liquid_outlined,
                            color: Color(0xFF2E7D32),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'] as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E35),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item['active_ingredient']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF388E3C),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['target'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String key, String label) {
    final isSelected = _selectedCategory == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedCategory = key;
          });
        }
      },
      selectedColor: const Color(0xFF2E7D32),
      backgroundColor: const Color(0xFFF1F8E9),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : const Color(0xFF2E7D32),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide.none,
    );
  }
}
