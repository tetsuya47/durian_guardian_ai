import 'package:flutter/material.dart';
import '../../domain/entities/history_entities.dart';

class HistoryStatisticsCard extends StatelessWidget {
  final List<HistoryLogEntity> logs;

  const HistoryStatisticsCard({
    super.key,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    final total = logs.length;
    final healthy = logs
        .where((l) => l.diseaseName.contains('Không phát hiện') || l.diseaseName.toLowerCase().contains('khỏe mạnh'))
        .length;
    final diseased = total > healthy ? (total - healthy) : 0;
    final rate = total > 0 ? ((diseased / total) * 100).toStringAsFixed(0) : '0';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.bar_chart_rounded,
                    color: Color(0xFF1E8E4A),
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Thống kê lịch sử',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF9CA3AF),
                    size: 16,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                ),
                child: const Row(
                  children: [
                    Text(
                      '7 ngày qua',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Color(0xFF6B7280),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Stat items row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Stat 1: Tổng lượt quét
              _buildStatItem(
                value: '$total',
                label: 'Tổng lượt quét',
                color: const Color(0xFF1E8E4A),
                bgColor: const Color(0xFFE8F5ED),
                icon: Icons.eco_rounded,
              ),
              _buildDivider(),

              // Stat 2: Khỏe mạnh
              _buildStatItem(
                value: '$healthy',
                label: 'Khỏe mạnh',
                color: const Color(0xFF1E8E4A),
                bgColor: const Color(0xFFE8F5ED),
                icon: Icons.shield_rounded,
              ),
              _buildDivider(),

              // Stat 3: Có bệnh
              _buildStatItem(
                value: '$diseased',
                label: 'Có bệnh',
                color: const Color(0xFFD97706),
                bgColor: const Color(0xFFFEF3C7),
                icon: Icons.bug_report_rounded,
              ),
              _buildDivider(),

              // Stat 4: Tỷ lệ bệnh
              _buildStatItem(
                value: '$rate%',
                label: 'Tỷ lệ bệnh',
                color: const Color(0xFFDC2626),
                bgColor: const Color(0xFFFEE2E2),
                icon: Icons.access_time_filled_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 48,
      color: const Color(0xFFF3F4F6),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11.5,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}
