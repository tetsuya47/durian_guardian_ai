import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/entities/disease_detection_entities.dart';

class ImageMetadataCard extends StatelessWidget {
  final ImageInfoEntity imageInfo;
  final String scanDate;

  const ImageMetadataCard({
    super.key,
    required this.imageInfo,
    required this.scanDate,
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
              Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 22),
              AppSpacing.h8,
              Text(
                AppStrings.imageInfoLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          AppSpacing.v16,
          _buildMetaRow(context, label: AppStrings.fileNameLabel, value: imageInfo.fileName),
          const Divider(height: AppSpacing.lg),
          _buildMetaRow(context, label: AppStrings.fileSizeLabel, value: imageInfo.fileSize),
          const Divider(height: AppSpacing.lg),
          _buildMetaRow(context, label: AppStrings.fileDimensionLabel, value: imageInfo.dimensions),
          const Divider(height: AppSpacing.lg),
          _buildMetaRow(context, label: AppStrings.scannedDateLabel, value: scanDate),
          const Divider(height: AppSpacing.lg),
          _buildMetaRow(context, label: AppStrings.deviceLabel, value: imageInfo.device),
        ],
      ),
    );
  }

  Widget _buildMetaRow(BuildContext context, {required String label, required String value}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(150),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
