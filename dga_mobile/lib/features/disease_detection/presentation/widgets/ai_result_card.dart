import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/entities/disease_detection_entities.dart';

class AIResultCard extends StatelessWidget {
  final DetectionResultEntity result;

  const AIResultCard({
    super.key,
    required this.result,
  });

  Color _getSeverityColor() {
    switch (result.severity) {
      case 'Nhẹ':
        return AppColors.success;
      case 'Trung bình':
        return AppColors.warning;
      case 'Nặng':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severityColor = _getSeverityColor();
    final confidencePercent = (result.confidence * 100).toStringAsFixed(1);

    return AppCard(
      backgroundColor: theme.colorScheme.primary.withAlpha(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology, color: theme.colorScheme.primary, size: 24),
                  AppSpacing.h8,
                  Text(
                    AppStrings.aiPrediction,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              // Severity Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: severityColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: severityColor.withAlpha(50)),
                ),
                child: Text(
                  '${AppStrings.levelLabel}: ${result.severity}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: severityColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.v16,
          Text(
            result.diseaseName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          AppSpacing.v16,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppStrings.confidence}:',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '$confidencePercent%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: severityColor,
                ),
              ),
            ],
          ),
          AppSpacing.v8,
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: result.confidence,
              minHeight: 8,
              backgroundColor: theme.brightness == Brightness.light
                  ? AppColors.lightBorder
                  : AppColors.darkBorder,
              valueColor: AlwaysStoppedAnimation<Color>(severityColor),
            ),
          ),
        ],
      ),
    );
  }
}
