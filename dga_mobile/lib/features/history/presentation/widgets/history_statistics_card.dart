import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/entities/history_entities.dart';

class HistoryStatisticsCard extends StatelessWidget {
  final List<HistoryLogEntity> logs;

  const HistoryStatisticsCard({
    super.key,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = logs.length;
    final healthy = logs.where((l) => l.diseaseName.contains('Không phát hiện') || l.diseaseName.toLowerCase().contains('khỏe mạnh')).length;
    final diseased = total - healthy;
    final rate = total > 0 ? (diseased / total * 100).toStringAsFixed(1) : '0.0';

    return AppCard(
      backgroundColor: theme.colorScheme.primary.withAlpha(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: theme.colorScheme.primary, size: 22),
              AppSpacing.h8,
              Text(
                'Thống kê lịch sử',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          AppSpacing.v16,
          Row(
            children: [
              Expanded(child: _buildStatItem(context, label: AppStrings.totalScans, value: '$total', color: theme.colorScheme.primary)),
              Expanded(child: _buildStatItem(context, label: AppStrings.filterHealthy, value: '$healthy', color: AppColors.success)),
              Expanded(child: _buildStatItem(context, label: AppStrings.filterDiseased, value: '$diseased', color: AppColors.warning)),
              Expanded(child: _buildStatItem(context, label: AppStrings.diseaseRate, value: '$rate%', color: AppColors.warning)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        AppSpacing.v4,
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(140),
          ),
        ),
      ],
    );
  }
}
