import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/dashboard_entities.dart';

class AIFarmStatusCard extends StatelessWidget {
  final FarmStatusEntity status;

  const AIFarmStatusCard({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final healthRate = status.totalTrees > 0
        ? ((status.healthyTrees / status.totalTrees) * 100).toStringAsFixed(1)
        : '0.0';

    return AppCard(
      backgroundColor: theme.colorScheme.primary.withAlpha(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.spa_outlined, color: theme.colorScheme.primary, size: 22),
              AppSpacing.h8,
              Text(
                AppStrings.aiFarmStatus,
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
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.healthRate,
                      style: theme.textTheme.labelMedium,
                    ),
                    AppSpacing.v4,
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$healthRate%',
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusIndicator(
                      context,
                      label: AppStrings.totalTrees,
                      value: '${status.totalTrees} cây',
                      color: theme.colorScheme.onSurface,
                    ),
                    AppSpacing.v8,
                    _buildStatusIndicator(
                      context,
                      label: AppStrings.diseasedTrees,
                      value: '${status.diseasedTrees} cây',
                      color: AppColors.error,
                    ),
                    AppSpacing.v8,
                    _buildStatusIndicator(
                      context,
                      label: AppStrings.highRiskTrees,
                      value: '${status.highRiskTrees} cây',
                      color: AppColors.warning,
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.v16,
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: status.totalTrees > 0 ? status.healthyTrees / status.totalTrees : 0.0,
              minHeight: 6,
              backgroundColor: AppColors.error.withAlpha(50),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            AppSpacing.h8,
            Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
