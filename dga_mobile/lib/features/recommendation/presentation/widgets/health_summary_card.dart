import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';

class HealthSummaryCard extends StatelessWidget {
  final String riskLevel;

  const HealthSummaryCard({
    super.key,
    required this.riskLevel,
  });

  Color _getRiskColor() {
    switch (riskLevel) {
      case 'Nguy cơ thấp':
        return AppColors.success;
      case 'Nguy cơ trung bình':
        return AppColors.warning;
      case 'Nguy cơ cao':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final riskColor = _getRiskColor();

    return AppCard(
      backgroundColor: theme.colorScheme.primary.withAlpha(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: theme.colorScheme.primary, size: 24),
              AppSpacing.h8,
              Text(
                AppStrings.healthSummaryTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          AppSpacing.v16,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppStrings.riskLevelLabel}:',
                style: theme.textTheme.bodyLarge,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: riskColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: riskColor.withAlpha(80), width: 1.5),
                ),
                child: Text(
                  riskLevel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: riskColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
