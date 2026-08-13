import 'package:flutter/material.dart';

class VietplantPesticideLookup extends StatefulWidget {
  final VoidCallback? onPesticidesTap;

  const VietplantPesticideLookup({
    super.key,
    this.onPesticidesTap,
  });

  static const List<Map<String, dynamic>> _pesticideData = [
    // 1. Đặc trị nấm & Xì mủ thân (Phytophthora, Thán thư)
    {
      'name': 'Ridomil Gold 68WG',
      'tag': 'Khuyên dùng',
      'isGreenTag': true,
      'category_id': 'fungus',
      'category_name': 'Nấm & Xì Mủ',
      'target': 'Đặc trị: Thán thư, nứt thân xì mủ, thối rễ',
      'active': 'Hoạt chất: Metalaxyl-M 4% + Mancozeb 64%',
      'dosage': 'Liều lượng: 40-50g / bình 25 lít nước',
      'usage': 'Phun đều tán lá hoặc quét trực tiếp lên vết xì mủ thân sau khi cạo sạch.',
      'manufacturer': 'Syngenta Thụy Sĩ',
      'phi': 'Thời gian cách ly (PHI): 7 ngày',
      'image_path': 'assets/images/pesticide_ridomil.png',
    },
    {
      'name': 'Aliette 800WG',
      'tag': 'Khuyên dùng',
      'isGreenTag': true,
      'category_id': 'fungus',
      'category_name': 'Nấm & Xì Mủ',
      'target': 'Đặc trị: Nấm Phytophthora & Xì mủ rễ',
      'active': 'Hoạt chất: Fosetyl-Aluminium 800g/kg',
      'dosage': 'Liều lượng: 20g / bình 16 lít nước',
      'usage': 'Lưu dẫn 2 chiều (lá xuống rễ & rễ lên lá). Tưới gốc 2-3 lít dung dịch/cây.',
      'manufacturer': 'Bayer Đức',
      'phi': 'Thời gian cách ly (PHI): 14 ngày',
      'image_path': 'assets/images/pesticide_aliette.png',
    },
    {
      'name': 'Agrifos 400',
      'tag': 'Sinh học AI',
      'isGreenTag': true,
      'category_id': 'fungus',
      'category_name': 'Nấm & Xì Mủ',
      'target': 'Tiêm thân & tưới gốc trị Phytophthora',
      'active': 'Hoạt chất: Potassium Phosphonate 400g/L',
      'dosage': 'Liều lượng: 500ml / 200 lít nước (hoặc tiêm nguyên chất 1:1)',
      'usage': 'Tưới gốc kết hợp tiêm thân cây bị bệnh Phytophthora nặng giúp kích kháng rễ tơ.',
      'manufacturer': 'Úc (Australia)',
      'phi': 'Thời gian cách ly (PHI): 3 ngày',
      'image_path': 'assets/images/pesticide_aliette.png',
    },
    {
      'name': 'Phytocide 50SC',
      'tag': 'Khuyên dùng',
      'isGreenTag': true,
      'category_id': 'fungus',
      'category_name': 'Nấm & Xì Mủ',
      'target': 'Thối trái sầu riêng & xì mủ cổ rễ',
      'active': 'Hoạt chất: Dimethomorph 500g/L',
      'dosage': 'Liều lượng: 15-20ml / 25 lít nước',
      'usage': 'Phun bảo vệ chùm trái sầu riêng giai đoạn 60-90 ngày sau đậu trái.',
      'manufacturer': 'Hợp Trí Vietnam',
      'phi': 'Thời gian cách ly (PHI): 7 ngày',
      'image_path': 'assets/images/pesticide_ridomil.png',
    },

    // 2. Trừ Sâu, Rầy Nhảy & Bọ Trĩ
    {
      'name': 'Confidor 200SL',
      'tag': 'Phòng trừ',
      'isGreenTag': false,
      'category_id': 'insect',
      'category_name': 'Sâu Rầy Bọ Trĩ',
      'target': 'Đặc trị: Rầy nhảy, rầy phấn trắng, rệp sáp',
      'active': 'Hoạt chất: Imidacloprid 200g/L',
      'dosage': 'Liều lượng: 10ml / 20 lít nước',
      'usage': 'Phun khi cơi đọt non vừa nhú 2-3cm để bảo vệ đọt sầu riêng.',
      'manufacturer': 'Bayer CropScience',
      'phi': 'Thời gian cách ly (PHI): 7 ngày',
      'image_path': 'assets/images/pesticide_confidor.png',
    },
    {
      'name': 'Movento 150OD',
      'tag': 'Cao cấp',
      'isGreenTag': true,
      'category_id': 'insect',
      'category_name': 'Sâu Rầy Bọ Trĩ',
      'target': 'Đặc trị: Bọ trĩ chích hút, rệp sáp rễ & rệp vảy',
      'active': 'Hoạt chất: Spirotetramat 150g/L',
      'dosage': 'Liều lượng: 15ml / 25 lít nước',
      'usage': 'Lưu dẫn 2 chiều qua hệ mạch rây, diệt sạch bọ trĩ ẩn nấp trong kẽ lá non.',
      'manufacturer': 'Bayer Đức',
      'phi': 'Thời gian cách ly (PHI): 14 ngày',
      'image_path': 'assets/images/pesticide_confidor.png',
    },
    {
      'name': 'Radiant 60SC',
      'tag': 'Khuyên dùng',
      'isGreenTag': true,
      'category_id': 'insect',
      'category_name': 'Sâu Rầy Bọ Trĩ',
      'target': 'Đặc trị: Sâu róm, sâu đục trái & bọ trĩ',
      'active': 'Hoạt chất: Spinetoram 60g/L',
      'dosage': 'Liều lượng: 15ml / 25 lít nước',
      'usage': 'Thuốc có nguồn gốc sinh học men vi khuẩn đất, hiệu lực kéo dài 10-14 ngày.',
      'manufacturer': 'Corteva Agriscience Mỹ',
      'phi': 'Thời gian cách ly (PHI): 3 ngày',
      'image_path': 'assets/images/pesticide_confidor.png',
    },
    {
      'name': 'Chess 50WG',
      'tag': 'Đặc trị',
      'isGreenTag': true,
      'category_id': 'insect',
      'category_name': 'Sâu Rầy Bọ Trĩ',
      'target': 'Chống lột xác & tuyệt chủng đàn rầy nhảy',
      'active': 'Hoạt chất: Pymetrozine 500g/kg',
      'dosage': 'Liều lượng: 15g / 25 lít nước',
      'usage': 'Khiến rầy bị khóa vòi hút ngừng chích hút ngay sau 1 giờ phun.',
      'manufacturer': 'Syngenta Thụy Sĩ',
      'phi': 'Thời gian cách ly (PHI): 7 ngày',
      'image_path': 'assets/images/pesticide_confidor.png',
    },

    // 3. Chế phẩm sinh học & Dầu khoáng
    {
      'name': 'Metarhizium Bio (Nấm Xanh)',
      'tag': 'Sinh học 100%',
      'isGreenTag': true,
      'category_id': 'bio',
      'category_name': 'Sinh Học & Hữu Cơ',
      'target': 'Diệt rầy nhảy, ve sầu & rệp sáp sinh học',
      'active': 'Chủng nấm ký sinh: Metarhizium anisopliae 10^8 bào tử/g',
      'dosage': 'Liều lượng: 500g / 200 lít nước',
      'usage': 'Phun ướt đều 2 mặt lá lúc chiều mát hoặc tưới quanh gốc.',
      'manufacturer': 'Viện Lúa ĐBSCL',
      'phi': 'Thời gian cách ly (PHI): 0 ngày',
      'image_path': 'assets/images/pesticide_bio.png',
    },
    {
      'name': 'Dầu Khoáng SK Enspray 99EC',
      'tag': 'An toàn thiên địch',
      'isGreenTag': true,
      'category_id': 'bio',
      'category_name': 'Sinh Học & Hữu Cơ',
      'target': 'Bao bọc ngạt thở nhện đỏ, bọ trĩ & ung trứng',
      'active': 'Hoạt chất: Petroleum Spray Oil 99%',
      'dosage': 'Liều lượng: 300ml / 200 lít nước',
      'usage': 'Phun định kỳ lúc cơi đọt vừa nhú giúp hạn chế việc dùng thuốc hóa học.',
      'manufacturer': 'Việt Thắng',
      'phi': 'Thời gian cách ly (PHI): 0 ngày',
      'image_path': 'assets/images/pesticide_bio.png',
    },
    {
      'name': 'Trichoderma + Bacillus',
      'tag': 'Men vi sinh đất',
      'isGreenTag': true,
      'category_id': 'bio',
      'category_name': 'Sinh Học & Hữu Cơ',
      'target': 'Đối kháng nấm rễ & phân giải mùn hữu cơ',
      'active': 'Nấm Trichoderma harzianum + B. subtilis (2 x 10^9 CFU/g)',
      'dosage': 'Liều lượng: 1kg / 400 lít nước tưới gốc',
      'usage': 'Tưới gốc 2-3 đợt/năm vào đầu và cuối mùa mưa để bảo vệ rễ tơ.',
      'manufacturer': 'Đại học Cần Thơ',
      'phi': 'Thời gian cách ly (PHI): 0 ngày',
      'image_path': 'assets/images/pesticide_bio.png',
    },

    // 4. Dưỡng Đọt, Bông & Vi Lượng Hữu Cơ
    {
      'name': 'Canxi - Bo Organic',
      'tag': 'Dưỡng bông trái',
      'isGreenTag': true,
      'category_id': 'nutrition',
      'category_name': 'Dưỡng Bông & Vi Lượng',
      'target': 'Chống rụng hoa, sốc nước rụng trái non & nứt gai',
      'active': 'Thành phần: Canxi 12% + Boron 25.000ppm + Amino Acid',
      'dosage': 'Liều lượng: 250ml / 200 lít nước',
      'usage': 'Phun 2 đợt: Trước xổ nhụy 5 ngày và sau khi đậu trái 10 ngày.',
      'manufacturer': 'Tây Ban Nha (Spain)',
      'phi': 'Thời gian cách ly (PHI): 0 ngày',
      'image_path': 'assets/images/pesticide_aliette.png',
    },
    {
      'name': 'Nativo 750WG',
      'tag': 'Khuyên dùng',
      'isGreenTag': true,
      'category_id': 'nutrition',
      'category_name': 'Dưỡng Bông & Vi Lượng',
      'target': 'Đặc trị: Thán thư chùm bông & Đốm mắt cua',
      'active': 'Hoạt chất: Tebuconazole 500g/kg + Trifloxystrobin 250g/kg',
      'dosage': 'Liều lượng: 10g / bình 25 lít nước',
      'usage': 'Phun bảo vệ bông sầu riêng trước khi xổ nhụy 7 ngày.',
      'manufacturer': 'Bayer Đức',
      'phi': 'Thời gian cách ly (PHI): 14 ngày',
      'image_path': 'assets/images/pesticide_ridomil.png',
    },
    {
      'name': 'Amistar Top 325SC',
      'tag': 'Cao cấp',
      'isGreenTag': true,
      'category_id': 'nutrition',
      'category_name': 'Dưỡng Bông & Vi Lượng',
      'target': 'Phòng khô bông, thối đít trái & sáng cơm',
      'active': 'Hoạt chất: Azoxystrobin 200g/L + Difenoconazole 125g/L',
      'dosage': 'Liều lượng: 15ml / bình 25 lít nước',
      'usage': 'Phun ướt đều chùm bông và mặt dưới tán lá giai đoạn nuôi trái.',
      'manufacturer': 'Syngenta Thụy Sĩ',
      'phi': 'Thời gian cách ly (PHI): 10 ngày',
      'image_path': 'assets/images/pesticide_aliette.png',
    },
  ];

  @override
  State<VietplantPesticideLookup> createState() => _VietplantPesticideLookupState();
}

class _VietplantPesticideLookupState extends State<VietplantPesticideLookup> {
  bool _isExpanded = false;
  String _searchQuery = '';
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final filteredList = VietplantPesticideLookup._pesticideData.where((p) {
      final name = (p['name'] as String).toLowerCase();
      final target = (p['target'] as String).toLowerCase();
      final active = (p['active'] as String).toLowerCase();
      final categoryId = (p['category_id'] as String);
      final q = _searchQuery.trim().toLowerCase();

      final matchesQuery = q.isEmpty || name.contains(q) || target.contains(q) || active.contains(q);
      if (!matchesQuery) return false;

      if (_selectedCategory == 'all') return true;
      return categoryId == _selectedCategory;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsible Accordion Header Card (Styled exactly like VietplantMarketPrices!)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _isExpanded ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                  width: _isExpanded ? 1.4 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Icon Container
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: const Center(
                      child: Text('🧪', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Title & Summary Text (Protected from overflow)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tra cứu thuốc BVTV sầu riêng',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B2E25),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ridomil • Aliette • Confidor • Bio... (14+ loại)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Expand Toggle Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _isExpanded ? const Color(0xFF2E7D32) : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isExpanded ? 'Đóng' : 'Tra cứu',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _isExpanded ? Colors.white : const Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 16,
                          color: _isExpanded ? Colors.white : const Color(0xFF2E7D32),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Unfolded Search Bar & Pesticides List (Only shown when expanded)
          if (_isExpanded) ...[
            const SizedBox(height: 12),

            // Live Search Field Input
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC8E6C9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Nhập tên thuốc (Ridomil, Aliette...), hoạt chất, nấm bệnh...',
                  hintStyle: const TextStyle(fontSize: 12.5, color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF2E7D32), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Category Filter Pills
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryChip('all', 'Tất cả (${VietplantPesticideLookup._pesticideData.length})'),
                  const SizedBox(width: 6),
                  _buildCategoryChip('fungus', '🛡️ Nấm & Xì mủ'),
                  const SizedBox(width: 6),
                  _buildCategoryChip('insect', '🐛 Sâu rầy bọ trĩ'),
                  const SizedBox(width: 6),
                  _buildCategoryChip('bio', '🌿 Sinh học'),
                  const SizedBox(width: 6),
                  _buildCategoryChip('nutrition', '🌸 Dưỡng bông vi lượng'),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Filtered Pesticides List
            if (filteredList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Center(
                  child: Text(
                    'Không tìm thấy loại thuốc phù hợp.',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = filteredList[index];
                  return _buildPesticideItemCard(context, item);
                },
              ),

            const SizedBox(height: 10),

            // Bottom Collapse Button
            InkWell(
              onTap: () => setState(() => _isExpanded = false),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Thu gọn danh mục thuốc',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_up, size: 16, color: Color(0xFF2E7D32)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String id, String label) {
    final isSelected = _selectedCategory == id;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFC8E6C9),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF2E7D32),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPesticideItemCard(BuildContext context, Map<String, dynamic> item) {
    final isGreen = item['isGreenTag'] as bool;
    final imagePath = item['image_path'] as String;

    return InkWell(
      onTap: () => _showPesticideDetailSheet(context, item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Authentic Product Image Bottle/Pack Container
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.medication, color: Color(0xFF2E7D32), size: 24),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Information Block (Protected from overflow)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['name'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B2E25),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isGreen ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item['tag'] as String,
                          style: TextStyle(
                            color: isGreen ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['target'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showPesticideDetailSheet(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PesticideDetailModal(item: item),
    );
  }
}

class _PesticideDetailModal extends StatelessWidget {
  final Map<String, dynamic> item;

  const _PesticideDetailModal({required this.item});

  @override
  Widget build(BuildContext context) {
    final imagePath = item['image_path'] as String;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Name, Real Image & Tag
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.medication, color: Color(0xFF2E7D32), size: 28),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B2E25),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['category_name'] as String,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item['tag'] as String,
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildDetailRow('🎯 Đối tượng phòng trừ', item['target'] as String),
          _buildDetailRow('🧪 Hoạt chất', item['active'] as String),
          _buildDetailRow('💧 Liều lượng pha', item['dosage'] as String),
          _buildDetailRow('📖 Hướng dẫn sử dụng', item['usage'] as String),
          _buildDetailRow('🏭 Hãng sản xuất', item['manufacturer'] as String),
          _buildDetailRow('⏳ Thời gian cách ly (PHI)', item['phi'] as String, isWarning: true),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Đã hiểu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isWarning ? FontWeight.bold : FontWeight.normal,
              color: isWarning ? const Color(0xFFB71C1C) : const Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}
