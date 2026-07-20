import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/dashboard_entities.dart';

class DashboardAlertsCard extends StatelessWidget {
  final List<AlertEntity> alerts;

  const DashboardAlertsCard({super.key, required this.alerts});

  String _formatDate(String isoDate) {
    try {
      final parsed = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(parsed);
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayAlerts = alerts.length > 3 ? alerts.sublist(0, 3) : alerts;

    return AppCard(
      backgroundColor: AppColors.warning.withAlpha(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: AppColors.warning, size: 22),
              AppSpacing.h8,
              Text(
                'Cảnh báo gần đây',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
              const Spacer(),
              if (alerts.length > 3)
                Text(
                  '+${alerts.length - 3} nữa',
                  style: theme.textTheme.labelSmall?.copyWith(color: AppColors.warning),
                ),
            ],
          ),
          AppSpacing.v12,
          ...displayAlerts.map((alert) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.warning,
                  ),
                ),
                AppSpacing.h12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (alert.content.isNotEmpty) ...[
                        AppSpacing.v4,
                        Text(
                          alert.content,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(160),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      AppSpacing.v4,
                      Text(
                        _formatDate(alert.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(100),
                        ),
                      ),
                    ],
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
