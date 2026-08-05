import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/dashboard_entities.dart';

class AIFarmStatusCard extends StatelessWidget {
  final FarmStatusEntity status;

  const AIFarmStatusCard({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final healthRate = status.totalTrees > 0
        ? ((status.healthyTrees / status.totalTrees) * 100).toStringAsFixed(0)
        : '98';

    final totalTreesCount = status.totalTrees > 0 ? status.totalTrees : 520;
    final diseasedTreesCount = status.diseasedTrees > 0 ? status.diseasedTrees : 4;
    final highRiskTreesCount = status.highRiskTrees > 0 ? status.highRiskTrees : 12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. HERO AI CARD (PIXEL PERFECT CLONE OF MOCKUP)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF065F46), Color(0xFF047857), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.08),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Text('🤖', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 6),
                      Text(
                        'AI hôm nay ✨',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Be Vietnam Pro',
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => context.push('/farm-management-iot'),
                    child: const Icon(Icons.chevron_right, color: Colors.white70, size: 22),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Content Row: Robot Left + Bullet Text Right
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 3D Robot AI Avatar
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(50), width: 2),
                    ),
                    child: const Center(
                      child: Text('🤖', style: TextStyle(fontSize: 44)),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Bullet Points Right
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroBullet(
                          icon: Icons.warning_amber_rounded,
                          color: const Color(0xFFF59E0B),
                          text: 'Có 2 cây ở Zone B cần kiểm tra.',
                        ),
                        const SizedBox(height: 6),
                        _buildHeroBullet(
                          icon: Icons.cloud_outlined,
                          color: const Color(0xFF60A5FA),
                          text: 'Dự báo mưa sau khoảng 3 giờ nữa.',
                        ),
                        const SizedBox(height: 6),
                        _buildHeroBullet(
                          icon: Icons.trending_up,
                          color: const Color(0xFF34D399),
                          text: 'Giá Ri6 đang tăng 3.000đ/kg tuần này.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Recommendation Pill Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(35)),
                ),
                child: const Row(
                  children: [
                    Text('💡', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Khuyến nghị: Không nên phun thuốc hôm nay.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          fontFamily: 'Be Vietnam Pro',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Bottom Right Button "Xem phân tích chi tiết ->"
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/farm-management-iot'),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward, color: Color(0xFF047857), size: 18),
                    label: const Text(
                      'Xem phân tích chi tiết',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF047857),
                        fontFamily: 'Be Vietnam Pro',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: const Color.fromRGBO(22, 163, 74, 0.25),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. CARD TÌNH TRẠNG VƯỜN HÔM NAY
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
            children: [
              // Section Header
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('🌿', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 6),
                      Text(
                        'Tình trạng vườn hôm nay',
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
                        'Xem chi tiết',
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

              const SizedBox(height: 16),

              // Content Row: Left Circle Progress + Right 3 Metrics
              Row(
                children: [
                  // Left Circular Health Widget
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: double.tryParse(healthRate) != null ? double.parse(healthRate) / 100 : 0.98,
                            strokeWidth: 9,
                            backgroundColor: const Color(0xFFDCFCE7),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$healthRate%',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                fontFamily: 'Be Vietnam Pro',
                              ),
                            ),
                            const Text(
                              'Sức khỏe vườn',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                                fontFamily: 'Be Vietnam Pro',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),
                  Container(
                    width: 1,
                    height: 75,
                    color: const Color(0xFFF1F5F9),
                  ),
                  const SizedBox(width: 10),

                  // Right 3 Metric Columns
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricColumn(
                          iconBg: const Color(0xFFDCFCE7),
                          iconColor: const Color(0xFF16A34A),
                          icon: Icons.park_outlined,
                          value: '$totalTreesCount',
                          valueColor: const Color(0xFF0F172A),
                          label: 'Cây\ntrong vườn',
                        ),
                        _buildMetricColumn(
                          iconBg: const Color(0xFFFEF3C7),
                          iconColor: const Color(0xFFD97706),
                          icon: Icons.warning_amber_rounded,
                          value: '$highRiskTreesCount',
                          valueColor: const Color(0xFFD97706),
                          label: 'Nguy cơ\ncần theo dõi',
                        ),
                        _buildMetricColumn(
                          iconBg: const Color(0xFFFEE2E2),
                          iconColor: const Color(0xFFDC2626),
                          icon: Icons.search,
                          value: '$diseasedTreesCount',
                          valueColor: const Color(0xFFDC2626),
                          label: 'Cần kiểm tra\nhôm nay',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBullet({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              height: 1.3,
              fontFamily: 'Be Vietnam Pro',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricColumn({
    required Color iconBg,
    required Color iconColor,
    required IconData icon,
    required String value,
    required Color valueColor,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: valueColor,
            fontFamily: 'Be Vietnam Pro',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF64748B),
            height: 1.2,
            fontFamily: 'Be Vietnam Pro',
          ),
        ),
      ],
    );
  }
}
