import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/ui_helpers.dart';
import '../../domain/entities/disease_detection_entities.dart';
import '../providers/disease_detection_providers.dart';
import '../widgets/action_buttons.dart';
import '../widgets/ai_result_card.dart';
import '../widgets/analysis_loading_widget.dart';
import '../widgets/disease_details_card.dart';
import '../widgets/empty_state_illustration.dart';
import '../widgets/image_metadata_card.dart';
import '../widgets/image_preview_card.dart';
import '../widgets/image_selector_buttons.dart';
import '../widgets/instructions_card.dart';
import '../widgets/photo_tips_card.dart';
import '../widgets/quick_recommendations_card.dart';
import '../../../history/presentation/providers/history_providers.dart';

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
      if (!context.mounted) return;
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

  void _startAnalysis(BuildContext context, WidgetRef ref, ImageInfoEntity imageInfo) async {
    final container = ProviderScope.containerOf(context);
    container.read(detectionStateProvider.notifier).state = 'analyzing';
    container.read(selectedImageProvider.notifier).state = imageInfo;
    container.read(detectionErrorMessageProvider.notifier).state = null;

    try {
      final repo = container.read(diseaseDetectionRepositoryProvider);
      final result = await repo.detectDisease(imageInfo);
      result.when(
        success: (data) {
          container.read(detectionResultProvider.notifier).state = data;
          container.read(detectionStateProvider.notifier).state = 'success';
          container.invalidate(historyRawLogsProvider);
        },
        failure: (msg, err) {
          container.read(detectionErrorMessageProvider.notifier).state = msg;
          container.read(detectionStateProvider.notifier).state = 'error';
        },
        loading: () {},
        empty: () {},
      );
    } catch (e) {
      container.read(detectionErrorMessageProvider.notifier).state = 'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.';
      container.read(detectionStateProvider.notifier).state = 'error';
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
      backgroundColor: const Color(0xFF0F8A4C),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/dashboard');
                      }
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'Chẩn đoán bệnh',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.history_outlined, color: Colors.white, size: 24),
                    onPressed: () {
                      ref.invalidate(historyRawLogsProvider);
                      context.go('/history');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // White Content Card
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildBodyByState(context, ref, state, selectedImage, result),
                  ),
                ),
              ),
            ),
          ],
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
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 72,
                color: Colors.redAccent,
              ),
              AppSpacing.v16,
              Text(
                'Không thể phân tích ảnh',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              AppSpacing.v8,
              Text(
                errorMsg ?? AppStrings.cannotReadImage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              AppSpacing.v24,
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _reset(ref);
                    context.push('/camera-simulator');
                  },
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Chụp ảnh lại (Máy ảnh)', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              AppSpacing.v12,
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _reset(ref);
                    _openGallery(context, ref);
                  },
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Chọn ảnh mới từ thư viện', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              AppSpacing.v12,
              if (selectedImage != null)
                TextButton.icon(
                  onPressed: () {
                    _startAnalysis(context, ref, selectedImage);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử chẩn đoán lại ảnh này'),
                ),
            ],
          ),
        ),
      );
    }

    if (state == 'success' && result != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
            ),
          ],
        ),
      );
    }

    // Default Idle State - Matches screenshot 100% pixel perfect
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Section 1: Instructions Card
          const InstructionsCard(),
          const SizedBox(height: 28),

          // Section 2: Empty State Illustration & Text
          const EmptyStateIllustration(),
          const SizedBox(height: 18),
          const Text(
            'Chưa có ảnh để chẩn đoán',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vui lòng chụp hoặc chọn ảnh để bắt đầu\nphân tích bệnh lá sầu riêng.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          // Section 3: Action Buttons
          ImageSelectorButtons(
            onCameraTap: () => context.push('/camera-simulator'),
            onGalleryTap: () => _openGallery(context, ref),
          ),
          const SizedBox(height: 24),

          // Section 4: Photo Tips
          const PhotoTipsCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
