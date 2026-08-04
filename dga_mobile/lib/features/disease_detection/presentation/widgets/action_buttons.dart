import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onReScan;

  const ActionButtons({
    super.key,
    required this.onReScan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Auto-save Status Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.green.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.withAlpha(60)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
              AppSpacing.h8,
              Text(
                'Đã tự động lưu kết quả vào lịch sử',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        AppSpacing.v16,
        // Re-Scan Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: onReScan,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text(
              'Chẩn đoán hình ảnh mới',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
