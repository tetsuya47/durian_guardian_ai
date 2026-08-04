import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_api_client.dart';
import '../../../../core/network/network_foundation.dart';

class AgriculturalFeaturesGrid extends ConsumerStatefulWidget {
  const AgriculturalFeaturesGrid({super.key});

  @override
  ConsumerState<AgriculturalFeaturesGrid> createState() =>
      _AgriculturalFeaturesGridState();
}

class _AgriculturalFeaturesGridState
    extends ConsumerState<AgriculturalFeaturesGrid> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFeatureModal(BuildContext context, String title, Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),

            // Modal Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Modal Content
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  // 1. Kỹ thuật canh tác
  Widget _buildFarmingTechniquesContent() {
    return const CultivationTechniquesStepWidget();
  }

  // 2. Sâu bệnh hại (Detailed seasonal disease database)
  Widget _buildPestsAndDiseasesContent() {
    return const PestsAndDiseasesSeasonalWidget();
  }

  // 3. Thời tiết nông vụ (Fetch from /api/v1/weather/current)
  Widget _buildAgriculturalWeatherContent() {
    final client = ref.watch(dioApiClientProvider);

    return FutureBuilder<ResponseWrapper<dynamic>>(
      future: client.get(
        path: ApiEndpoints.weatherCurrent,
        decoder: (json) => json,
      ),
      builder: (context, snapshot) {
        Map<String, dynamic> weather = {
          'temperature': 29.5,
          'humidity': 82,
          'wind_speed': 2.8,
          'condition': 'Mây rải rác, độ ẩm cao',
          'recommendation':
              'Độ ẩm cao thuận lợi cho nấm Phytophthora phát triển. Kiểm tra kỹ mặt dưới lá và gốc sầu riêng.',
        };

        if (snapshot.hasData && snapshot.data?.data != null) {
          final res = snapshot.data!.data;
          if (res is Map) {
            weather = Map<String, dynamic>.from(res);
          }
        }

        final double temp = ((weather['temp_celsius'] ?? weather['temperature'] ?? 29.5) as num).toDouble();
        final int humidity = ((weather['humidity_percent'] ?? weather['humidity'] ?? 82) as num).toInt();
        final double windSpeed = ((weather['wind_speed_m_s'] ?? weather['wind_speed'] ?? 2.8) as num).toDouble();
        final String condition = (weather['description'] ?? weather['condition'] ?? 'Thời tiết ổn định').toString();
        final String recommendation = (weather['agricultural_advice'] ?? weather['recommendation'] ?? 'Duy trì độ ẩm hợp lý và phun phòng nấm định kỳ.').toString();
        final String location = (weather['location_name'] ?? 'Buôn Ma Thuột').toString();
        final String risk = (weather['fungal_disease_risk'] ?? 'LOW').toString();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Realtime Weather Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF1B4D3E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          'Thời tiết Nông trại Realtime ($location)',
                          style: const TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${temp.toStringAsFixed(1)}°C',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      condition,
                      style: const TextStyle(
                          fontSize: 15, color: Colors.amberAccent, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.water_drop, color: Colors.white70),
                            const SizedBox(height: 4),
                            Text(
                              'Độ ẩm: $humidity%',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Icon(Icons.air, color: Colors.white70),
                            const SizedBox(height: 4),
                            Text(
                              'Gió: $windSpeed m/s',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Icon(Icons.shield_outlined, color: Colors.amberAccent),
                            const SizedBox(height: 4),
                            Text(
                              'Nguy cơ nấm: $risk',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // AI Weather Recommendation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFECB3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.psychology, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Khuyến nghị AI Agronomist theo thời tiết',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF795548),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recommendation,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5D4037),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 4. Ưu đãi gói cước (Matching Web Portal Mockup)
  Widget _buildServicePackagesContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Top
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B4D3E), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: const Text(
                    'ƯU ĐÃI GÓI NÔNG NGHIỆP THÔNG MINH',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kích Hoạt Công Nghệ AI & IoT Cho Trang Trại',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Lựa chọn giải pháp phù hợp để giám sát đất, cảnh báo nấm bệnh & tối ưu sản lượng',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 1. GÓI PLUS (MIỄN PHÍ)
          _buildPackageCard(
            context,
            title: 'Gói Plus',
            badge: 'Gói Mặc Định',
            price: 'Miễn Phí',
            priceSub: ' vĩnh viễn',
            subtitle: 'Dành cho nông hộ trải nghiệm các tính năng cơ bản của ứng dụng.',
            buttonText: 'Đang sử dụng',
            isCurrent: true,
            isPopular: false,
            cardColor: Colors.white,
            borderColor: const Color(0xFFE0EFE7),
            features: [
              {'icon': Icons.check_circle_outline, 'color': Colors.green, 'text': 'Sử dụng các chức năng app có giới hạn lượt'},
              {'icon': Icons.warning_amber_rounded, 'color': Colors.amber.shade800, 'text': 'Giới hạn lượt quét AI (tự động hồi lượt hàng tuần)'},
              {'icon': Icons.check_circle_outline, 'color': Colors.green, 'text': 'Dự báo thời tiết & tra cứu giá thu mua tại vườn'},
              {'icon': Icons.cancel_outlined, 'color': Colors.red, 'text': 'Không được tư vấn 1-1 với Chuyên gia Nông nghiệp'},
            ],
          ),

          const SizedBox(height: 16),

          // 2. GÓI PRO (30.000đ/tháng) - PHỔ BIẾN
          _buildPackageCard(
            context,
            title: 'Gói Pro',
            badge: '★ PHỔ BIẾN ★',
            price: '30.000đ',
            priceSub: ' / tháng',
            subtitle: 'Mở khóa toàn bộ chức năng ứng dụng & Tư vấn Chuyên gia Nông nghiệp.',
            buttonText: 'Nâng cấp Gói Pro',
            isCurrent: false,
            isPopular: true,
            cardColor: const Color(0xFFF1F8E9),
            borderColor: const Color(0xFF2E7D32),
            features: [
              {'icon': Icons.check_circle, 'color': Colors.green, 'text': 'Sử dụng TẤT CẢ các chức năng trong app theo tháng'},
              {'icon': Icons.check_circle, 'color': Colors.green, 'text': 'Không giới hạn lượt quét AI & chẩn đoán sâu bệnh'},
              {'icon': Icons.check_circle, 'color': Colors.green, 'text': 'Mở khóa tư vấn 1-1 trực tiếp với Chuyên gia Nông nghiệp'},
              {'icon': Icons.cancel_outlined, 'color': Colors.red, 'text': 'Không sử dụng được các chức năng thiết bị IoT'},
            ],
          ),

          const SizedBox(height: 16),

          // 3. GÓI PREMIUM (199.000đ/tháng) - VIP PREMIUM
          _buildPackageCard(
            context,
            title: 'Gói Premium',
            badge: 'VIP Premium ★★★',
            price: '199.000đ',
            priceSub: ' / tháng',
            subtitle: 'Mở khóa toàn diện AI + IoT quản lý vườn tự động & Ưu đãi Voucher.',
            buttonText: 'Đăng ký Gói Premium',
            isCurrent: false,
            isPopular: false,
            cardColor: const Color(0xFF1B4D3E),
            borderColor: const Color(0xFF2E7D32),
            isDarkBg: true,
            features: [
              {'icon': Icons.check_circle, 'color': Colors.amber, 'text': 'Mở khóa thiết bị IoT để AI quản lý vườn & đề xuất kỹ thuật'},
              {'icon': Icons.check_circle, 'color': Colors.amber, 'text': 'Sử dụng TẤT CẢ các chức năng ứng dụng không giới hạn'},
              {'icon': Icons.support_agent, 'color': Colors.amber, 'text': 'Đầy đủ đặc quyền Tư vấn Chuyên gia Nông nghiệp 1-1'},
              {'icon': Icons.card_giftcard, 'color': Colors.amber, 'text': 'Voucher giảm giá 20% khi mua thiết bị IoT nông nghiệp'},
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(
    BuildContext context, {
    required String title,
    required String badge,
    required String price,
    required String priceSub,
    required String subtitle,
    required String buttonText,
    required bool isCurrent,
    required bool isPopular,
    required Color cardColor,
    required Color borderColor,
    bool isDarkBg = false,
    required List<Map<String, dynamic>> features,
  }) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: isPopular ? 2 : 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isPopular ? 15 : 6),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkBg ? Colors.white : const Color(0xFF1B4D3E),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPopular
                          ? const Color(0xFF2E7D32)
                          : (isDarkBg ? Colors.amber : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isPopular
                            ? Colors.white
                            : (isDarkBg ? Colors.black87 : Colors.grey.shade800),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isDarkBg ? Colors.amber : const Color(0xFF2E7D32),
                    ),
                  ),
                  Text(
                    priceSub,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkBg ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkBg ? Colors.white70 : Colors.grey.shade700,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              Column(
                children: features.map((f) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(f['icon'] as IconData,
                            size: 16, color: f['color'] as Color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f['text'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkBg ? Colors.white : Colors.grey.shade900,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isCurrent
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🎉 Đã chọn $title ($price)! Chuyển đến cổng thanh toán...'),
                              backgroundColor: const Color(0xFF2E7D32),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkBg
                        ? Colors.amber
                        : (isPopular ? const Color(0xFF2E7D32) : Colors.grey.shade300),
                    foregroundColor: isDarkBg
                        ? Colors.black87
                        : (isPopular ? Colors.white : Colors.grey.shade700),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 5. LEARN-VN & Tin tức nông nghiệp
  Widget _buildNewsAndKnowledgeContent() {
    final newsList = [
      {
        'title':
            'Xuất khẩu sầu riêng Việt Nam đạt kỷ kỷ lục mới trong 6 tháng đầu năm',
        'date': '04/08/2026',
        'source': 'Báo Nông Nghiệp Việt Nam',
        'desc':
            'Giá sầu riêng Ri6 và Dona ổn định nhờ tiêu chuẩn mã số vùng trồng xuất khẩu chính ngạch.',
      },
      {
        'title': 'Cẩm nang quản lý sâu bệnh hại sầu riêng mùa mưa',
        'date': '02/08/2026',
        'source': 'Viện Khoa học Kỹ thuật Nông Lâm nghiệp',
        'desc':
            'Hướng dẫn thoát nước vườn và sử dụng vi sinh Trichoderma phòng nấm gốc.',
      },
      {
        'title': 'Ứng dụng AI và IoT trong canh tác sầu riêng thông minh',
        'date': '30/07/2026',
        'source': 'DGA Agronomist Research',
        'desc':
            'Hệ thống cảnh báo sớm giúp nông dân giảm 40% chi phí phun thuốc trừ sâu.',
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: newsList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = newsList[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBE7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0F4C3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    item['source']!,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF33691E)),
                  ),
                  const Spacer(),
                  Text(
                    item['date']!,
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item['title']!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4D3E),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item['desc']!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
              ),
            ],
          ),
        );
      },
    );
  }

  // 6. Phòng trừ sinh học
  Widget _buildBiologicalControlContent() {
    final bioItems = [
      {
        'name': 'Nấm đối kháng Trichoderma harzianum',
        'usage': 'Trộn với phân hữu cơ rải gốc 2 lần/năm.',
        'benefit':
            'Ức chế và tiêu diệt nấm Phytophthora & Pythium gây thối rễ sầu riêng.',
      },
      {
        'name': 'Chế phẩm Phosphonate vi sinh',
        'usage': 'Phun qua lá hoặc tưới gốc khi lá già.',
        'benefit':
            'Kích thích cơ chế tự miễn dịch của cây sầu riêng chống lại bệnh xì mủ.',
      },
      {
        'name': 'Vi khuẩn Bacillus thuringiensis (BT)',
        'usage': 'Phun khi phát hiện sâu ăn lá & sâu đục quả.',
        'benefit': 'Gây bệnh cho sâu hại nhưng an toàn 100% cho người và con nít.',
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bioItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = bioItems[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFC8E6C9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.eco, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['name']!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '💡 Cách dùng: ${item['usage']}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF1B5E20)),
              ),
              const SizedBox(height: 4),
              Text(
                '🛡️ Tác dụng: ${item['benefit']}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'title': 'Kỹ thuật canh tác',
        'icon': Icons.water_drop_outlined,
        'color': const Color(0xFFE8F5E9),
        'iconColor': const Color(0xFF2E7D32),
        'onTap': () => _openFeatureModal(
              context,
              '🌱 Kỹ thuật Canh tác Sầu Riêng',
              _buildFarmingTechniquesContent(),
            ),
      },
      {
        'title': 'Sâu bệnh hại',
        'icon': Icons.search_outlined,
        'color': const Color(0xFFE8F5E9),
        'iconColor': const Color(0xFF2E7D32),
        'onTap': () => _openFeatureModal(
              context,
              '🐛 Tra cứu Sâu bệnh hại Sầu Riêng',
              _buildPestsAndDiseasesContent(),
            ),
      },
      {
        'title': 'Thời tiết nông vụ',
        'icon': Icons.wb_sunny_outlined,
        'color': const Color(0xFFE8F5E9),
        'iconColor': const Color(0xFF2E7D32),
        'onTap': () => _openFeatureModal(
              context,
              '🌦️ Thời tiết Nông nghiệp Realtime',
              _buildAgriculturalWeatherContent(),
            ),
      },
      {
        'title': 'Ưu đãi gói cước',
        'icon': Icons.cell_tower_outlined,
        'color': const Color(0xFFE8F5E9),
        'iconColor': const Color(0xFF2E7D32),
        'onTap': () => _openFeatureModal(
              context,
              '📶 Gói Dịch Vụ & Thiết Bị IoT',
              _buildServicePackagesContent(context),
            ),
      },
      {
        'title': 'Tin tức',
        'icon': Icons.menu_book_outlined,
        'color': const Color(0xFFE8F5E9),
        'iconColor': const Color(0xFF2E7D32),
        'onTap': () => _openFeatureModal(
              context,
              '📰 Kiến Thức & Tin Tức Nông Nghiệp',
              _buildNewsAndKnowledgeContent(),
            ),
      },
      {
        'title': 'Phòng trừ sinh học',
        'icon': Icons.shield_outlined,
        'color': const Color(0xFFE8F5E9),
        'iconColor': const Color(0xFF2E7D32),
        'onTap': () => _openFeatureModal(
              context,
              '🧪 Biện Pháp Phòng Trừ Sinh Học',
              _buildBiologicalControlContent(),
            ),
      },
    ];

    // Filter features based on search query
    final filteredFeatures = features.where((f) {
      if (_searchQuery.isEmpty) return true;
      return (f['title'] as String)
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar (Matching reference image)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFD0E1D4), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withAlpha(12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val.trim();
              });
            },
            decoration: const InputDecoration(
              hintText: 'Nhập từ khóa ...',
              hintStyle: TextStyle(
                color: Color(0xFF8DA69B),
                fontSize: 14,
              ),
              border: InputBorder.none,
              suffixIcon: Icon(
                Icons.search,
                color: Color(0xFF2E7D32),
                size: 24,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 6 Grid Features (3 columns x 2 rows)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredFeatures.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.82,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final item = filteredFeatures[index];
            return InkWell(
              onTap: item['onTap'] as VoidCallback,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon container (soft rounded square green tint)
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: item['color'] as Color,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFC8E6C9),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      size: 32,
                      color: item['iconColor'] as Color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title text
                  Text(
                    item['title'] as String,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E35),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class CultivationTechniquesStepWidget extends StatefulWidget {
  const CultivationTechniquesStepWidget({super.key});

  @override
  State<CultivationTechniquesStepWidget> createState() =>
      _CultivationTechniquesStepWidgetState();
}

class _CultivationTechniquesStepWidgetState
    extends State<CultivationTechniquesStepWidget> {
  Map<String, dynamic>? _selectedVariety;
  String _selectedAge = 'all'; // 'all', '1-3', '4-7', '8+'

  final List<Map<String, dynamic>> _varieties = [
    {
      'id': 'monthong',
      'name': 'Sầu riêng Monthong / Dona',
      'origin': 'Giống nhập khẩu Thái Lan',
      'icon': '🍈',
      'desc':
          'Cơm vàng óng, hạt lép 90%, vỏ mỏng. Thân cành nhạy cảm nấm Phytophthora & thối rễ mùa mưa.',
      'bg_color': Color(0xFFF1F8E9),
    },
    {
      'id': 'ri6',
      'name': 'Sầu riêng Ri6',
      'origin': 'Giống truyền thống Đồng Nai / Miền Tây',
      'icon': '🍈',
      'desc':
          'Cơm dẻo rượm, ngọt béo đậm đà. Khả năng thích nghi thổ nhưỡng Tây Nguyên & Miền Tây rất cao.',
      'bg_color': Color(0xFFFFF8E1),
    },
    {
      'id': 'musang_king',
      'name': 'Sầu riêng Musang King',
      'origin': 'Giống nhập khẩu Malaysia (VIP)',
      'icon': '👑',
      'desc':
          'Đặc sản giá trị kinh tế cao, cơm mịn dẻo đắng nhẹ. Đòi hỏi kỹ thuật siết nước & ép mầm hoa nghiêm ngặt.',
      'bg_color': Color(0xFFF3E5F5),
    },
    {
      'id': 'black_thorn',
      'name': 'Sầu riêng Black Thorn (Gai Đen)',
      'origin': 'Giống nhập khẩu Malaysia',
      'icon': '🖤',
      'desc':
          'Cơm màu đỏ cam đặc sánh, năng suất cực cao. Cần bổ sung Canxi-Bo định kỳ chống đốm gai.',
      'bg_color': Color(0xFFE0F2F1),
    },
    {
      'id': 'chuong_bo',
      'name': 'Sầu riêng Chuồng Bò / Khổ Qua',
      'origin': 'Giống bản địa lâu đời',
      'icon': '🌳',
      'desc':
          'Nhẹ công chăm sóc, khả năng kháng sâu bệnh tự nhiên cao, cơm béo ngậy truyền thống.',
      'bg_color': Color(0xFFE8F5E9),
    },
  ];

  final List<Map<String, dynamic>> _allTechniques = [
    // Monthong
    {
      'variety_id': 'monthong',
      'age': '1-3',
      'age_text': '1 - 3 năm (Cây con kiến thiết)',
      'title': '🏛️ Kỹ thuật bón phân & kích rễ tơ Monthong cây con',
      'category': 'Dinh Dưỡng Cây Con',
      'desc':
          'Bón 200g/gốc NPK 20-20-15 kết hợp 5kg phân hữu cơ vi sinh gà nở 2 tháng/lần. Tưới Trichoderma harzianum nâng pH đất > 6.0 chống thối rễ cám mùa mưa.\n\n📚 Nguồn: Viện KHKT Nông Lâm Nghiệp Tây Nguyên (WASI)',
      'tag': '1-3 năm tuổi',
      'source': '🏛️ Viện WASI Tây Nguyên',
    },
    {
      'variety_id': 'monthong',
      'age': '1-3',
      'age_text': '1 - 3 năm (Cây con kiến thiết)',
      'title': '🔬 Quy trình bấm đọt hãm ngọn & tỉa cành nón lá',
      'category': 'Tạo Tán Nón Lá',
      'desc':
          'Bấm ngọn thân chính ở chiều cao 3.2 - 3.5m giúp cành cấp 1 phát triển to khỏe. Cắt tỉa cành mọc sà mặt đất < 50cm và cành bơi trong tán.\n\n📚 Nguồn: Viện Nghiên cứu Cây ăn quả Miền Nam (SOFRI)',
      'tag': '1-3 năm tuổi',
      'source': '🔬 Viện SOFRI Miền Nam',
    },
    {
      'variety_id': 'monthong',
      'age': '4-7',
      'age_text': '4 - 7 năm (Cây làm bông)',
      'title': '🏛️ Kỹ thuật siết nước 20 ngày & ép mầm hoa Monthong',
      'category': 'Xử Lý Mầm Hoa',
      'desc':
          'Rải Super Lân 1.5 - 2.0kg/gốc khi cơi đọt 2 lụa già. Siết nước hoàn toàn 18-22 ngày kết hợp phủ bạt mủ nylon mương rãnh. Xả nước nhẹ khi mắt cua nhú 2cm.\n\n📚 Nguồn: Cục Trồng Trọt - Bộ Nông nghiệp & PTNT',
      'tag': '4-7 năm tuổi',
      'source': '🏛️ Cục Trồng Trọt (Bộ NN&PTNT)',
    },
    {
      'variety_id': 'monthong',
      'age': '4-7',
      'age_text': '4 - 7 năm (Cây làm bông)',
      'title': '🎓 Thụ phấn nhân tạo bổ sung khung giờ vàng 18h00 - 20h00',
      'category': 'Thụ Phấn Bổ Sung',
      'desc':
          'Dùng cọ quét nhẹ nhụy hoa từ 18h00 - 20h00 tối khi hoa sầu riêng nở rộ. Tăng tỷ lệ đậu trái tròn đều hộc lên > 85%, hạn chế trái méo.\n\n📚 Nguồn: Khoa Nông Nghiệp - Đại học Cần Thơ',
      'tag': '4-7 năm tuổi',
      'source': '🎓 Đại học Cần Thơ',
    },
    {
      'variety_id': 'monthong',
      'age': '8+',
      'age_text': '8+ năm (Cây kinh doanh)',
      'title': '🌾 Quy trình bón Kali Sunfat (K2SO4) nuôi cơm Monthong hạt lép',
      'category': 'Nuôi Trái & Cơm',
      'desc':
          'Giai đoạn quả 70-90 ngày: Bón NPK 12-12-17 kết hợp K2SO4 (Kali Sunfat) tỉ lệ 2:1. Cơm sầu riêng lên màu vàng rực, dẻo béo và không bị sượng cơm hay cháy múi.\n\n📚 Nguồn: Trung tâm Khuyến nông Quốc gia',
      'tag': '8+ năm tuổi',
      'source': '🌾 Khuyến nông Quốc gia',
    },
    {
      'variety_id': 'monthong',
      'age': '8+',
      'age_text': '8+ năm (Cây kinh doanh)',
      'title': '🏛️ Kỹ thuật hãm đọt non mùa nuôi quả chống rụng trái',
      'category': 'Hãm Đọt Non',
      'desc':
          'Khi cây vừa nhú cơi đọt non lúc mang quả 30-50 ngày, phun ngay K2SO4 500g/200L nước hoặc MKP để già đọt lụa nhanh, tránh đọt non giành dinh dưỡng làm rụng trái.\n\n📚 Nguồn: Viện KHKT Nông Lâm Nghiệp Tây Nguyên (WASI)',
      'tag': '8+ năm tuổi',
      'source': '🏛️ Viện WASI Tây Nguyên',
    },

    // Ri6
    {
      'variety_id': 'ri6',
      'age': '1-3',
      'age_text': '1 - 3 năm (Cây con kiến thiết)',
      'title': '🔬 Tạo bộ khung cành ngang 360 độ & tỉa cành bơi Ri6',
      'category': 'Tỉa Cành & Tạo Tán',
      'desc':
          'Giữ 1 thân chính thẳng đứng. Tỉa bỏ cành sát đất < 60cm và cành bơi mọc ngược vào thân để tán thoáng nhận ánh sáng 360 độ.\n\n📚 Nguồn: Viện Nghiên cứu Cây ăn quả Miền Nam (SOFRI)',
      'tag': '1-3 năm tuổi',
      'source': '🔬 Viện SOFRI Miền Nam',
    },
    {
      'variety_id': 'ri6',
      'age': '4-7',
      'age_text': '4 - 7 năm (Cây làm bông)',
      'title': '🏛️ Phun MKP (0-52-34) làm già lá lụa Ri6 tạo mầm hoa',
      'category': 'Xử Lý Mầm Hoa',
      'desc':
          'Phun MKP 500g/200L nước 2 lần cách nhau 7 ngày giúp cơi đọt đồng loạt lụa già, tạo tiền đề siết nước nhú mầm hoa mắt cua đều khắp tán.\n\n📚 Nguồn: Viện KHKT Nông Lâm Nghiệp Tây Nguyên (WASI)',
      'tag': '4-7 năm tuổi',
      'source': '🏛️ Viện WASI Tây Nguyên',
    },
    {
      'variety_id': 'ri6',
      'age': '8+',
      'age_text': '8+ năm (Cây kinh doanh)',
      'title': '🌾 Quy trình chống sượng cơm & cháy múi Ri6 bằng Magie-Boron',
      'category': 'Dinh Dưỡng Cơm Quả',
      'desc':
          'Phun vi lượng Canxi-Bo + Magie Sulfate giai đoạn 45 ngày tuổi. Giúp cơm Ri6 dẻo rượm, vàng đậm, hạt lép và không bị bã cơm mùa mưa.\n\n📚 Nguồn: Trung tâm Khuyến nông Quốc gia',
      'tag': '8+ năm tuổi',
      'source': '🌾 Khuyến nông Quốc gia',
    },

    // Musang King
    {
      'variety_id': 'musang_king',
      'age': '1-3',
      'age_text': '1 - 3 năm',
      'title': '🎓 Che nắng & phòng rầy nhảy Allocaridara Musang King',
      'category': 'Bảo Vệ Đọt Non',
      'desc':
          'Musang King lá mỏng dễ cháy nắng và rầy nhảy chích hút biến dạng đọt. Phun Imidacloprid + Amino Acid ngay khi đọt nhú 2cm.\n\n📚 Nguồn: Khoa Nông Nghiệp - Đại học Cần Thơ',
      'tag': '1-3 năm tuổi',
      'source': '🎓 Đại học Cần Thơ',
    },
    {
      'variety_id': 'musang_king',
      'age': '4-7',
      'age_text': '4 - 7 năm',
      'title': '🏛️ Tuyển trái chuẩn VIP 5 hộc Musang King xuất khẩu',
      'category': 'Tuyển Trái Chuẩn',
      'desc':
          'Chỉ giữ 40-50 trái/cây 5-7 năm tuổi. Tỉa bỏ trái méo hộc, trái cong vẹo để tập trung dinh dưỡng nuôi trái tròn hình ngôi sao VIP.\n\n📚 Nguồn: Cục Trồng Trọt - Bộ Nông nghiệp & PTNT',
      'tag': '4-7 năm tuổi',
      'source': '🏛️ Cục Trồng Trọt (Bộ NN&PTNT)',
    },

    // Black Thorn
    {
      'variety_id': 'black_thorn',
      'age': '1-3',
      'age_text': '1 - 3 năm',
      'title': '🔬 Bổ sung Canxi-Bo & Kẽm Chelate chống nứt vỏ Gai Đen',
      'category': 'Dinh Dưỡng Vi Lượng',
      'desc':
          'Gai Đen lớn cực nhanh dễ bị nứt vỏ thân. Phun vi lượng Canxi-Bo + Kẽm Chelate 15 ngày/lần giúp vách tế bào dẻo dai chắc khỏe.\n\n📚 Nguồn: Viện Nghiên cứu Cây ăn quả Miền Nam (SOFRI)',
      'tag': '1-3 năm tuổi',
      'source': '🔬 Viện SOFRI Miền Nam',
    },
    {
      'variety_id': 'black_thorn',
      'age': '4-7',
      'age_text': '4 - 7 năm',
      'title': '🏛️ Quản lý độ ẩm đắp mô cao 80cm & mương rãnh cho Gai Đen',
      'category': 'Thoát Nước Mùa Mưa',
      'desc':
          'Gai Đen nhạy cảm ngập úng. Đắp mô đất cao 80cm và xẻ mương thoát nước sâu 1m tránh bão hòa nước làm thối rễ cám.\n\n📚 Nguồn: Viện KHKT Nông Lâm Nghiệp Tây Nguyên (WASI)',
      'tag': '4-7 năm tuổi',
      'source': '🏛️ Viện WASI Tây Nguyên',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // STEP 1: Select Durian Variety
    if (_selectedVariety == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app_outlined, color: Color(0xFF2E7D32), size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Vui lòng chọn Giống Sầu Riêng của nông trại để xem kỹ thuật canh tác tối ưu:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _varieties.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _varieties[index];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedVariety = item;
                      _selectedAge = 'all';
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: item['bg_color'] as Color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD0E1D4)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          item['icon'] as String,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'] as String,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B4D3E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['origin'] as String,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF388E3C),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['desc'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade800,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios,
                            color: Color(0xFF2E7D32), size: 16),
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

    // STEP 2: View Cultivation Techniques Filtered by Age for Selected Variety
    final varietyId = _selectedVariety!['id'] as String;
    final filteredTechniques = _allTechniques.where((item) {
      final matchesVariety = item['variety_id'] == varietyId;
      final matchesAge = _selectedAge == 'all' || item['age'] == _selectedAge;
      return matchesVariety && matchesAge;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Selected Variety Banner + Back Button
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B4D3E), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text(
                  _selectedVariety!['icon'] as String,
                  style: const TextStyle(fontSize: 26),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedVariety!['name'] as String,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Cẩm nang kỹ thuật canh tác chuẩn Vie-farm',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedVariety = null;
                    });
                  },
                  icon: const Icon(Icons.swap_horiz, size: 14, color: Colors.amber),
                  label: const Text(
                    'Đổi giống',
                    style: TextStyle(fontSize: 11, color: Colors.amber),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.amber),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Age Filter Chips
          const Text(
            'Lọc theo độ tuổi cây sầu riêng:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(height: 8),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildAgeChip('all', 'Tất cả độ tuổi'),
                const SizedBox(width: 8),
                _buildAgeChip('1-3', '🐣 1 - 3 năm (Cây con)'),
                const SizedBox(width: 8),
                _buildAgeChip('4-7', '🌳 4 - 7 năm (Làm bông)'),
                const SizedBox(width: 8),
                _buildAgeChip('8+', '👑 8+ năm (Kinh doanh)'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Techniques List
          if (filteredTechniques.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, color: Colors.grey, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    'Chưa có kỹ thuật canh tác riêng cho độ tuổi ${_selectedAge} năm của giống này.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredTechniques.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = filteredTechniques[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2EFE9)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(6),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item['category'] as String,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Text(
                              item['tag'] as String,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item['title'] as String,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['desc'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAgeChip(String key, String label) {
    final isSelected = _selectedAge == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedAge = key;
          });
        }
      },
      selectedColor: const Color(0xFF2E7D32),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : const Color(0xFF2E7D32),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: const BorderSide(color: Color(0xFFC8E6C9)),
    );
  }
}

class PestsAndDiseasesSeasonalWidget extends StatefulWidget {
  const PestsAndDiseasesSeasonalWidget({super.key});

  @override
  State<PestsAndDiseasesSeasonalWidget> createState() =>
      _PestsAndDiseasesSeasonalWidgetState();
}

class _PestsAndDiseasesSeasonalWidgetState
    extends State<PestsAndDiseasesSeasonalWidget> {
  String _selectedSeason = 'all'; // 'all', 'rainy', 'dry', 'flowering'

  final List<Map<String, dynamic>> _diseases = [
    // 1. Phytophthora
    {
      'id': 'phytophthora',
      'name': 'Bệnh xì mủ thối gốc sầu riêng',
      'scientific': 'Phytophthora palmivora',
      'season': 'rainy',
      'season_label': '🌧️ Mùa Mưa',
      'risk_level': 'RẤT CAO',
      'risk_color': Colors.red,
      'symptoms':
          'Vết nứt xì mủ nâu đen rỉ nước trên vỏ gốc thân, lá vàng quăn rụng trơ cành, thối rễ cám hàng loạt.',
      'treatment':
          'Cạo sạch vết xì mủ, quét Metalaxyl 68WG hoặc Ridomil Gold đậm đặc. Tưới 500g Vôi bột + 100g Phosphonate / gốc.',
      'phi': '7 ngày',
      'ingredient': 'Metalaxyl + Mancozeb / Potassium Phosphonate',
    },
    // 2. Colletotrichum
    {
      'id': 'colletotrichum',
      'name': 'Bệnh thán thư lá sầu riêng',
      'scientific': 'Colletotrichum gloeosporioides',
      'season': 'rainy',
      'season_label': '🌧️ Mùa Mưa',
      'risk_level': 'CAO',
      'risk_color': Colors.deepOrange,
      'symptoms':
          'Lá xuất hiện vết cháy tròn màu nâu xám đồng tâm từ mép lá, quăn queo và rụng trơ trụi cơi đọt non.',
      'treatment':
          'Phun luân phiên Mancozeb (Dithane M-45), Azoxystrobin hoặc Hexaconazole (Anvil 5SC) định kỳ 7-10 ngày vào mùa mưa.',
      'phi': '14 ngày',
      'ingredient': 'Azoxystrobin + Difenoconazole (Amistar Top)',
    },
    // 3. Erythricium
    {
      'id': 'erythricium',
      'name': 'Bệnh nấm hồng chạc cành',
      'scientific': 'Erythricium salmonicolor',
      'season': 'rainy',
      'season_label': '🌧️ Mùa Mưa',
      'risk_level': 'CAO',
      'risk_color': Colors.deepOrange,
      'symptoms':
          'Mảng tơ nấm màu hồng nhạt bao phủ chạc cành cấp 1-2, làm tắc mạch dẫn khiến toàn bộ cành phía trên bị khô héo.',
      'treatment':
          'Cắt tỉa cành bệnh đem đốt tiêu hủy. Phun thuốc gốc Đồng (Copper Hydroxide / Coc 85) hoặc Validamycin.',
      'phi': '7 ngày',
      'ingredient': 'Copper Hydroxide / Validamycin A',
    },
    // 4. Rhizoctonia
    {
      'id': 'rhizoctonia',
      'name': 'Bệnh cháy lá đốm mắt cua',
      'scientific': 'Rhizoctonia solani',
      'season': 'rainy',
      'season_label': '🌧️ Mùa Mưa',
      'risk_level': 'TRUNG BÌNH',
      'risk_color': Colors.amber.shade900,
      'symptoms':
          'Lá lụa bị tổn thương đốm bỏng nước loang lổ, đọt non bị quánh dính lại với nhau như tổ nhện.',
      'treatment':
          'Phun Validamycin hoặc Carbendazim 2 lần cách nhau 5 ngày. Tỉa cành thoáng nhận nắng.',
      'phi': '7 ngày',
      'ingredient': 'Validamycin + Hexaconazole',
    },
    // 5. Fusarium
    {
      'id': 'fusarium',
      'name': 'Bệnh thối đít quả sầu riêng',
      'scientific': 'Fusarium oxysporum',
      'season': 'rainy',
      'season_label': '🌧️ Mùa Mưa',
      'risk_level': 'CAO',
      'risk_color': Colors.deepOrange,
      'symptoms':
          'Phần rốn đít quả bị nấm trắng bám thâm loang lổ, xì mủ thối mụt rơi rụng trước thu hoạch.',
      'treatment':
          'Phun phòng thuốc gốc Đồng + Kẽm Chelate khi quả được 50 ngày tuổi. Kê lót trái không chạm mặt đất.',
      'phi': '10 ngày',
      'ingredient': 'Copper Hydroxide + Zinc Chelate',
    },

    // 6. Allocaridara
    {
      'id': 'allocaridara',
      'name': 'Rầy nhảy chích hút cơi đọt',
      'scientific': 'Allocaridara malayensis',
      'season': 'dry',
      'season_label': '☀️ Mùa Khô',
      'risk_level': 'RẤT CAO',
      'risk_color': Colors.red,
      'symptoms':
          'Rầy mủ trắng chích hút nhựa đọt non làm lá quăn queo, biến dạng nhỏ hẹp và rụng hàng loạt.',
      'treatment':
          'Phun Imidacloprid (Confidor) hoặc Thiamethoxam khi cơi đọt nhú 2-3cm vào sáng sớm.',
      'phi': '7 ngày',
      'ingredient': 'Imidacloprid 200SL / Thiamethoxam 250WG',
    },
    // 7. Pseudococcus
    {
      'id': 'pseudococcus',
      'name': 'Rệp sáp hại rễ & cuống quả',
      'scientific': 'Pseudococcus spp.',
      'season': 'dry',
      'season_label': '☀️ Mùa Khô',
      'risk_level': 'CAO',
      'risk_color': Colors.deepOrange,
      'symptoms':
          'Lớp sáp trắng mịn bám kín cuống quả & rễ tơ, tiết mật ngọt thu hút kiến đen và gây nấm bồ hóng đen lá.',
      'treatment':
          'Tưới gốc Spirotetramat hoặc Spiromesifen kết hợp dội nước áp lực cao phá vỡ vách sáp.',
      'phi': '14 ngày',
      'ingredient': 'Spirotetramat (Movento 150OD)',
    },
    // 8. Tetranychus
    {
      'id': 'tetranychus',
      'name': 'Nhện đỏ hại mặt dưới lá',
      'scientific': 'Tetranychus urticae',
      'season': 'dry',
      'season_label': '☀️ Mùa Khô',
      'risk_level': 'TRUNG BÌNH',
      'risk_color': Colors.amber.shade900,
      'symptoms':
          'Mặt dưới lá bị bạc màu bụi cám, chấm lấm lúm li ti kèm tơ nhện mỏng làm suy kiệt quang hợp.',
      'treatment':
          'Phun Abamectin hoặc Pyridaben xoay vòng gốc thuốc tránh nhện đỏ kháng thuốc.',
      'phi': '7 ngày',
      'ingredient': 'Abamectin + Pyridaben',
    },

    // 9. Thrips
    {
      'id': 'thrips',
      'name': 'Bọ trĩ hại hoa & quả non',
      'scientific': 'Thrips spp.',
      'season': 'flowering',
      'season_label': '🌸 Mùa Làm Bông',
      'risk_level': 'RẤT CAO',
      'risk_color': Colors.red,
      'symptoms':
          'Bọ trĩ hút nhựa hoa làm chùm hoa khô đen, cuống trái non bị đảo gai méo hộc rụng hàng loạt.',
      'treatment':
          'Phun Spinetoram (Radiant 60SC) hoặc Spirotetramat trước khi hoa xả tụy nở rộ 3 ngày.',
      'phi': '5 ngày',
      'ingredient': 'Spinetoram (Radiant 60SC)',
    },
    // 10. Conogethes
    {
      'id': 'conogethes',
      'name': 'Sâu đục quả sầu riêng',
      'scientific': 'Conogethes punctiferalis',
      'season': 'flowering',
      'season_label': '🌸 Đậu Trái',
      'risk_level': 'CAO',
      'risk_color': Colors.deepOrange,
      'symptoms':
          'Sâu đục khoét nách chùm trái xì đùn phân đen ra ngoài, làm hỏng hoàn toàn múi cơm bên trong.',
      'treatment':
          'Phun Emamectin benzoate kết hợp chèn miếng xốp mỏng giữa 2 quả lân cận tránh tiếp xúc chùm.',
      'phi': '7 ngày',
      'ingredient': 'Emamectin benzoate 5WG',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _diseases.where((item) {
      if (_selectedSeason == 'all') return true;
      return item['season'] == _selectedSeason;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Top
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFE0B2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.deepOrange, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bộ Cẩm Nang Tra Cứu 10 Loại Sâu Bệnh Hại Sầu Riêng Phổ Biến:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFBF360C),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Seasonal Filter Chips Bar
          const Text(
            'Lọc sâu bệnh hại theo đặc điểm mùa vụ:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(height: 8),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSeasonChip('all', 'Tất cả các mùa'),
                const SizedBox(width: 8),
                _buildSeasonChip('rainy', '🌧️ Mùa Mưa (Nấm & Thối rễ)'),
                const SizedBox(width: 8),
                _buildSeasonChip('dry', '☀️ Mùa Khô (Rầy & Rệp)'),
                const SizedBox(width: 8),
                _buildSeasonChip('flowering', '🌸 Mùa Làm Bông & Trái Non'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Diseases List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = filtered[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2EFE9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(6),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (item['risk_color'] as Color).withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: (item['risk_color'] as Color).withAlpha(80)),
                          ),
                          child: Text(
                            '🔥 ${item['risk_level']}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: item['risk_color'] as Color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item['season_label'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'PHI: ${item['phi']}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item['name'] as String,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                    Text(
                      item['scientific'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '🚨 Triệu chứng: ${item['symptoms']}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '💊 Thuốc & Biện pháp: ${item['treatment']}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '🧪 Hoạt chất khuyên dùng: ${item['ingredient']}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.blueGrey.shade700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonChip(String key, String label) {
    final isSelected = _selectedSeason == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedSeason = key;
          });
        }
      },
      selectedColor: const Color(0xFF2E7D32),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : const Color(0xFF2E7D32),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: const BorderSide(color: Color(0xFFC8E6C9)),
    );
  }
}


