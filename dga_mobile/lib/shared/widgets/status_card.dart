import 'package:flutter/material.dart';
import 'app_card.dart';
import '../theme/app_colors.dart';
import '../styles/app_styles.dart';

enum StatusType { success, warning, error, info }

class StatusCard extends StatelessWidget {
  final String title;
  final String description;
  final StatusType statusType;
  final IconData? icon;

  const StatusCard({
    super.key,
    required this.title,
    required this.description,
    this.statusType = StatusType.info,
    this.icon,
  });

  Color _getStatusColor(BuildContext context) {
    switch (statusType) {
      case StatusType.success:
        return AppColors.success;
      case StatusType.warning:
        return AppColors.warning;
      case StatusType.error:
        return AppColors.error;
      case StatusType.info:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getDefaultIcon() {
    switch (statusType) {
      case StatusType.success:
        return Icons.check_circle_outline;
      case StatusType.warning:
        return Icons.warning_amber_outlined;
      case StatusType.error:
        return Icons.error_outline;
      case StatusType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(context);
    final displayIcon = icon ?? _getDefaultIcon();

    return AppCard(
      backgroundColor: statusColor.withValues(alpha: 0.08),
      showBorder: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(displayIcon, color: statusColor, size: 24),
          AppSpacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                AppSpacing.v4,
                Text(
                  description,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
