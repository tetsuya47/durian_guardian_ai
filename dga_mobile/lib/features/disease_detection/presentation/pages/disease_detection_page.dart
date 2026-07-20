import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/utils/ui_helpers.dart';
import '../../domain/entities/disease_detection_entities.dart';
import '../providers/disease_detection_providers.dart';
import '../widgets/action_buttons.dart';
import '../widgets/ai_result_card.dart';
import '../widgets/analysis_loading_widget.dart';
import '../widgets/disease_details_card.dart';
import '../widgets/image_metadata_card.dart';
import '../widgets/image_preview_card.dart';
import '../widgets/image_selector_buttons.dart';
import '../widgets/instructions_card.dart';
import '../widgets/quick_recommendations_card.dart';

class DiseaseDetectionPage extends ConsumerWidget {
  const DiseaseDetectionPage({super.key});

  Future<void> _openGallery(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (image == null) return;
      await _processAndNavigate(context, ref, image);
    } catch (e) {
      if (context.mounted) {
        AppSnackbars.showError(context, 'Không thể chọn ảnh. Vui lòng thử lại.');
      }
    }
  }

  Future<void> _processAndNavigate(BuildContext context, WidgetRef ref, XFile pickedFile) async {
    final file = File(pickedFile.path);
    if (!await file.exists()) {
      if (context.mounted) {
        AppSnackbars.showError(context, 'Không thể đọc tệp ảnh đã chọn.');
      }
      return;
    }

    final fileSize = await file.length();
    final fileName = p.basename(pickedFile.path);

    String dimensions = '';
    try {
      final decoded = await decodeImageFromList(await file.readAsBytes());
      dimensions = '${decoded.width}x${decoded.height}';
    } catch (_) {}

    String deviceInfo = 'Thiết bị hiện tại';
    if (pickedFile.path.contains('/data/')) {
      deviceInfo = 'Android Device';
    } else if (pickedFile.path.contains('/var/mobile/')) {
      deviceInfo = 'iOS Device';
    }

    final imageInfo = ImageInfoEntity(
      fileName: fileName,
      fileSize: _formatFileSize(fileSize),
      dimensions: dimensions.isNotEmpty ? dimensions : 'Không xác định',
      createdDate: _formatNow(),
      device: deviceInfo,
      imageUrl: pickedFile.path,
    );

    ref.read(selectedImageProvider.notifier).state = imageInfo;
    if (context.mounted) {
      context.push('/image-editor-wizard');
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatNow() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  void _startAnalysis(WidgetRef ref, ImageInfoEntity imageInfo) async {
    ref.read(detectionStateProvider.notifier).state = 'analyzing';
    ref.read(selectedImageProvider.notifier).state = imageInfo;
    ref.read(detectionErrorMessageProvider.notifier).state = null;

    try {
      final repo = ref.read(diseaseDetectionRepositoryProvider);
      final result = await repo.detectDisease(imageInfo);
      result.when(
        success: (data) {
          ref.read(detectionResultProvider.notifier).state = data;
          ref.read(detectionStateProvider.notifier).state = 'success';
        },
        failure: (msg, err) {
          ref.read(detectionErrorMessageProvider.notifier).state = msg;
          ref.read(detectionStateProvider.notifier).state = 'error';
        },
        loading: () {},
        empty: () {},
      );
    } catch (e) {
      ref.read(detectionErrorMessageProvider.notifier).state = 'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.';
      ref.read(detectionStateProvider.notifier).state = 'error';
    }
  }

  void _reset(WidgetRef ref) {
    ref.read(detectionStateProvider.notifier).state = 'idle';
    ref.read(selectedImageProvider.notifier).state = null;
    ref.read(detectionResultProvider.notifier).state = null;
    ref.read(detectionErrorMessageProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(detectionStateProvider);
    final selectedImage = ref.watch(selectedImageProvider);
    final result = ref.watch(detectionResultProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.diseaseDetection),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            onPressed: () => context.go('/history'),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildBodyByState(context, ref, state, selectedImage, result),
        ),
      ),
    );
  }

  Widget _buildBodyByState(
    BuildContext context,
    WidgetRef ref,
    String state,
    ImageInfoEntity? selectedImage,
    DetectionResultEntity? result,
  ) {
    final theme = Theme.of(context);

    if (state == 'analyzing') {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: AnalysisLoadingWidget(),
      );
    }

    if (state == 'error') {
      final errorMsg = ref.watch(detectionErrorMessageProvider);
      return Center(
        child: ErrorState(
          description: errorMsg ?? AppStrings.cannotReadImage,
          onRetry: () {
            if (selectedImage != null) {
              _startAnalysis(ref, selectedImage);
            } else {
              _reset(ref);
            }
          },
        ),
      );
    }

    if (state == 'success' && result != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ImagePreviewCard(imageInfo: result.imageInfo),
            AppSpacing.v16,
            AIResultCard(result: result),
            AppSpacing.v16,
            DiseaseDetailsCard(diseaseInfo: result.diseaseInfo),
            AppSpacing.v16,
            QuickRecommendationsCard(recommendations: result.diseaseInfo.quickRecommendations),
            AppSpacing.v16,
            ImageMetadataCard(imageInfo: result.imageInfo, scanDate: result.scanDate),
            AppSpacing.v24,
            ActionButtons(
              onReScan: () => _reset(ref),
              onSave: () {
                AppSnackbars.showInfo(context, 'Kết quả chẩn đoán đã hiển thị trên màn hình.');
              },
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const InstructionsCard(),
          AppSpacing.v24,
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  size: 80,
                  color: theme.colorScheme.onSurface.withAlpha(50),
                ),
                AppSpacing.v16,
                Text(
                  AppStrings.noImageForDetection,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(120),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.v40,
          ImageSelectorButtons(
            onCameraTap: () => context.push('/camera-simulator'),
            onGalleryTap: () => _openGallery(context, ref),
          ),
        ],
      ),
    );
  }
}
