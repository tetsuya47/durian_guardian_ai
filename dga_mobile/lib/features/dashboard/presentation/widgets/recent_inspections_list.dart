import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/dashboard_entities.dart';

class RecentInspectionsList extends StatelessWidget {
  final List<InspectionItemEntity> inspections;

  const RecentInspectionsList({
    super.key,
    required this.inspections,
  });

  String _getItemStatus(InspectionItemEntity item) {
    if (item.diseaseName.contains('Không phát hiện') || item.diseaseName.contains('khỏe mạnh')) {
      return 'Healthy';
    } else if (item.confidence < 0.8) {
      return 'Warning';
    } else {
      return 'Danger';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Healthy':
        return AppColors.success;
      case 'Warning':
        return AppColors.warning;
      case 'Danger':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Healthy':
        return AppStrings.safe;
      case 'Warning':
        return AppStrings.warningStatus;
      case 'Danger':
        return AppStrings.dangerStatus;
      default:
        return AppStrings.scanningStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: inspections.length,
      itemBuilder: (context, index) {
        final item = inspections[index];
        final status = _getItemStatus(item);
        final statusColor = _getStatusColor(status);
        final statusText = _getStatusText(status);
        final confidencePercent = (item.confidence * 100).toStringAsFixed(0);

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: theme.brightness == Brightness.light
                          ? AppColors.lightBorder.withAlpha(50)
                          : AppColors.darkBorder.withAlpha(50),
                      child: const Center(
                        child: SizedBox(
                           width: 20,
                           height: 20,
                           child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.primary.withAlpha(30),
                      child: const Icon(Icons.image_not_supported_outlined, size: 24),
                    ),
                  ),
                ),
                AppSpacing.h16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.diseaseName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AppSpacing.v4,
                      Row(
                        children: [
                          Text(
                            '${AppStrings.confidence}: ',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            '$confidencePercent%',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.v4,
                      Text(
                        '${item.date} ${item.time}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                AppSpacing.h12,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withAlpha(50)),
                  ),
                  child: Text(
                    statusText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
