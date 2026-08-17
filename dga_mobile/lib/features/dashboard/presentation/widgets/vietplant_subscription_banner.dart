import 'package:flutter/material.dart';

class VietplantSubscriptionBanner extends StatefulWidget {
  final VoidCallback? onUpgradeTap;

  const VietplantSubscriptionBanner({super.key, this.onUpgradeTap});

  @override
  State<VietplantSubscriptionBanner> createState() => _VietplantSubscriptionBannerState();
}

class _VietplantSubscriptionBannerState extends State<VietplantSubscriptionBanner> {
  final PageController _pageController = PageController(viewportFraction: 0.88, initialPage: 1);
  int _currentPage = 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF81C784)),
            ),
            child: const Text(
              'ƯU ĐÃI GÓI NÔNG NGHIỆP THÔNG MINH',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Kích Hoạt Công Nghệ AI & IoT Cho Trang Trại',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2E25),
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Lựa chọn giải pháp phù hợp để giám sát đất, cảnh báo nấm bệnh & tối ưu sản lượng',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF616161),
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Navigation Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDot(0, 'Gói Plus'),
              const SizedBox(width: 8),
              _buildDot(1, 'Gói Pro ⭐'),
              const SizedBox(width: 8),
              _buildDot(2, 'Gói Premium'),
            ],
          ),
          const SizedBox(height: 14),

          // Carousel
          SizedBox(
            height: 440,
            child: PageView(
              controller: _pageController,
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              children: [
                // 1. Gói Plus
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _buildCard(
                    context: context,
                    badgeText: 'Gói Mặc Định',
                    badgeColor: const Color(0xFFEEEEEE),
                    badgeTextColor: const Color(0xFF616161),
                    packageName: 'Gói Plus',
                    price: 'Miễn Phí',
                    priceSuffix: ' vĩnh viễn',
                    priceColor: const Color(0xFF2E7D32),
                    description: 'Dành cho nông hộ trải nghiệm các tính năng cơ bản của ứng dụng.',
                    features: [
                      _Feature(true, 'Sử dụng các chức năng app có giới hạn lượt'),
                      _Feature(true, 'Giới hạn lượt quét AI (tự động hồi lượt hàng tuần)'),
                      _Feature(true, 'Dự báo thời tiết & tra cứu giá thu mua tại vườn'),
                      _Feature(false, 'Không được tư vấn 1-1 với Chuyên gia Nông nghiệp'),
                    ],
                    buttonText: 'Đang sử dụng',
                    isButtonActive: false,
                    buttonColor: const Color(0xFFF5F5F5),
                    buttonTextColor: const Color(0xFF9E9E9E),
                    onTap: () {},
                  ),
                ),

                // 2. Gói Pro (Highlight)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _buildCard(
                    context: context,
                    badgeText: 'PHỔ BIẾN ⭐',
                    badgeColor: const Color(0xFF2E7D32),
                    badgeTextColor: Colors.white,
                    hasGlowBorder: true,
                    packageName: 'Gói Pro',
                    price: '30.000đ',
                    priceSuffix: ' / tháng',
                    priceColor: const Color(0xFF2E7D32),
                    description: 'Mở khóa toàn bộ chức năng ứng dụng & Tư vấn Chuyên gia Nông nghiệp.',
                    features: [
                      _Feature(true, 'Sử dụng TẤT CẢ các chức năng trong app theo tháng'),
                      _Feature(true, 'Không giới hạn lượt quét AI & chẩn đoán sâu bệnh'),
                      _Feature(true, 'Mở khóa tư vấn 1-1 trực tiếp với Chuyên gia Nông nghiệp'),
                      _Feature(false, 'Không sử dụng được các chức năng thiết bị IoT'),
                    ],
                    buttonText: 'Nâng cấp Gói Pro',
                    isButtonActive: true,
                    buttonColor: const Color(0xFF2E7D32),
                    buttonTextColor: Colors.white,
                    onTap: () => _showDialog(context, 'Gói Pro', '30.000đ / tháng'),
                  ),
                ),

                // 3. Gói Premium
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _buildCard(
                    context: context,
                    badgeText: 'VIP Premium ★★★',
                    badgeColor: const Color(0xFFFFF8E1),
                    badgeTextColor: const Color(0xFFE65100),
                    isPremiumBorder: true,
                    packageName: 'Gói Premium',
                    price: '199.000đ',
                    priceSuffix: ' / tháng',
                    priceColor: const Color(0xFF00838F),
                    description: 'Mở khóa toàn diện AI + IoT quản lý vườn tự động & Ưu đãi Voucher.',
                    features: [
                      _Feature(true, 'Mở khóa thiết bị IoT để AI quản lý vườn & đề xuất kỹ thuật'),
                      _Feature(true, 'Sử dụng TẤT CẢ các chức năng ứng dụng không giới hạn'),
                      _Feature(true, '⭐ Đầy đủ đặc quyền Tư vấn Chuyên gia Nông nghiệp 1-1'),
                      _Feature(true, '🎁 Voucher giảm giá 20% khi mua thiết bị IoT nông nghiệp'),
                    ],
                    buttonText: 'Đăng ký Gói Premium',
                    isButtonActive: true,
                    buttonColor: const Color(0xFF1B5E20),
                    buttonTextColor: Colors.white,
                    onTap: () => _showDialog(context, 'Gói Premium', '199.000đ / tháng'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, String label) {
    final isSelected = _currentPage == index;
    return InkWell(
      onTap: () => _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      ),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade600,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    bool hasGlowBorder = false,
    bool isPremiumBorder = false,
    required String packageName,
    required String price,
    required String priceSuffix,
    required Color priceColor,
    required String description,
    required List<_Feature> features,
    required String buttonText,
    required bool isButtonActive,
    required Color buttonColor,
    required Color buttonTextColor,
    required VoidCallback onTap,
  }) {
    Color borderColor = Colors.grey.shade200;
    double borderWidth = 1.0;
    List<BoxShadow> shadows = [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ];

    if (hasGlowBorder) {
      borderColor = const Color(0xFF2E7D32);
      borderWidth = 2.0;
      shadows = [
        BoxShadow(
          color: const Color(0xFF2E7D32).withOpacity(0.18),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];
    } else if (isPremiumBorder) {
      borderColor = const Color(0xFFFFB300);
      borderWidth = 1.5;
      shadows = [
        BoxShadow(
          color: const Color(0xFFFFB300).withOpacity(0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: shadows,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Name & Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                packageName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2E25),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeTextColor.withOpacity(0.3)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: priceColor,
                ),
              ),
              Text(
                priceSuffix,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF616161),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Subtitle
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF757575),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.grey.shade200, thickness: 1.0),
          const SizedBox(height: 8),

          // Features
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: features.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final f = features[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      f.isIncluded ? Icons.check_circle : Icons.cancel,
                      size: 15,
                      color: f.isIncluded ? const Color(0xFF2E7D32) : const Color(0xFFE53935),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f.text,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: f.isIncluded ? const Color(0xFF2E2E2E) : const Color(0xFF9E9E9E),
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: isButtonActive ? onTap : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                disabledBackgroundColor: buttonColor,
                elevation: isButtonActive ? 2 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonText,
                style: TextStyle(
                  color: buttonTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, String packageName, String price) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.verified, color: Color(0xFF2E7D32), size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Đăng ký $packageName',
                style: const TextStyle(color: Color(0xFF1B2E25), fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Xác nhận đăng ký $packageName ($price) để mở khóa toàn bộ tính năng AI & IoT cho trang trại.',
          style: const TextStyle(color: Color(0xFF424242), fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF2E7D32),
                  content: Text('🎉 Chúc mừng! Bạn đã kích hoạt thành công $packageName.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _Feature {
  final bool isIncluded;
  final String text;

  const _Feature(this.isIncluded, this.text);
}
