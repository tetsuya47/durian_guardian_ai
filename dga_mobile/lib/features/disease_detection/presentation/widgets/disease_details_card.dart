import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/entities/disease_detection_entities.dart';

class DiseaseDetailsCard extends StatelessWidget {
  final DiseaseInfoEntity diseaseInfo;

  const DiseaseDetailsCard({
    super.key,
    required this.diseaseInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin chi tiết bệnh',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.v16,
          _buildInfoSection(
            context,
            icon: Icons.analytics_outlined,
            title: AppStrings.symptoms,
            content: diseaseInfo.symptoms,
          ),
          AppSpacing.v16,
          _buildInfoSection(
            context,
            icon: Icons.science_outlined,
            title: AppStrings.causes,
            content: diseaseInfo.causes,
          ),
          AppSpacing.v16,
          _buildInfoSection(
            context,
            icon: Icons.gavel_outlined,
            title: AppStrings.impactLevel,
            content: diseaseInfo.impactLevel,
          ),
          AppSpacing.v16,
          _buildInfoSection(
            context,
            icon: Icons.share_outlined,
            title: AppStrings.spreadMethod,
            content: diseaseInfo.spreadMethod,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        AppSpacing.h12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              AppSpacing.v4,
              Text(
                content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
