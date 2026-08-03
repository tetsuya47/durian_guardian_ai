import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/feature_tile.dart';
import '../../../../core/theme/app_spacing.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Register Farm & IoT Shop
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FeatureTile(
                icon: Icons.add_business_outlined,
                title: 'Đăng Ký Vườn Mới',
                description: 'Kích hoạt trang trại sầu riêng để dùng AI',
                onTap: () => context.go('/register-farm'),
              ),
            ),
            AppSpacing.h12,
            Expanded(
              child: FeatureTile(
                icon: Icons.shopping_cart_outlined,
                title: 'Mua Sắm IoT',
                description: 'Cửa hàng thiết bị & quản lý đơn hàng',
                onTap: () => context.go('/iot-shop'),
              ),
            ),
          ],
        ),
        AppSpacing.v12,

        // Row 2: IoT Management & AI Scan Leaf
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FeatureTile(
                icon: Icons.memory_outlined,
                title: 'Quản Lý IoT',
                description: 'Giám sát cảm biến & kết nối thiết bị',
                onTap: () => context.go('/iot-management'),
              ),
            ),
            AppSpacing.h12,
            Expanded(
              child: FeatureTile(
                icon: Icons.camera_alt_outlined,
                title: 'Quét Lá AI',
                description: 'Chẩn đoán sâu bệnh từ hình ảnh lá',
                onTap: () => context.go('/disease-detection'),
              ),
            ),
          ],
        ),
        AppSpacing.v12,

        // Row 3: Recommendations & History
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FeatureTile(
                icon: Icons.lightbulb_outline,
                title: 'Khuyến Nghị AI',
                description: 'Giải pháp chăm sóc & điều trị',
                onTap: () => context.go('/recommendation'),
              ),
            ),
            AppSpacing.h12,
            Expanded(
              child: FeatureTile(
                icon: Icons.history_outlined,
                title: 'Lịch Sử Kiểm Tra',
                description: 'Xem lại nhật ký chẩn đoán',
                onTap: () => context.go('/history'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
