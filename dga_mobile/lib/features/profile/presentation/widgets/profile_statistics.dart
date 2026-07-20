import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/entities/profile_entities.dart';

class ProfileStatistics extends StatelessWidget {
  final ProfileStatsEntity stats;

  const ProfileStatistics({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.8,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      children: [
        _buildStatCard(
          context,
          icon: Icons.qr_code_scanner,
          label: AppStrings.totalInspectionsStat,
          value: '${stats.totalInspections}',
          color: theme.colorScheme.primary,
        ),
        _buildStatCard(
          context,
          icon: Icons.bug_report_outlined,
          label: AppStrings.detectedDiseasesStat,
          value: '${stats.detectedDiseases}',
          color: AppColors.error,
        ),
        _buildStatCard(
          context,
          icon: Icons.lightbulb_outline,
          label: AppStrings.viewedRecommendationsStat,
          value: '${stats.viewedRecommendations}',
          color: AppColors.warning,
        ),
        _buildStatCard(
          context,
          icon: Icons.spa_outlined,
          label: AppStrings.healthyTreeRateStat,
          value: '${stats.healthyTreeRate.toStringAsFixed(1)}%',
          color: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: theme.colorScheme.onSurface.withAlpha(8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withAlpha(20),
            child: Icon(icon, color: color, size: 20),
          ),
          AppSpacing.h8,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(140),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
