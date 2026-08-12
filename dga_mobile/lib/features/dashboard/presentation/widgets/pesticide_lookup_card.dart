import 'package:flutter/material.dart';

class PesticideLookupCard extends StatelessWidget {
  const PesticideLookupCard({super.key});

  static const List<Map<String, dynamic>> _pesticideData = [
    {
      'name': 'Ridomil Gold 68WG',
      'tag': 'Khuyên dùng',
      'isGreenTag': true,
      'type': 'granule',
      'imageAsset': 'assets/images/pesticide_ridomil_gold.png',
      'target': 'Đặc trị: Thán thư, sương mai, thối rễ',
      'active': 'Hoạt chất: Metalaxyl-M 4% + Mancozeb 64%',
      'dosage': 'Liều lượng: 40-50g / bình 25 lít nước',
      'usage': 'Phun đều lá hoặc quét trực tiếp lên vết xì mủ sau khi cạo sạch.',
      'manufacturer': 'Syngenta Thụy Sĩ',
      'phi': 'Thời gian cách ly (PHI): 7 ngày',
    },
    {
      'name': 'Aliette 800WG',
      'tag': 'Khuyên dùng',
      'isGreenTag': true,
      'type': 'granule',
      'imageAsset': 'assets/images/pesticide_aliette.png',
      'target': 'Đặc trị: Nấm Phytophthora & Xì mủ gốc',
      'active': 'Hoạt chất: Fosetyl-Aluminium 800g/kg',
      'dosage': 'Liều lượng: 20g / bình 16 lít nước',
      'usage': 'Lưu dẫn 2 chiều (lá xuống rễ & rễ lên lá). Tưới gốc 2-3 lít/cây.',
      'manufacturer': 'Bayer Đức',
      'phi': 'Thời gian cách ly (PHI): 14 ngày',
    },
    {
      'name': 'Confidor 200SL',
      'tag': 'Phòng trừ',
      'isGreenTag': false,
      'type': 'insecticide',
      'imageAsset': 'assets/images/pesticide_confidor.png',
      'target': 'Đặc trị: Rầy phấn trắng, rệp sáp, bọ trĩ',
      'active': 'Hoạt chất: Imidacloprid 200g/L',
      'dosage': 'Liều lượng: 10ml / 20 lít nước',
      'usage': 'Phun khi đọt non vừa nhú 2-3cm để bảo vệ đọt sầu riêng.',
      'manufacturer': 'Bayer CropScience',
      'phi': 'Thời gian cách ly (PHI): 7 ngày',
    },
    {
      'name': 'Agrifos 400',
      'tag': 'Sinh học',
      'isGreenTag': true,
      'type': 'bio',
      'imageAsset': 'assets/images/pesticide_agrifos_400.png',
      'target': 'Phòng nấm & kích kháng rễ tơ',
      'active': 'Hoạt chất: Potassium Phosphonate 400g/L',
      'dosage': 'Liều lượng: 500ml / 200 lít nước',
      'usage': 'Tưới gốc kết hợp tiêm thân cây bị bệnh Phytophthora nặng.',
      'manufacturer': 'Úc',
      'phi': 'Thời gian cách ly (PHI): 3 ngày',
    },
    {
      'name': 'Anvil 5SC',
      'tag': 'Phòng trừ',
      'isGreenTag': false,
      'type': 'fungicide',
      'imageAsset': 'assets/images/pesticide_anvil_5sc.png',
      'target': 'Đặc trị: Nấm hồng, đốm lá, rỉ sắt',
      'active': 'Hoạt chất: Hexaconazole 50g/L',
      'dosage': 'Liều lượng: 40ml / 20 lít nước',
      'usage': 'Phun ướt đều tán lá khi xuất hiện vết đốm màu gỉ sắt.',
      'manufacturer': 'Syngenta',
      'phi': 'Thời gian cách ly (PHI): 14 ngày',
    },
    {
      'name': 'Nativo 750WG',
      'tag': 'Khuyên dùng',
      'isGreenTag': true,
      'type': 'granule',
      'imageAsset': 'assets/images/pesticide_nativo_750wg.png',
      'target': 'Đặc trị: Thán thư bông & Đốm mắt cua',
      'active': 'Hoạt chất: Tebuconazole 500g/kg + Trifloxystrobin 250g/kg',
      'dosage': 'Liều lượng: 10g / bình 25 lít nước',
      'usage': 'Phun bảo vệ bông sầu riêng trước khi xổ nhụy 7 ngày.',
      'manufacturer': 'Bayer Đức',
      'phi': 'Thời gian cách ly (PHI): 14 ngày',
    },
    {
      'name': 'Amistar Top 325SC',
      'tag': 'Khuyên dùng',
      'isGreenTag': true,
      'type': 'fungicide',
      'imageAsset': 'assets/images/pesticide_amistar_top.png',
      'target': 'Phòng khô bông, rụng trái non & đốm lá',
      'active': 'Hoạt chất: Azoxystrobin 200g/L + Difenoconazole 125g/L',
      'dosage': 'Liều lượng: 15ml / bình 25 lít nước',
      'usage': 'Phun ướt đều chùm bông và mặt dưới tán lá.',
      'manufacturer': 'Syngenta Thụy Sĩ',
      'phi': 'Thời gian cách ly (PHI): 10 ngày',
    },
    {
      'name': 'Movento 150OD',
      'tag': 'Phòng trừ',
      'isGreenTag': false,
      'type': 'insecticide',
      'imageAsset': 'assets/images/pesticide_confidor.png',
      'target': 'Đặc trị: Rệp sáp rễ & Bọ trĩ kháng thuốc',
      'active': 'Hoạt chất: Spirotetramat 150g/L',
      'dosage': 'Liều lượng: 20ml / 25 lít nước',
      'usage': 'Thuốc lưu dẫn 2 chiều mạnh mẽ, phun khi rệp mới xuất hiện.',
      'manufacturer': 'Bayer Đức',
      'phi': 'Thời gian cách ly (PHI): 7 ngày',
    },
    {
      'name': 'Trico-DHCT (Trichoderma)',
      'tag': 'Sinh học',
      'isGreenTag': true,
      'type': 'bio',
      'imageAsset': 'assets/images/pesticide_agrifos_400.png',
      'target': 'Nấm đối kháng ủ phân & Ngừa thối rễ',
      'active': 'Chủng bào tử: Trichoderma harzianum 10^9 CFU/g',
      'dosage': 'Liều lượng: 1kg / 400 lít nước tưới gốc',
      'usage': 'Tưới gốc định kỳ 2-3 tháng/lần để bảo vệ vi sinh vật có lợi.',
      'manufacturer': 'Đại học Cần Thơ',
      'phi': 'Thời gian cách ly (PHI): 0 ngày (Sinh học an toàn)',
    },
    {
      'name': 'Antracol 700WP',
      'tag': 'Khuyên dùng',
      'isGreenTag': true,
      'type': 'granule',
      'imageAsset': 'assets/images/pesticide_aliette.png',
      'target': 'Áo giáp kẽm bảo vệ đọt non & Trừ thán thư',
      'active': 'Hoạt chất: Propineb 700g/kg + Kẽm tinh khiết (Zn++)',
      'dosage': 'Liều lượng: 50g / bình 25 lít nước',
      'usage': 'Phun khi đọt vừa nhú lá lụa giúp xanh dày lá và phòng bệnh.',
      'manufacturer': 'Bayer Đức',
      'phi': 'Thời gian cách ly (PHI): 7 ngày',
    },
    {
      'name': 'Comda 250EC',
      'tag': 'Phòng trừ',
      'isGreenTag': false,
      'type': 'insecticide',
      'imageAsset': 'assets/images/pesticide_anvil_5sc.png',
      'target': 'Đặc trị: Nhện đỏ & Rầy nhảy gây cháy lá',
      'active': 'Hoạt chất: Abamectin 50g/L + Petroleum Oil 200g/L',
      'dosage': 'Liều lượng: 25ml / bình 25 lít nước',
      'usage': 'Phun kỹ mặt dưới lá sầu riêng mùa nắng nóng.',
      'manufacturer': 'VFC Việt Nam',
      'phi': 'Thời gian cách ly (PHI): 7 ngày',
    },
    {
      'name': 'Tilt Super 300EC',
      'tag': 'Phòng trừ',
      'isGreenTag': false,
      'type': 'fungicide',
      'imageAsset': 'assets/images/pesticide_ridomil_gold.png',
      'target': 'Đặc trị: Rỉ sắt, nấm hồng & Vàng lá',
      'active': 'Hoạt chất: Propiconazole 150g/L + Difenoconazole 150g/L',
      'dosage': 'Liều lượng: 10ml / bình 16 lít nước',
      'usage': 'Phun khi phát hiện đốm rỉ sắt đầu tiên trên tán lá.',
      'manufacturer': 'Syngenta',
      'phi': 'Thời gian cách ly (PHI): 14 ngày',
    },
    {
      'name': 'Preventon 5SC',
      'tag': 'Phòng trừ',
      'isGreenTag': false,
      'type': 'insecticide',
      'imageAsset': 'assets/images/pesticide_confidor.png',
      'target': 'Đặc trị: Sâu đục quả & Sâu ăn bông',
      'active': 'Hoạt chất: Chlorantraniliprole 50g/L',
      'dosage': 'Liều lượng: 15ml / 25 lít nước',
      'usage': 'Phun vào chùm trái non khi trái sầu riêng bằng quả trứng gà.',
      'manufacturer': 'FMC Mỹ',
      'phi': 'Thời gian cách ly (PHI): 5 ngày',
    },
    {
      'name': 'Matyl 90WP',
      'tag': 'Khuyên dùng',
      'isGreenTag': true,
      'type': 'granule',
      'imageAsset': 'assets/images/pesticide_nativo_750wg.png',
      'target': 'Đặc trị: Thối mút trái & Xì mủ thân',
      'active': 'Hoạt chất: Metalaxyl 90% w/w',
      'dosage': 'Liều lượng: 30g / 20 lít nước',
      'usage': 'Phun phòng trước mùa mưa hoặc quét gốc vết thối.',
      'manufacturer': 'Ấn Độ',
      'phi': 'Thời gian cách ly (PHI): 7 ngày',
    },
    {
      'name': 'Yamida 100EC',
      'tag': 'Phòng trừ',
      'isGreenTag': false,
      'type': 'insecticide',
      'imageAsset': 'assets/images/pesticide_amistar_top.png',
      'target': 'Đặc trị: Bọ trĩ hút mật bông & Nhện vàng',
      'active': 'Hoạt chất: Imidacloprid 100g/L',
      'dosage': 'Liều lượng: 20ml / 25 lít nước',
      'usage': 'Phun vào sáng sớm hoặc chiều mát giai đoạn nhú mầm hoa.',
      'manufacturer': 'Nông Dược HAI',
      'phi': 'Thời gian cách ly (PHI): 7 ngày',
    },
    {
      'name': 'Metarhizium Bio (Nấm Xanh)',
      'tag': 'Sinh học',
      'isGreenTag': true,
      'type': 'bio',
      'imageAsset': 'assets/images/pesticide_agrifos_400.png',
      'target': 'Diệt rệp sáp gốc & Ve sầu sinh học',
      'active': 'Chủng nấm ký sinh: Metarhizium anisopliae 10^8 spores/g',
      'dosage': 'Liều lượng: 500g / 200 lít nước tưới gốc',
      'usage': 'Tưới ẩm gốc cây vào đầu mùa mưa để diệt ấu trùng dưới đất.',
      'manufacturer': 'Viện Lúa ĐBSCL',
      'phi': 'Thời gian cách ly (PHI): 0 ngày',
    },
  ];

  Widget _buildPesticideTypeIcon(String type, {double size = 44, String? imageAsset}) {
    if (imageAsset != null && imageAsset.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * 0.25),
          border: Border.all(color: Colors.grey.shade200, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.22),
          child: Image.asset(
            imageAsset,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackIcon(type, size),
          ),
        ),
      );
    }
    return _buildFallbackIcon(type, size);
  }

  Widget _buildFallbackIcon(String type, double size) {
    Color bg;
    Color border;
    Color iconColor;
    IconData iconData;

    switch (type) {
      case 'fungicide':
        bg = const Color(0xFFEFF6FF);
        border = const Color(0xFFBFDBFE);
        iconColor = const Color(0xFF2563EB);
        iconData = Icons.healing_rounded;
        break;
      case 'insecticide':
        bg = const Color(0xFFFFF7ED);
        border = const Color(0xFFFED7AA);
        iconColor = const Color(0xFFEA580C);
        iconData = Icons.sanitizer_rounded;
        break;
      case 'bio':
        bg = const Color(0xFFF0FDF4);
        border = const Color(0xFFBBF7D0);
        iconColor = const Color(0xFF16A34A);
        iconData = Icons.eco_rounded;
        break;
      case 'granule':
        bg = const Color(0xFFFAF5FF);
        border = const Color(0xFFE9D5FF);
        iconColor = const Color(0xFF9333EA);
        iconData = Icons.inventory_2_rounded;
        break;
      case 'liquid':
      default:
        bg = const Color(0xFFF0FDFA);
        border = const Color(0xFF99F6E4);
        iconColor = const Color(0xFF0D9488);
        iconData = Icons.science_rounded;
        break;
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Icon(
        iconData,
        size: size * 0.54,
        color: iconColor,
      ),
    );
  }

  void _showPesticideCatalogSheet(BuildContext context, [Map<String, dynamic>? initialItem]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.84,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            const SizedBox(height: 16),

            // Header Title
            Row(
              children: [
                _buildPesticideTypeIcon('liquid', size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Danh Mục Thuốc BVTV Đề Xuất',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_pesticideData.length} loại',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Khuyên dùng chuẩn Vie-farm AI cho sầu riêng',
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
            const Divider(height: 24),

            // List of Pesticides
            Expanded(
              child: ListView.separated(
                itemCount: _pesticideData.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _pesticideData[index];
                  final isGreenTag = item['isGreenTag'] as bool;
                  final type = (item['type'] as String?) ?? 'liquid';
                  final isSelected = initialItem != null && initialItem['name'] == item['name'];

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildPesticideTypeIcon(type, size: 44, imageAsset: item['imageAsset'] as String?),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['name'] as String,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isGreenTag ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item['tag'] as String,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: isGreenTag ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['target'] as String,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item['active'] as String,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item['dosage'] as String,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item['usage'] as String,
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row with Interactive "Xem tất cả"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildPesticideTypeIcon('liquid', size: 28),
                const SizedBox(width: 8),
                const Text(
                  'Thuốc bảo vệ thực vật đề xuất',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    fontFamily: 'Be Vietnam Pro',
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => _showPesticideCatalogSheet(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'Xem tất cả',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Be Vietnam Pro',
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: Color(0xFF16A34A)),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Product Cards list (First 4 items on Dashboard)
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = _pesticideData[index];
            return GestureDetector(
              onTap: () => _showPesticideCatalogSheet(context, item),
              child: _buildPesticideItemCard(item),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPesticideItemCard(Map<String, dynamic> item) {
    final isGreenTag = item['isGreenTag'] as bool;
    final type = (item['type'] as String?) ?? 'liquid';

    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Custom Pesticide Product Image Asset Container
          _buildPesticideTypeIcon(type, size: 52, imageAsset: item['imageAsset'] as String?),
          const SizedBox(width: 12),

          // Content Middle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['name'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          fontFamily: 'Be Vietnam Pro',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isGreenTag ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item['tag'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isGreenTag ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                          fontFamily: 'Be Vietnam Pro',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item['target'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontFamily: 'Be Vietnam Pro',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['active'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontFamily: 'Be Vietnam Pro',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Right Chevron Icon
          const Icon(Icons.chevron_right, size: 20, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }
}
