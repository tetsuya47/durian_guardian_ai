import 'package:flutter/material.dart';

class SmartGardenManagementPage extends StatefulWidget {
  const SmartGardenManagementPage({super.key});

  @override
  State<SmartGardenManagementPage> createState() => _SmartGardenManagementPageState();
}

class _SmartGardenManagementPageState extends State<SmartGardenManagementPage> {
  int _selectedGardenIndex = 0;
  bool _valveZoneA = false;
  bool _valveZoneB = true;
  bool _autoCutoffEnabled = true;

  final List<_GardenData> _gardens = const [
    _GardenData(
      name: 'Vườn Sầu Riêng Krông Pắk (Đắk Lắk)',
      area: '3.5 ha • 450 cây Ri6 & Monthong',
      stationId: 'IoT-KRONGPAK-01',
      temp: 28.5,
      humidity: 82.0,
      soilMoisture: 78.0,
      soilPh: 6.2,
      ec: 1.4,
      lightLux: 42000,
      rainfall: 15.0,
      battery: 95,
      highRiskDisease: 'Bệnh Nứt Thân Xì Mủ & Thối Rễ (Phytophthora)',
      highRiskScore: 85,
      highRiskReason: 'Độ ẩm đất duy trì 78% liên tục suốt 48h kết hợp độ ẩm không khí 82% và nhiệt độ 28.5°C tạo điều kiện nấm Phytophthora phát triển mạnh.',
      highRiskActions: [
        'Ngắt ngay van tưới tự động khu vực ẩm trong 3-5 ngày.',
        'Khơi thông các rãnh thoát nước sâu 40-50cm quanh mô đất, tránh để nước ngập tù đọng.',
        'Tưới sục nấm đối kháng Trichoderma hazianum + Bacillus subtilis quanh tán rễ non.',
        'Quét vôi tôi pha hoạt chất Metalaxyl lên thân cây từ gốc lên cao 1 mét để chặn nấm xì mủ.',
      ],
      mediumRiskDisease: 'Rầy Nhảy & Bọ Trĩ Chích Hút Cơi Đọt Non',
      mediumRiskScore: 45,
      mediumRiskReason: 'Vườn đang vào giai đoạn nhú cơi lá mới, dự báo 2 ngày tới nhiệt độ tăng lên 33°C thuận lợi cho rầy phát tán.',
      mediumRiskActions: [
        'Phun phòng chế phẩm Nấm Xanh (Metarhizium) hoặc dầu khoáng sinh học SK99 vào chiều mát.',
        'Kiểm tra mặt dưới lá non và bảo vệ đàn Kiến vàng thiên địch trong vườn.',
      ],
    ),
    _GardenData(
      name: 'Vườn Sầu Riêng Cai Lậy (Tiền Giang)',
      area: '2.0 ha • 280 cây Ri6 Nghịch Vụ',
      stationId: 'IoT-CAILAY-02',
      temp: 31.0,
      humidity: 70.0,
      soilMoisture: 62.0,
      soilPh: 5.8,
      ec: 1.6,
      lightLux: 55000,
      rainfall: 0.0,
      battery: 98,
      highRiskDisease: 'Rầy Nhảy & Nhện Đỏ Hại Lá Non',
      highRiskScore: 75,
      highRiskReason: 'Thời tiết nắng nóng nhiệt độ 31°C và độ ẩm đất 62% đang vào chu kỳ sinh sản rộ của rầy phấn và nhện đỏ.',
      highRiskActions: [
        'Tăng cường phun sương giữ ẩm trên tán lá non vào buổi sáng sớm.',
        'Phun chế phẩm sinh học dịch chiết Neem oil hoặc tỏi ớt gừng ngâm rượu.',
        'Duy trì thảm cỏ giữ ẩm mặt đất, hạn chế thoát hơi nước quá nhanh.',
      ],
      mediumRiskDisease: 'Bệnh Cháy Lá Chết Ngọn (Rhizoctonia solani)',
      mediumRiskScore: 40,
      mediumRiskReason: 'Gió mạnh và bức xạ nhiệt cao làm tổn thương mép lá non.',
      mediumRiskActions: [
        'Bổ sung phân bón lá chứa Canxi - Bo - Silic để tăng độ dày vách tế bào lá.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final garden = _gardens[_selectedGardenIndex];

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
          'Quản Lý Vườn Thông Minh (IoT & AI)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Garden Selector Dropdown / Tabs
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
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
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFF2E7D32), size: 18),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Chọn khu vườn quản lý:',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
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
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          garden.stationId,
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(_gardens.length, (index) {
                      final isSelected = _selectedGardenIndex == index;
                      return Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedGardenIndex = index),
                          child: Container(
                            margin: EdgeInsets.only(right: index == 0 ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  index == 0 ? '🌿 Vườn Krông Pắk' : '🌿 Vườn Cai Lậy',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : const Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  index == 0 ? 'Đắk Lắk (3.5 ha)' : 'Tiền Giang (2.0 ha)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected ? Colors.white70 : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 2. IoT Sensor Live Telemetry Dashboard (8 Indicators)
            const Text(
              'Số Liệu Cảm Biến IoT Thu Thập Thời Gian Thực',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2E25),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Trạm cảm biến solar 4G tự động đồng bộ mỗi 30 giây',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),

            // 8 Grid Sensor Cards
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.45,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildSensorCard(
                  icon: Icons.thermostat,
                  iconColor: Colors.deepOrange,
                  title: 'Nhiệt độ khí',
                  value: '${garden.temp}°C',
                  status: 'Tối ưu: 25 - 32°C',
                  isWarning: false,
                ),
                _buildSensorCard(
                  icon: Icons.water_drop,
                  iconColor: Colors.blue,
                  title: 'Ẩm độ không khí',
                  value: '${garden.humidity}%',
                  status: garden.humidity > 80 ? 'Cao > 80% (Ẩm ướt)' : 'Bình thường',
                  isWarning: garden.humidity > 80,
                ),
                _buildSensorCard(
                  icon: Icons.grass,
                  iconColor: const Color(0xFF2E7D32),
                  title: 'Độ ẩm của đất',
                  value: '${garden.soilMoisture}%',
                  status: garden.soilMoisture > 75 ? 'Rất cao ⚠️ (Ngập úng)' : 'Thích hợp',
                  isWarning: garden.soilMoisture > 75,
                ),
                _buildSensorCard(
                  icon: Icons.science,
                  iconColor: Colors.purple,
                  title: 'Độ pH của đất',
                  value: '${garden.soilPh} pH',
                  status: 'Chuẩn: 5.5 - 6.5',
                  isWarning: false,
                ),
                _buildSensorCard(
                  icon: Icons.bolt,
                  iconColor: Colors.amber.shade800,
                  title: 'Dinh dưỡng EC',
                  value: '${garden.ec} mS/cm',
                  status: 'Hấp thụ ổn định',
                  isWarning: false,
                ),
                _buildSensorCard(
                  icon: Icons.wb_sunny,
                  iconColor: Colors.orange,
                  title: 'Cường độ sáng',
                  value: '${(garden.lightLux / 1000).toStringAsFixed(0)}k Lux',
                  status: 'Quang hợp tốt',
                  isWarning: false,
                ),
                _buildSensorCard(
                  icon: Icons.cloudy_snowing,
                  iconColor: Colors.teal,
                  title: 'Lượng mưa tức thời',
                  value: '${garden.rainfall} mm/h',
                  status: garden.rainfall > 0 ? 'Mưa rào nhẹ' : 'Không mưa',
                  isWarning: false,
                ),
                _buildSensorCard(
                  icon: Icons.battery_charging_full,
                  iconColor: const Color(0xFF2E7D32),
                  title: 'Trạm IoT Solar',
                  value: '${garden.battery}% Pin',
                  status: 'Kết nối 4G LTE Ổn định',
                  isWarning: false,
                ),
              ],
            ),
            const SizedBox(height: 22),

            // 3. AI Early Disease Warning & Prevention Protocols
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Color(0xFFC62828), size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Cảnh Báo Sớm Dịch Bệnh Vườn',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B2E25),
                        ),
                      ),
                      Text(
                        'Dự báo nguy cơ từ dữ liệu tương quan cảm biến',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // High Risk Disease Box
            _buildDiseaseWarningBox(
              riskTitle: '🔴 CẢNH BÁO MỨC CAO (${garden.highRiskScore}%)',
              diseaseName: garden.highRiskDisease,
              reason: garden.highRiskReason,
              actions: garden.highRiskActions,
              isHighRisk: true,
            ),
            const SizedBox(height: 14),

            // Medium Risk Disease Box
            _buildDiseaseWarningBox(
              riskTitle: '🟡 CẢNH BÁO MỨC TRUNG BÌNH (${garden.mediumRiskScore}%)',
              diseaseName: garden.mediumRiskDisease,
              reason: garden.mediumRiskReason,
              actions: garden.mediumRiskActions,
              isHighRisk: false,
            ),
            const SizedBox(height: 22),

            // 4. Remote Smart Irrigation Controls (Điều khiển van tưới tự động)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune, color: Color(0xFF2E7D32), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Điều Khiển Van Tưới Tự Động Từ Xa (IoT)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B2E25),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Zone A Valve
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Van tưới Khu A (Khu Cây Con)', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(_valveZoneA ? 'Đang mở (Áp lực 2.5 bar)' : 'Đang đóng', style: TextStyle(color: _valveZoneA ? const Color(0xFF2E7D32) : Colors.grey)),
                    value: _valveZoneA,
                    activeColor: const Color(0xFF2E7D32),
                    onChanged: (val) => setState(() => _valveZoneA = val),
                  ),
                  const Divider(height: 1),

                  // Zone B Valve
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Van tưới Khu B (Khu Nuôi Trái)', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(_valveZoneB ? 'Đang mở (Áp lực 3.0 bar)' : 'Đang đóng', style: TextStyle(color: _valveZoneB ? const Color(0xFF2E7D32) : Colors.grey)),
                    value: _valveZoneB,
                    activeColor: const Color(0xFF2E7D32),
                    onChanged: (val) => setState(() => _valveZoneB = val),
                  ),
                  const Divider(height: 1),

                  // Auto cutoff
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tự động ngắt khi ẩm độ đất > 75%', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Bảo vệ rễ chống úng nấm Phytophthora', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    value: _autoCutoffEnabled,
                    activeColor: const Color(0xFF2E7D32),
                    onChanged: (val) => setState(() => _autoCutoffEnabled = val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String status,
    required bool isWarning,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isWarning ? const Color(0xFFFFF8E1) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isWarning ? const Color(0xFFFFCA28) : Colors.grey.shade200,
          width: isWarning ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 22, color: iconColor),
              if (isWarning)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Cảnh báo',
                    style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2E25),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isWarning ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseWarningBox({
    required String riskTitle,
    required String diseaseName,
    required String reason,
    required List<String> actions,
    required bool isHighRisk,
  }) {
    final borderColor = isHighRisk ? const Color(0xFFEF9A9A) : const Color(0xFFFFE082);
    final bgColor = isHighRisk ? const Color(0xFFFFEBEE) : const Color(0xFFFFFDE7);
    final titleColor = isHighRisk ? const Color(0xFFC62828) : const Color(0xFFF57F17);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Risk Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                riskTitle,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const Icon(Icons.shield_outlined, size: 18, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 6),

          // Disease Name
          Text(
            diseaseName,
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2E25),
            ),
          ),
          const SizedBox(height: 8),

          // Detected Reason Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.psychology, size: 16, color: Color(0xFF1565C0)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Nguyên nhân AI phát hiện: $reason',
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF333333), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Prevention Protocol Steps
          const Row(
            children: [
              Icon(Icons.checklist, size: 16, color: Color(0xFF2E7D32)),
              SizedBox(width: 6),
              Text(
                'Biện pháp phòng ngừa sớm nhất:',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...actions.map((act) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, size: 15, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        act,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF2E2E2E), height: 1.3),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _GardenData {
  final String name;
  final String area;
  final String stationId;
  final double temp;
  final double humidity;
  final double soilMoisture;
  final double soilPh;
  final double ec;
  final double lightLux;
  final double rainfall;
  final int battery;
  final String highRiskDisease;
  final int highRiskScore;
  final String highRiskReason;
  final List<String> highRiskActions;
  final String mediumRiskDisease;
  final int mediumRiskScore;
  final String mediumRiskReason;
  final List<String> mediumRiskActions;

  const _GardenData({
    required this.name,
    required this.area,
    required this.stationId,
    required this.temp,
    required this.humidity,
    required this.soilMoisture,
    required this.soilPh,
    required this.ec,
    required this.lightLux,
    required this.rainfall,
    required this.battery,
    required this.highRiskDisease,
    required this.highRiskScore,
    required this.highRiskReason,
    required this.highRiskActions,
    required this.mediumRiskDisease,
    required this.mediumRiskScore,
    required this.mediumRiskReason,
    required this.mediumRiskActions,
  });
}
