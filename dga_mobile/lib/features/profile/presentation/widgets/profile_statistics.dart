import 'package:flutter/material.dart';
import '../../domain/entities/profile_entities.dart';

class ProfileStatistics extends StatelessWidget {
  final ProfileStatsEntity stats;

  const ProfileStatistics({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Item 1: Tổng lượt quét
          Expanded(
            child: _buildColumnItem(
              icon: Icons.qr_code_scanner_rounded,
              iconColor: const Color(0xFF1E8E4A),
              iconBgColor: const Color(0xFFE8F5ED),
              value: '${stats.totalInspections}',
              valueColor: const Color(0xFF1E8E4A),
              label: 'Tổng lượt quét',
            ),
          ),
          _buildDivider(),

          // Item 2: Lần phát hiện bệnh
          Expanded(
            child: _buildColumnItem(
              icon: Icons.bug_report_rounded,
              iconColor: const Color(0xFFDC2626),
              iconBgColor: const Color(0xFFFEE2E2),
              value: '${stats.detectedDiseases}',
              valueColor: const Color(0xFFDC2626),
              label: 'Lần phát hiện\nbệnh',
            ),
          ),
          _buildDivider(),

          // Item 3: Khuyến nghị đã xem
          Expanded(
            child: _buildColumnItem(
              icon: Icons.lightbulb_outline_rounded,
              iconColor: const Color(0xFFD97706),
              iconBgColor: const Color(0xFFFEF3C7),
              value: '${stats.viewedRecommendations}',
              valueColor: const Color(0xFFD97706),
              label: 'Khuyến nghị\nđã xem',
            ),
          ),
          _buildDivider(),

          // Item 4: Tỷ lệ cây khỏe
          Expanded(
            child: _buildColumnItem(
              icon: Icons.eco_rounded,
              iconColor: const Color(0xFF1E8E4A),
              iconBgColor: const Color(0xFFE8F5ED),
              value: '${stats.healthyTreeRate.toStringAsFixed(1)}%',
              valueColor: const Color(0xFF1E8E4A),
              label: 'Tỷ lệ cây khỏe',
            ),
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

  Widget _buildColumnItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String value,
    required Color valueColor,
    required String label,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11.5,
            color: Color(0xFF6B7280),
            height: 1.25,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
