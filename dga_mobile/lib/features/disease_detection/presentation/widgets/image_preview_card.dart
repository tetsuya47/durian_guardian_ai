import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/entities/disease_detection_entities.dart';

class ImagePreviewCard extends StatefulWidget {
  final ImageInfoEntity imageInfo;

  const ImagePreviewCard({
    super.key,
    required this.imageInfo,
  });

  @override
  State<ImagePreviewCard> createState() => _ImagePreviewCardState();
}

class _ImagePreviewCardState extends State<ImagePreviewCard> {
  bool _showExplainability = false;

  Widget _buildImage(String url, { BoxFit fit = BoxFit.cover, double? height, double? width}) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        height: height,
        width: width,
        placeholder: (context, url) => Container(
          height: height ?? 220,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(20),
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          height: height ?? 220,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(20),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('Không thể tải ảnh', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }
    final file = File(url);
    return Image.file(
      file,
      fit: fit,
      height: height,
      width: width,
      errorBuilder: (context, error, stackTrace) => Container(
        height: height ?? 220,
        color: Theme.of(context).colorScheme.onSurface.withAlpha(20),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('Không thể đọc ảnh', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasOverlay = widget.imageInfo.overlayUrl != null && widget.imageInfo.overlayUrl!.isNotEmpty;

    final activeUrl = (_showExplainability && hasOverlay)
        ? widget.imageInfo.overlayUrl!
        : widget.imageInfo.imageUrl;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hình ảnh phân tích',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasOverlay)
                Row(
                  children: [
                    Text(
                      'Bản đồ chú ý (AI Heatmap)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _showExplainability ? theme.colorScheme.primary : theme.colorScheme.onSurface.withAlpha(120),
                      ),
                    ),
                    AppSpacing.h4,
                    Switch(
                      value: _showExplainability,
                      onChanged: (val) {
                        setState(() {
                          _showExplainability = val;
                        });
                      },
                    ),
                  ],
                ),
            ],
          ),
          AppSpacing.v12,
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImage(activeUrl, height: 220, width: double.infinity),
          ),
          AppSpacing.v12,
          _buildMetaRow(context, label: AppStrings.fileNameLabel, value: widget.imageInfo.fileName),
          AppSpacing.v4,
          _buildMetaRow(context, label: AppStrings.fileSizeLabel, value: widget.imageInfo.fileSize),
          AppSpacing.v4,
          _buildMetaRow(context, label: AppStrings.fileDimensionLabel, value: widget.imageInfo.dimensions),
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
          style: theme.textTheme.bodySmall,
        ),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
