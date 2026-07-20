import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../authentication/domain/entities/auth_entities.dart';

class FarmInformationCard extends StatelessWidget {
  final FarmEntity farmInfo;

  const FarmInformationCard({
    super.key,
    required this.farmInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.agriculture_outlined, color: theme.colorScheme.primary, size: 22),
              AppSpacing.h8,
              Text(
                AppStrings.farmInfoTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          AppSpacing.v16,
          _buildInfoRow(context, label: AppStrings.farmNameLabel, value: farmInfo.farmName),
          const Divider(height: AppSpacing.lg),
          _buildInfoRow(context, label: AppStrings.farmCodeLabel, value: farmInfo.farmCode),
          const Divider(height: AppSpacing.lg),
          _buildInfoRow(context, label: AppStrings.addressLabel, value: farmInfo.address),
          const Divider(height: AppSpacing.lg),
          _buildInfoRow(context, label: AppStrings.treeCountLabel, value: '${farmInfo.treeCount} cây'),
          const Divider(height: AppSpacing.lg),
          _buildInfoRow(context, label: AppStrings.joinedDateLabel, value: farmInfo.joinedDate),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, {required String label, required String value}) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(140),
          ),
        ),
        AppSpacing.h16,
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
