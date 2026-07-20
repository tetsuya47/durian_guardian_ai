import 'package:flutter/material.dart';
import 'app_card.dart';
import '../theme/app_colors.dart';
import '../styles/app_styles.dart';

class AIPredictionCard extends StatelessWidget {
  final String diseaseName;
  final double confidence; // Value between 0.0 and 1.0
  final String scanDate;
  final VoidCallback? onDetailsTap;

  const AIPredictionCard({
    super.key,
    required this.diseaseName,
    required this.confidence,
    required this.scanDate,
    this.onDetailsTap,
  });

  Color _getConfidenceColor() {
    if (confidence >= 0.8) return AppColors.success;
    if (confidence >= 0.5) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confidencePercent = (confidence * 100).toStringAsFixed(1);
    final confidenceColor = _getConfidenceColor();

    return AppCard(
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
                    'AI Chẩn Đoán',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Text(
                scanDate,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          AppSpacing.v12,
          Text(
            diseaseName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.v12,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Độ tin cậy:',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '$confidencePercent%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: confidenceColor,
                ),
              ),
            ],
          ),
          AppSpacing.v8,
          ClipRRect(
            borderRadius: AppRadius.borderSmall,
            child: LinearProgressIndicator(
              value: confidence,
              minHeight: 8,
              backgroundColor: theme.brightness == Brightness.light
                  ? AppColors.lightBorder
                  : AppColors.darkBorder,
              valueColor: AlwaysStoppedAnimation<Color>(confidenceColor),
            ),
          ),
          if (onDetailsTap != null) ...[
            AppSpacing.v12,
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onDetailsTap,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Xem chi tiết'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
