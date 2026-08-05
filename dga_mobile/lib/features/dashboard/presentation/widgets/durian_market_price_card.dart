import 'package:flutter/material.dart';

class DurianMarketPriceCard extends StatefulWidget {
  const DurianMarketPriceCard({super.key});

  @override
  State<DurianMarketPriceCard> createState() => _DurianMarketPriceCardState();
}

class _DurianMarketPriceCardState extends State<DurianMarketPriceCard> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _priceData = const [
    {
      'name': 'Ri6',
      'isStar': true,
      'price': '95.000đ/kg',
      'change': '↑ +3.000đ (3,2%)',
      'aiInsight': '🤖 AI: Giá có xu hướng tăng trong tuần này.',
    },
    {
      'name': 'Monthong',
      'isStar': false,
      'price': '125.000đ/kg',
      'change': '↑ +2.000đ (1,6%)',
      'aiInsight': '🤖 AI: Nhu cầu cao, khả năng tăng nhẹ.',
    },
    {
      'name': 'Musang King',
      'isStar': false,
      'price': '180.000đ/kg',
      'change': '↑ +5.000đ (2,9%)',
      'aiInsight': '🤖 AI: Xu hướng tăng mạnh, nên bán sớm.',
    },
    {
      'name': 'Black Thorn',
      'isStar': false,
      'price': '320.000đ/kg',
      'change': '↑ +10.000đ (3,1%)',
      'aiInsight': '🤖 AI: Hàng VIP xuất khẩu khan hiếm.',
    },
    {
      'name': 'Chuồng Bò',
      'isStar': false,
      'price': '75.000đ/kg',
      'change': 'Ổn định',
      'aiInsight': '🤖 AI: Nguồn cung nội địa dồi dào.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text('📈', style: TextStyle(fontSize: 18)),
                SizedBox(width: 6),
                Text(
                  'Giá sầu riêng hôm nay',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    fontFamily: 'Be Vietnam Pro',
                  ),
                ),
              ],
            ),
            Row(
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
          ],
        ),

        const SizedBox(height: 14),

        // Carousel List View
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.85),
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: _priceData.length,
            itemBuilder: (context, index) {
              final item = _priceData[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildPriceCard(item),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _priceData.length,
            (index) => Container(
              width: _currentIndex == index ? 16 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: _currentIndex == index ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceCard(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.06),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item['name'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          fontFamily: 'Be Vietnam Pro',
                        ),
                      ),
                      if (item['isStar'] == true) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['price'] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                      fontFamily: 'Be Vietnam Pro',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['change'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF16A34A),
                      fontFamily: 'Be Vietnam Pro',
                    ),
                  ),
                ],
              ),
              // Durian Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/durian_icon.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),

          // AI Insight Line Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              item['aiInsight'] as String,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
