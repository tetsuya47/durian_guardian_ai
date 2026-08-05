import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/url_resolver.dart';
import '../../domain/entities/history_entities.dart';

class HistoryDetailSheet extends StatelessWidget {
  final HistoryLogEntity log;

  const HistoryDetailSheet({
    super.key,
    required this.log,
  });

  Color _getSeverityColor() {
    switch (log.severity) {
      case 'Khỏe mạnh':
        return AppColors.success;
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
    final confidencePercent = (log.confidence * 100).toStringAsFixed(0);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withAlpha(40),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${AppStrings.detailScanTitle} (${log.id})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            AppSpacing.v16,
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildSmartImage(log.imageUrl, height: 200, width: double.infinity),
            ),
            AppSpacing.v16,
            Text(
              log.treeName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.v4,
            Row(
              children: [
                Expanded(
                  child: Text(
                    log.diseaseName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: severityColor,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: severityColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${AppStrings.confidence}: $confidencePercent%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: severityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xxl),
            // Weather conditions & inspector
            _buildInfoRow(context, label: AppStrings.scannedDateLabel, value: '${log.date} lúc ${log.time}'),
            AppSpacing.v12,
            _buildInfoRow(context, label: AppStrings.inspectorLabel, value: log.inspectorName),
            if (log.weather.temperature > 0 || log.weather.humidity > 0) ...[
              AppSpacing.v12,
              _buildInfoRow(
                context,
                label: AppStrings.weatherAtScan,
                value: '${log.weather.temperature.toStringAsFixed(1)}°C - ẩm ${log.weather.humidity.toStringAsFixed(0)}%',
              ),
            ],
            const Divider(height: AppSpacing.xxl),
            // Recommendations list
            Row(
              children: [
                Icon(Icons.assignment_turned_in_outlined, color: theme.colorScheme.primary, size: 20),
                AppSpacing.h8,
                Text(
                  AppStrings.quickRecommendations,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            AppSpacing.v12,
            ...log.recommendations.map(
              (rec) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, size: 18, color: theme.colorScheme.secondary),
                    AppSpacing.h12,
                    Expanded(
                      child: Text(
                        rec,
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.v24,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, {required String label, required String value}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(140),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSmartImage(String url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    final resolvedUrl = UrlResolver.resolve(url);
    if (resolvedUrl.isEmpty) {
      return _buildErrorWidget(width, height);
    }

    // 1. Asset Image
    if (resolvedUrl.startsWith('assets/')) {
      return Image.asset(
        resolvedUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(width, height),
      );
    }

    // 2. Local File
    if (resolvedUrl.startsWith('/') || resolvedUrl.startsWith('file:')) {
      final cleanPath = resolvedUrl.replaceFirst('file://', '');
      final file = File(cleanPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(width, height),
        );
      }
    }

    // 3. Network Image
    return CachedNetworkImage(
      imageUrl: resolvedUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey.withAlpha(30),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => _buildErrorWidget(width, height),
    );
  }

  Widget _buildErrorWidget(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
