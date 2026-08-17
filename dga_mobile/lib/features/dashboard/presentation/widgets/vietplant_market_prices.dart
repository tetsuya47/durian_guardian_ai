import 'package:flutter/material.dart';

class DurianVarietyPriceGroup {
  final String id;
  final String name;
  final String emoji;
  final String gaccTag;
  final Map<String, dynamic>? depItem;
  final Map<String, dynamic>? xoItem;
  final String regionalSummary;

  const DurianVarietyPriceGroup({
    required this.id,
    required this.name,
    required this.emoji,
    required this.gaccTag,
    this.depItem,
    this.xoItem,
    required this.regionalSummary,
  });
}

class VietplantMarketPrices extends StatefulWidget {
  final List<Map<String, dynamic>> prices;
  final VoidCallback? onViewAll;

  const VietplantMarketPrices({
    super.key,
    required this.prices,
    this.onViewAll,
  });

  @override
  State<VietplantMarketPrices> createState() => _VietplantMarketPricesState();
}

class _VietplantMarketPricesState extends State<VietplantMarketPrices> {
  bool _isExpanded = false;

  List<DurianVarietyPriceGroup> _buildGroups(List<Map<String, dynamic>> items) {
    final List<_VarietyConfig> configs = [
      _VarietyConfig(
        id: 'ri6',
        name: 'Sầu riêng Ri6',
        emoji: '🥑',
        tag: 'Cơm vàng hạt lép',
        defaultRegional: 'Miền Tây: 65k • Tây Nguyên: 54k',
      ),
      _VarietyConfig(
        id: 'monthong',
        name: 'Sầu riêng Monthong (Thái A)',
        emoji: '🥭',
        tag: 'Chuẩn GACC Xuất Khẩu',
        defaultRegional: 'Miền Tây: 95k • Tây Nguyên: 74k',
      ),
      _VarietyConfig(
        id: 'musang_king',
        name: 'Sầu riêng Musang King',
        emoji: '👑',
        tag: 'Hàng VIP Thượng Hạng',
        defaultRegional: 'ĐBSCL: 220k • Lâm Đồng: 200k',
      ),
      _VarietyConfig(
        id: 'black_thorn',
        name: 'Sầu riêng Black Thorn (Gai Đen)',
        emoji: '🌟',
        tag: 'Đặc sản Cơm Đỏ Cam',
        defaultRegional: 'Miền Tây: 280k • Tây Nguyên: 260k',
      ),
      _VarietyConfig(
        id: 'chuong_bo',
        name: 'Sầu riêng Chuồng Bò',
        emoji: '🪵',
        tag: 'Đặc sản Béo Ngậy Truyền Thống',
        defaultRegional: 'Tiền Giang: 58k • Tây Nguyên: 50k',
      ),
    ];

    return configs.map((config) {
      Map<String, dynamic>? dep;
      Map<String, dynamic>? xo;

      for (final item in items) {
        final name = (item['name'] ?? item['variety_name'] ?? '').toString().toLowerCase();
        final vId = (item['variety_id'] ?? item['category'] ?? '').toString().toLowerCase();
        final grade = (item['grade_type'] ?? item['grade'] ?? '').toString().toLowerCase();
        final quality = (item['quality'] ?? '').toString().toLowerCase();

        final matchesVariety = vId.contains(config.id) ||
            name.contains(config.id) ||
            (config.id == 'monthong' && (name.contains('thái') || name.contains('dona'))) ||
            (config.id == 'black_thorn' && (name.contains('gai đen') || name.contains('sáu hữu')));

        if (matchesVariety) {
          if (grade == 'dep' || quality.contains('đẹp') || quality.contains('loại 1') || quality.contains('xuất')) {
            dep = item;
          } else if (grade == 'xo_lua' || grade == 'xo' || quality.contains('xô') || quality.contains('lùa')) {
            xo = item;
          }
        }
      }

      return DurianVarietyPriceGroup(
        id: config.id,
        name: config.name,
        emoji: config.emoji,
        gaccTag: config.tag,
        depItem: dep,
        xoItem: xo,
        regionalSummary: dep?['region'] ?? xo?['region'] ?? config.defaultRegional,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allGroups = _buildGroups(widget.prices);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsible Accordion Header Card
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
                  // Icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: const Center(
                      child: Text('🍈', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Title & Price Summary
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Giá sầu riêng tại vườn',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B2E25),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ri6: 65k • Monthong: 95k • Musang: 220k',
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

                  // Expand Indicator Button
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
                          _isExpanded ? 'Đóng' : 'Bảng giá',
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

          // Unfolded List of All 5 Varieties (Only shown when expanded)
          if (_isExpanded) ...[
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allGroups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final group = allGroups[index];
                return _buildCompactVarietyCard(group);
              },
            ),
            const SizedBox(height: 8),
            // Bottom Collapse Button
            InkWell(
              onTap: () => setState(() => _isExpanded = false),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Thu gọn bảng giá ▲',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactVarietyCard(DurianVarietyPriceGroup group) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Name + Tag
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Center(
                  child: Text(
                    group.emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B2E25),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        group.gaccTag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 2 COLUMNS: HÀNG ĐẸP vs HÀNG XÔ LÙA (Zero Overflow)
          Row(
            children: [
              // CỘT 1: HÀNG ĐẸP
              Expanded(
                child: _buildCompactGradeColumn(
                  title: '🌟 HÀNG ĐẸP',
                  subtitle: 'Loại 1 xuất khẩu',
                  item: group.depItem,
                  isDep: true,
                  defaultPrice: '63.000 – 65.000',
                  defaultChange: '+3.5%',
                ),
              ),
              const SizedBox(width: 8),

              // CỘT 2: HÀNG XÔ LÙA
              Expanded(
                child: _buildCompactGradeColumn(
                  title: '🌾 HÀNG XÔ LÙA',
                  subtitle: 'Xô vườn cắt lứa',
                  item: group.xoItem,
                  isDep: false,
                  defaultPrice: '48.000 – 50.000',
                  defaultChange: 'Ổn định',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Footer: Regional Price Summary
          Row(
            children: [
              const Icon(Icons.location_on, size: 12, color: Color(0xFFE65100)),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  group.regionalSummary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactGradeColumn({
    required String title,
    required String subtitle,
    required Map<String, dynamic>? item,
    required bool isDep,
    required String defaultPrice,
    required String defaultChange,
  }) {
    final rawPrice = item?['price'] ?? item?['price_mientay'] ?? defaultPrice;
    final priceStr = rawPrice.toString().replaceAll('vnđ/kg', '').replaceAll('đ/kg', '').trim();
    final change = item?['change']?.toString() ?? defaultChange;
    final isUp = change.contains('+');
    final isDown = change.contains('-');

    final bgColor = isDep ? const Color(0xFFF1F8E9) : const Color(0xFFFFF8E1);
    final borderColor = isDep ? const Color(0xFFC5E1A5) : const Color(0xFFFFE082);
    final titleColor = isDep ? const Color(0xFF2E7D32) : const Color(0xFFE65100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
              ),
              if (isUp || isDown)
                Text(
                  change,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isDown ? Colors.red.shade900 : Colors.green.shade900,
                  ),
                )
              else
                Text(
                  'Ổn định',
                  style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600),
                ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  priceStr,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: isDep ? const Color(0xFF1B5E20) : const Color(0xFFBF360C),
                  ),
                ),
                const SizedBox(width: 2),
                const Text(
                  'đ/kg',
                  style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _VarietyConfig {
  final String id;
  final String name;
  final String emoji;
  final String tag;
  final String defaultRegional;

  const _VarietyConfig({
    required this.id,
    required this.name,
    required this.emoji,
    required this.tag,
    required this.defaultRegional,
  });
}
