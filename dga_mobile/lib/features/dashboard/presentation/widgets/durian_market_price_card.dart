import 'package:flutter/material.dart';

class DurianMarketPriceCard extends StatefulWidget {
  const DurianMarketPriceCard({super.key});

  @override
  State<DurianMarketPriceCard> createState() => _DurianMarketPriceCardState();
}

class _DurianMarketPriceCardState extends State<DurianMarketPriceCard> {
  String _selectedRegion = 'all';

  final List<Map<String, dynamic>> _priceData = [
    {
      'name': 'Sầu riêng Monthong / Dona',
      'region': 'tay_nguyen',
      'region_name': 'Tây Nguyên',
      'price_dep': '115.000 - 130.000',
      'price_xo': '85.000 - 98.000',
      'unit': 'đ/kg',
      'trend': 'up',
      'change': '+5.000đ',
      'dep_desc': 'Hàng Đẹp (Loại 1 / Xuất khẩu): 2.7 - 5.5 kg/trái, 4-5 hộc múi rậm rạp, cơm vàng hạt lép.',
      'xo_desc': 'Hàng Xô / Xô Lùa: Mua trọn vạt vườn, trái 1.8 - 4.5kg, hộc méo nhẹ hoặc lép 1 hộc.',
    },
    {
      'name': 'Sầu riêng Ri6',
      'region': 'mien_tay',
      'region_name': 'Miền Tây',
      'price_dep': '85.000 - 95.000',
      'price_xo': '60.000 - 72.000',
      'unit': 'đ/kg',
      'trend': 'up',
      'change': '+3.000đ',
      'dep_desc': 'Hàng Đẹp (Loại 1 / Xuất khẩu): 2.0 - 4.5 kg/trái, tròn đều, vỏ mỏng cơm dẻo vàng rực.',
      'xo_desc': 'Hàng Xô / Xô Lùa: Mua xô tại gốc, gồm trái lỡ 1.5 - 2.0kg và trái da heo.',
    },
    {
      'name': 'Sầu riêng Musang King',
      'region': 'tay_nguyen',
      'region_name': 'Tây Nguyên',
      'price_dep': '250.000 - 280.000',
      'price_xo': '180.000 - 210.000',
      'unit': 'đ/kg',
      'trend': 'stable',
      'change': 'Ổn định',
      'dep_desc': 'Hàng Đẹp (Chuẩn VIP): Trái hình ngôi sao 5 hộc rõ rệt, cơm mịn dẻo béo ngậy vị đắng nhẹ.',
      'xo_desc': 'Hàng Xô / Xô Lùa: Trái dạt nhỏ 1.5kg hoặc cuống ngắn, cơm mịn béo tiêu dùng nội địa.',
    },
    {
      'name': 'Sầu riêng Black Thorn (Gai Đen)',
      'region': 'dong_nam_bo',
      'region_name': 'Đông Nam Bộ',
      'price_dep': '320.000 - 360.000',
      'price_xo': '230.000 - 260.000',
      'unit': 'đ/kg',
      'trend': 'up',
      'change': '+10.000đ',
      'dep_desc': 'Hàng Đẹp (Xuất khẩu cao cấp): Trái trên 2.5kg, cơm màu đỏ cam đặc sánh, vị ngọt béo đậm.',
      'xo_desc': 'Hàng Xô / Xô Lùa: Trái mua xô vườn, từ 1.8 - 2.5kg, vỏ gai đen nhẹ.',
    },
    {
      'name': 'Sầu riêng Chuồng Bò',
      'region': 'mien_tay',
      'region_name': 'Miền Tây',
      'price_dep': '65.000 - 75.000',
      'price_xo': '48.000 - 58.000',
      'unit': 'đ/kg',
      'trend': 'stable',
      'change': 'Ổn định',
      'dep_desc': 'Hàng Đẹp: Trái tròn hộc to 2.5 - 4.0kg, cơm béo ngậy nhão dẻo truyền thống.',
      'xo_desc': 'Hàng Xô / Xô Lùa: Mua trọn vườn, trái nhỡ 1.5 - 2.5kg.',
    },
    {
      'name': 'Sầu riêng Khổ Qua Xanh',
      'region': 'mien_tay',
      'region_name': 'Miền Tây',
      'price_dep': '55.000 - 65.000',
      'price_xo': '38.000 - 45.000',
      'unit': 'đ/kg',
      'trend': 'stable',
      'change': 'Ổn định',
      'dep_desc': 'Hàng Đẹp: Trái vỏ xanh gai nhọn đều, cơm dẻo béo ngọt đậm.',
      'xo_desc': 'Hàng Xô / Xô Lùa: Hàng dạt xô vườn bán nội địa.',
    },
    {
      'name': 'Sầu riêng Chín Hóa',
      'region': 'mien_tay',
      'region_name': 'Miền Tây',
      'price_dep': '70.000 - 82.000',
      'price_xo': '52.000 - 62.000',
      'unit': 'đ/kg',
      'trend': 'up',
      'change': '+2.000đ',
      'dep_desc': 'Hàng Đẹp: Cơm vàng óng, mùi thơm nồng đặc trưng, hạt lép 70%.',
      'xo_desc': 'Hàng Xô / Xô Lùa: Trái méo hộc mua trọn cây.',
    },
    {
      'name': 'Sầu riêng Sáu Hữu',
      'region': 'mien_tay',
      'region_name': 'Miền Tây',
      'price_dep': '80.000 - 90.000',
      'price_xo': '58.000 - 68.000',
      'unit': 'đ/kg',
      'trend': 'stable',
      'change': 'Ổn định',
      'dep_desc': 'Hàng Đẹp: Trái hộc béo mịn 2.0 - 3.5kg, cơm rực rỡ ngọt dịu.',
      'xo_desc': 'Hàng Xô / Xô Lùa: Trái nhỏ mua xô vườn.',
    },
  ];

  void _showPriceDetailModal(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.78,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

            // Header
            Row(
              children: [
                const Icon(Icons.monetization_on, color: Color(0xFF2E7D32), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] as String,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      Text(
                        'Vùng thu mua: ${item['region_name']} • Cập nhật hôm nay 04/08/2026',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
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
                    // HÀNG ĐẸP BOX
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8E9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.star, color: Color(0xFF2E7D32), size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    '🌟 HÀNG ĐẸP (Loại 1 / Xuất khẩu)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B4D3E),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${item['price_dep']} ${item['unit']}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['dep_desc'] as String,
                            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800, height: 1.35),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // HÀNG XÔ LÙA BOX
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFECB3), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.shopping_basket_outlined, color: Colors.orange, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    '🧺 HÀNG XÔ / XÔ LÙA (Mua tại vườn)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF795548),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${item['price_xo']} ${item['unit']}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['xo_desc'] as String,
                            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800, height: 1.35),
                          ),
                        ],
                      ),
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
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Đóng bảng giá'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _priceData.where((item) {
      if (_selectedRegion == 'all') return true;
      return item['region'] == _selectedRegion;
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
                  Icons.trending_up,
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
                      'Bảng Giá Thị Trường Sầu Riêng',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                    Text(
                      'Giá mua tại vườn hôm nay 04/08/2026',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.fiber_manual_record, color: Colors.red, size: 8),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Region filter tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRegionChip('all', 'Tất cả vùng'),
                const SizedBox(width: 8),
                _buildRegionChip('tay_nguyen', 'Tây Nguyên'),
                const SizedBox(width: 8),
                _buildRegionChip('mien_tay', 'Miền Tây'),
                const SizedBox(width: 8),
                _buildRegionChip('dong_nam_bo', 'Đông Nam Bộ'),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Giống sầu riêng',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4D3E),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    '🌟 Hàng Đẹp',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    '🧺 Hàng Xô Lùa',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF795548),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Price items list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredData.length,
            separatorBuilder: (_, __) => const Divider(height: 14),
            itemBuilder: (context, index) {
              final item = filteredData[index];

              return InkWell(
                onTap: () => _showPriceDetailModal(context, item),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Row(
                    children: [
                      // Name & Region
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] as String,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E35),
                              ),
                            ),
                            Text(
                              item['region_name'] as String,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Price Hàng Đẹp
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${item['price_dep']}đ',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 4),

                      // Price Hàng Xô Lùa
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${item['price_xo']}đ',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),
          const Center(
            child: Text(
              '💡 Chạm vào từng dòng để xem tiêu chuẩn hộc múi & trọng lượng chi tiết',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF668878),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionChip(String key, String label) {
    final isSelected = _selectedRegion == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedRegion = key;
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
