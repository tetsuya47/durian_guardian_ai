import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text('⚡', style: TextStyle(fontSize: 18)),
            SizedBox(width: 6),
            Text(
              'Hành động hôm nay',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.25,
          children: [
            _buildQuickActionCard(
              context,
              icon: Icons.qr_code_scanner_outlined,
              iconColor: const Color(0xFF16A34A),
              bgColor: const Color(0xFFDCFCE7),
              title: 'Quét lá AI',
              subtitle: 'Chẩn đoán bệnh',
              onTap: () => context.go('/disease-detection'),
            ),
            _buildQuickActionCard(
              context,
              icon: Icons.assignment_outlined,
              iconColor: const Color(0xFF2563EB),
              bgColor: const Color(0xFFDBEAFE),
              title: 'Nhật ký',
              subtitle: 'Ghi chép canh tác',
              onTap: () => context.go('/history'),
            ),
            _buildQuickActionCard(
              context,
              icon: Icons.sensors_outlined,
              iconColor: const Color(0xFF9333EA),
              bgColor: const Color(0xFFF3E8FF),
              title: 'Cảm biến IoT',
              subtitle: 'Theo dõi vườn',
              onTap: () => context.push('/farm-management-iot'),
            ),
            _buildQuickActionCard(
              context,
              icon: Icons.forest_outlined,
              iconColor: const Color(0xFFEA580C),
              bgColor: const Color(0xFFFFEDD5),
              title: 'Quản lý vườn',
              subtitle: 'Sơ đồ & cây trồng',
              onTap: () => context.go('/register-farm'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
