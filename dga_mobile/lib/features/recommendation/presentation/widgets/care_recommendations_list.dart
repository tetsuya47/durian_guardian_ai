import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/entities/recommendation_entities.dart';

class CareRecommendationsList extends StatelessWidget {
  final List<CareRecommendationEntity> recommendations;

  const CareRecommendationsList({
    super.key,
    required this.recommendations,
  });

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Khẩn cấp':
        return AppColors.error;
      case 'Cao':
        return AppColors.warning;
      case 'Trung bình':
        return AppColors.primary;
      case 'Thấp':
        return AppColors.success;
      default:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_outlined, color: theme.colorScheme.primary, size: 22),
              AppSpacing.h8,
              Text(
                AppStrings.careRecommendations,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          AppSpacing.v16,
          ...recommendations.map(
            (rec) {
              final priorityColor = _getPriorityColor(rec.priority);

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            rec.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: priorityColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: priorityColor.withAlpha(50)),
                          ),
                          child: Text(
                            'Ưu tiên: ${rec.priority}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: priorityColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.v4,
                    Text(
                      rec.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(180),
                        height: 1.4,
                      ),
                    ),
                    AppSpacing.v8,
                    const Divider(height: 1),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
