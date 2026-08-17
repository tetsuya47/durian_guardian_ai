import 'package:flutter/material.dart';

class VietplantSmartGardenCard extends StatelessWidget {
  final bool hasIoTDevices;
  final Map<String, dynamic>? telemetryData;
  final VoidCallback? onTap;
  final VoidCallback? onBuyIoT;
  final VoidCallback? onUpgradePackage;

  const VietplantSmartGardenCard({
    super.key,
    this.hasIoTDevices = false,
    this.telemetryData,
    this.onTap,
    this.onBuyIoT,
    this.onUpgradePackage,
  });

  @override
  Widget build(BuildContext context) {
    final bool isIoTActive = hasIoTDevices &&
        (telemetryData != null) &&
        (telemetryData!['has_iot'] == true ||
            (telemetryData!['telemetry'] is Map && (telemetryData!['telemetry'] as Map).isNotEmpty));

    if (!isIoTActive) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.sensors, color: Color(0xFF2E7D32), size: 20),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Quản lý vườn thông minh',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B2E25),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Empty State Container: No IoT equipment purchased yet
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sensors_off_rounded, color: Color(0xFF2E7D32), size: 36),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'Chưa có dữ liệu cảm biến IoT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B2E25),
                    ),
                  ),
                  const SizedBox(height: 6),

                  const Text(
                    'Vườn sầu riêng của bạn chưa kết nối trạm cảm biến IoT. Hãy mua sắm thiết bị IoT và đăng ký gói dịch vụ để kích hoạt giám sát vi khí hậu thời gian thực.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF666666), height: 1.35),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onBuyIoT,
                          icon: const Icon(Icons.shopping_cart_outlined, size: 16, color: Colors.white),
                          label: const Text(
                            'Mua Thiết Bị IoT',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onUpgradePackage,
                          icon: const Icon(Icons.workspace_premium_outlined, size: 16, color: Color(0xFF2E7D32)),
                          label: const Text(
                            'Mua Gói Dịch Vụ',
                            style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final telemetry = (telemetryData?['telemetry'] as Map?) ?? {};
    final farmName = (telemetry['farm_name'] ?? telemetryData?['farm_name'] ?? 'Vườn Sầu Riêng').toString();
    final temp = (telemetry['temperature'] ?? telemetryData?['temperature_celsius'] ?? telemetryData?['temperature'])?.toString() ?? '--';
    final soilMoisture = (telemetry['soil_moisture'] ?? telemetryData?['soil_moisture_percent'] ?? telemetryData?['soil_moisture'])?.toString() ?? '--';
    final airHumidity = (telemetry['humidity'] ?? telemetryData?['humidity_percent'] ?? telemetryData?['humidity'])?.toString() ?? '--';
    final soilPh = (telemetry['soil_ph'] ?? telemetryData?['soil_ph'])?.toString() ?? '--';
    final riskPercent = telemetryData?['model3_risk_score'] != null
        ? ((telemetryData!['model3_risk_score'] as num) * 100).toInt()
        : (telemetryData?['phytophthora_risk_percent'] ?? 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Row (Protected from overflow)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.sensors, color: Color(0xFF2E7D32), size: 20),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Quản lý vườn thông minh',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B2E25),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onTap,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Chi tiết',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: Color(0xFF2E7D32)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Main Card Container with Telemetry Data
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
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
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Garden Header & Station Live Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.yard, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                farmName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
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
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fiber_manual_record, color: Color(0xFF69F0AE), size: 8),
                            SizedBox(width: 4),
                            Text(
                              'Trạm IoT Trực Tiếp',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 4 Main Sensor Metrics Grid
                  Row(
                    children: [
                      _buildMetricTile('🌡️ Nhiệt độ', '$temp°C', 'Ổn định'),
                      const SizedBox(width: 6),
                      _buildMetricTile('💧 Ẩm độ đất', '$soilMoisture%', (num.tryParse(soilMoisture.toString()) ?? 0) > 75 ? 'Cao ⚠️' : 'Ổn định'),
                      const SizedBox(width: 6),
                      _buildMetricTile('💨 Ẩm không khí', '$airHumidity%', 'Ẩm ướt'),
                      const SizedBox(width: 6),
                      _buildMetricTile('🧪 Độ pH đất', '$soilPh pH', 'Chuẩn'),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // AI Early Warning Alert Banner
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFB74D)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CẢNH BÁO SỚM: Nguy cơ nấm xì mủ Phytophthora ($riskPercent%)',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB71C1C),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Ẩm đất $soilMoisture% liên tục 48h. Chạm để xem cách phòng chống ngay >',
                                style: const TextStyle(fontSize: 10.5, color: Color(0xFFE65100)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, String status) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 1),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                status,
                style: TextStyle(
                  color: status.contains('⚠️') ? const Color(0xFFFFD54F) : const Color(0xFFB9F6CA),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
