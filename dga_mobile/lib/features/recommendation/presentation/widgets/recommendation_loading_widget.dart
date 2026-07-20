import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/skeleton_loading.dart';
import '../../../../shared/widgets/app_card.dart';

class RecommendationLoadingWidget extends StatelessWidget {
  const RecommendationLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppSpacing.v16,
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(strokeWidth: 4),
              ),
              AppSpacing.v24,
              Text(
                AppStrings.generatingRecommendations,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              AppSpacing.v16,
              const LinearProgressIndicator(minHeight: 6),
              AppSpacing.v16,
            ],
          ),
        ),
        AppSpacing.v20,
        SkeletonLoading.card(height: 140),
        AppSpacing.v16,
        SkeletonLoading.card(height: 120),
        AppSpacing.v16,
        SkeletonLoading.text(width: 180),
        AppSpacing.v8,
        SkeletonLoading.text(),
        AppSpacing.v8,
        SkeletonLoading.text(),
      ],
    );
  }
}
