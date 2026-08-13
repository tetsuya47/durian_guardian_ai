import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DailyAiNotificationItem {
  final String id;
  final String time;
  final String title;
  final String category; // 'disease', 'pest', 'irrigation', 'market', 'compliance', 'fertilizer'
  final String gardenName;
  final String description;
  final List<String> aiActionSteps;
  final Color badgeColor;
  final Color badgeBg;
  final IconData icon;
  final bool isUrgent;
  final bool requiresIoT;

  const DailyAiNotificationItem({
    required this.id,
    required this.time,
    required this.title,
    required this.category,
    required this.gardenName,
    required this.description,
    required this.aiActionSteps,
    required this.badgeColor,
    required this.badgeBg,
    required this.icon,
    this.isUrgent = false,
    this.requiresIoT = false,
  });
}

class DailyAiNotificationsPage extends StatefulWidget {
  final bool hasIoTDevices;

  const DailyAiNotificationsPage({
    super.key,
    this.hasIoTDevices = false,
  });

  @override
  State<DailyAiNotificationsPage> createState() => _DailyAiNotificationsPageState();
}

class _DailyAiNotificationsPageState extends State<DailyAiNotificationsPage> {
  String _selectedGardenFilter = 'all';

  final List<DailyAiNotificationItem> _allNotifications = const [
    // 1. IoT-dependent Notifications (requiresIoT: true)
    DailyAiNotificationItem(
      id: 'ai_1',
      time: '08:30 Sáng',
      title: 'Cảnh báo nguy cơ Nấm Xì Mủ Phytophthora (85%)',
      category: 'disease',
      gardenName: 'Vườn Krông Pắk (Đắk Lắk)',
      description: 'Cảm biến IoT phát hiện độ ẩm đất đạt 78% liên tục trong suốt 48 giờ kết hợp độ ẩm không khí 82% và nhiệt độ 28.5°C. Bào tử nấm đang nảy mầm xâm nhập chóp rễ tơ.',
      aiActionSteps: [
        'Ngắt ngay van tưới tự động khu vực đất ẩm trong 3-5 ngày.',
        'Khơi thông các rãnh thoát nước sâu 40-50cm quanh mô đất sầu riêng.',
        'Tưới sục nấm đối kháng Trichoderma hazianum + Bacillus subtilis quanh tán rễ.',
        'Quét vôi tôi pha hoạt chất Metalaxyl lên thân cây cao 1 mét để chặn nấm xì mủ.',
      ],
      badgeColor: Color(0xFFC62828),
      badgeBg: Color(0xFFFFEBEE),
      icon: Icons.warning_amber_rounded,
      isUrgent: true,
      requiresIoT: true,
    ),
    DailyAiNotificationItem(
      id: 'ai_2',
      time: '10:15 Trưa',
      title: 'Dự báo bùng phát Rầy Nhảy & Bọ Trĩ chích hút cơi đọt non',
      category: 'pest',
      gardenName: 'Vườn Cai Lậy (Tiền Giang)',
      description: 'Dữ liệu vi khí hậu từ trạm thời tiết phát hiện nhiệt độ đọt 33°C kèm nắng ráo kích thích trứng rầy nở nhanh trên bề mặt lá non.',
      aiActionSteps: [
        'Phun phòng chế phẩm sinh học Nấm Xanh (Metarhizium) hoặc dầu khoáng SK99 vào chiều mát.',
        'Phun sương giữ ẩm nhẹ tán lá vào sáng sớm để cản trở rầy di chuyển.',
        'Bảo tồn đàn Kiến vàng và bọ rùa săn mồi tự nhiên trong vườn.',
      ],
      badgeColor: Color(0xFFE65100),
      badgeBg: Color(0xFFFFF3E0),
      icon: Icons.bug_report_outlined,
      isUrgent: false,
      requiresIoT: true,
    ),
    DailyAiNotificationItem(
      id: 'ai_3',
      time: '06:00 Sáng',
      title: 'Khuyến nghị ngưng tưới và bổ sung Canxi-Bo cho cây xổ nhụy',
      category: 'irrigation',
      gardenName: 'Vườn Krông Pắk (Đắk Lắk)',
      description: 'Số liệu cảm biến IoT đo được độ pH đất 6.2 và EC 1.4 mS/cm. Cây đang trong giai đoạn nhú hoa và xổ nhụy cần hạn chế tưới nước thừa để chống hiện tượng sốc nước rụng bông non.',
      aiActionSteps: [
        'Duy trì lượng tưới nhẹ chỉ 20-30% mức bình thường vào sáng sớm.',
        'Phun bổ sung vi lượng Canxi - Bo hữu cơ lên chùm hoa tăng tỷ lệ hạt phấn đậu trái.',
      ],
      badgeColor: Color(0xFF00796B),
      badgeBg: Color(0xFFE0F2F1),
      icon: Icons.water_drop_outlined,
      isUrgent: false,
      requiresIoT: true,
    ),

    // 2. Non-IoT / General Notifications (requiresIoT: false - ALWAYS VISIBLE!)
    DailyAiNotificationItem(
      id: 'ai_4',
      time: '07:00 Sáng',
      title: 'Giá thu mua Monthong tại Đắk Lắk hôm nay tăng +2.000đ/kg',
      category: 'market',
      gardenName: 'Toàn vùng Tây Nguyên',
      description: 'Giá thu mua sầu riêng Monthong loại 1 xuất khẩu tại vườn hôm nay ghi nhận mức 94.000 – 95.000đ/kg do nhu cầu tiêu thụ tại thị trường tỷ dân tăng cao.',
      aiActionSteps: [
        'Theo dõi độ ngọt và màu cơm sầu riêng để lên lịch cắt trái đợt 1 đúng độ chín 8.5 tuổi.',
        'Chuẩn bị bao bì và tem truy xuất nguồn gốc QR code sẵn sàng xuất bán.',
      ],
      badgeColor: Color(0xFF2E7D32),
      badgeBg: Color(0xFFE8F5E9),
      icon: Icons.trending_up,
      isUrgent: false,
      requiresIoT: false,
    ),
    DailyAiNotificationItem(
      id: 'ai_5',
      time: '09:00 Sáng',
      title: 'Khuyến nghị bón phân hữu cơ vi sinh đợt 2 mùa mưa',
      category: 'fertilizer',
      gardenName: 'Toàn bộ trang trại',
      description: 'Vào đầu mùa mưa, đất ẩm thuận lợi cho vi sinh vật cố định đạm phát triển. Bổ sung phân gà ủ hoai mục kết hợp nấm Trichoderma giúp phục hồi bộ rễ.',
      aiActionSteps: [
        'Bón 5-8 kg phân hữu cơ vi sinh quanh chiếu rễ cây 4 năm tuổi.',
        'Xới nhẹ lớp đất mặt 3-5 cm để phân bón ngấm đều, tránh bón trực tiếp sát gốc cây.',
      ],
      badgeColor: Color(0xFF7B1FA2),
      badgeBg: Color(0xFFF3E5F5),
      icon: Icons.eco_rounded,
      isUrgent: false,
      requiresIoT: false,
    ),
    DailyAiNotificationItem(
      id: 'ai_6',
      time: '14:00 Chiều',
      title: 'Nhắc nhở cập nhật nhật ký bón phân hữu cơ chuẩn GACC',
      category: 'compliance',
      gardenName: 'Vườn Sầu Riêng',
      description: 'Còn 3 ngày nữa trước kỳ đối soát định kỳ dữ liệu mã số vùng trồng (MSVT) xuất khẩu chính ngạch sang thị trường Trung Quốc.',
      aiActionSteps: [
        'Mở tab "Nhật ký" trên ứng dụng và tích xác nhận lần bón phân hữu cơ vi sinh đợt 2.',
        'Chụp ảnh bao bì phân bón lưu vào hồ sơ kiểm tra điện tử.',
      ],
      badgeColor: Color(0xFF1565C0),
      badgeBg: Color(0xFFE3F2FD),
      icon: Icons.verified_user_outlined,
      isUrgent: false,
      requiresIoT: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final availableNotifications = _allNotifications.where((n) {
      if (!widget.hasIoTDevices && n.requiresIoT) {
        return false; // Filter out IoT-dependent AI alerts for users without IoT equipment!
      }
      if (_selectedGardenFilter == 'krong_pak') {
        return n.gardenName.contains('Krông Pắk') || n.gardenName.contains('Toàn');
      } else if (_selectedGardenFilter == 'cai_lay') {
        return n.gardenName.contains('Cai Lậy') || n.gardenName.contains('Toàn');
      }
      return true;
    }).toList();

    final iotCount = _allNotifications.where((n) => n.requiresIoT).length;
    final generalCount = _allNotifications.where((n) => !n.requiresIoT).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Thông Báo AI Vườn Sầu Riêng',
          style: TextStyle(
            fontSize: 17.5,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily AI Agronomist Overview Card
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Color(0xFFFFD54F), size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Điểm Tin AI Hôm Nay',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
                          style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.hasIoTDevices
                        ? 'Vie-farm AI đã phân tích dữ liệu vi khí hậu từ trạm cảm biến IoT và dự báo thời tiết tại vườn. Dưới đây là các thông báo quan trọng:'
                        : 'Điểm tin thị trường giá cả, khuyến nghị bón phân hữu cơ và nhắc nhở nhật ký đối soát GACC hôm nay:',
                    style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.35),
                  ),
                  const SizedBox(height: 12),

                  // Status Summary Bar
                  Row(
                    children: [
                      if (widget.hasIoTDevices) ...[
                        _buildSummaryPill('🔴 1 Cảnh báo cao', const Color(0xFFFFEBEE), const Color(0xFFC62828)),
                        const SizedBox(width: 6),
                        _buildSummaryPill('🟡 1 Dự báo rầy', const Color(0xFFFFF3E0), const Color(0xFFE65100)),
                        const SizedBox(width: 6),
                      ],
                      _buildSummaryPill('📈 Giá sầu riêng', const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
                      const SizedBox(width: 6),
                      _buildSummaryPill('🌿 1 Bón phân', const Color(0xFFF3E5F5), const Color(0xFF7B1FA2)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notice Banner for Non-IoT users encouraging IoT connection
            if (!widget.hasIoTDevices) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFD54F)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFE65100), size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kích hoạt AI Cảnh Báo Vi Khí Hậu Vườn',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFFE65100)),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Để nhận cảnh báo nấm bệnh Phytophthora và khuyến nghị tưới tiêu chính xác từ Vie-farm AI, hãy lắp đặt cảm biến IoT cho vườn sầu riêng.',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF5D4037)),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/iot-shop'),
                            icon: const Icon(Icons.shopping_cart_outlined, size: 14, color: Colors.white),
                            label: const Text('Mua Thiết Bị IoT', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Garden Filter Chips
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('all', 'Tất cả thông báo (${availableNotifications.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('krong_pak', '🌿 Vườn Krông Pắk (Đắk Lắk)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('cai_lay', '🌿 Vườn Cai Lậy (Tiền Giang)'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Notifications List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: availableNotifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final item = availableNotifications[index];
                return _buildNotificationCard(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryPill(String label, Color bg, Color text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String id, String label) {
    final isSelected = _selectedGardenFilter == id;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedGardenFilter = id),
      selectedColor: const Color(0xFF2E7D32),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF444444),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(DailyAiNotificationItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: item.isUrgent ? const Color(0xFFEF9A9A) : Colors.grey.shade200,
          width: item.isUrgent ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Category Badge + Time + Garden Tag (Zero Overflow)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: item.badgeBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, size: 15, color: item.badgeColor),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: item.badgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.gardenName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: item.badgeColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.time,
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2E25),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),

          // Description
          Text(
            item.description,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),

          // Action Steps Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBF9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.checklist_rounded, size: 16, color: Color(0xFF2E7D32)),
                    SizedBox(width: 6),
                    Text(
                      'Biện pháp xử lý đề xuất từ AI:',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...item.aiActionSteps.map((step) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              step,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF333333), height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
