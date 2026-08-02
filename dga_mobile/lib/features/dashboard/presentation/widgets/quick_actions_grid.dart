import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/feature_tile.dart';
import '../../../../core/theme/app_spacing.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FeatureTile(
                icon: Icons.camera_alt_outlined,
                title: AppStrings.scanLeafAction,
                description: AppStrings.scanLeafDesc,
                onTap: () => context.go('/disease-detection'),
              ),
            ),
            AppSpacing.h12,
            Expanded(
              child: FeatureTile(
                icon: Icons.star_border,
                title: AppStrings.recommendationAction,
                description: AppStrings.recommendationDesc,
                onTap: () => context.go('/recommendation'),
              ),
            ),
          ],
        ),
        AppSpacing.v12,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FeatureTile(
                icon: Icons.history_outlined,
                title: AppStrings.historyAction,
                description: AppStrings.historyDesc,
                onTap: () => context.go('/history'),
              ),
            ),
            AppSpacing.h12,
            Expanded(
              child: FeatureTile(
                icon: Icons.person_outline,
                title: AppStrings.profileAction,
                description: AppStrings.profileDesc,
                onTap: () => context.go('/profile'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
