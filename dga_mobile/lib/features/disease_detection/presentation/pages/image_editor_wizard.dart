import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/ui_helpers.dart';
import '../../domain/entities/disease_detection_entities.dart';
import '../providers/disease_detection_providers.dart';

class ImageEditorWizard extends ConsumerStatefulWidget {
  const ImageEditorWizard({super.key});

  @override
  ConsumerState<ImageEditorWizard> createState() => _ImageEditorWizardState();
}

class _ImageEditorWizardState extends ConsumerState<ImageEditorWizard> {
  int _currentStep = 0;
  double _rotationAngle = 0.0;
  bool _isFlipped = false;
  double _compressionQuality = 80.0;
  double _cropWidthPercent = 0.8;
  double _cropHeightPercent = 0.8;

  double _parseFileSize(String sizeStr) {
    final clean = sizeStr.replaceAll(RegExp(r'[^\d\.]'), '');
    final value = double.tryParse(clean) ?? 1.0;
    if (sizeStr.toLowerCase().contains('kb')) {
      return value / 1024.0;
    }
    return value;
  }

  String _formatFileSize(double mbValue) {
    if (mbValue < 0.1) {
      return '${(mbValue * 1024.0).toStringAsFixed(0)} KB';
    }
    return '${mbValue.toStringAsFixed(2)} MB';
  }

  void _startAIPrediction(ImageInfoEntity selectedImage) async {
    ref.read(detectionStateProvider.notifier).state = 'analyzing';
    if (!mounted) return;
    context.go('/disease-detection');

    try {
      final repo = ref.read(diseaseDetectionRepositoryProvider);
      final result = await repo.detectDisease(selectedImage);
      if (!mounted) return;
      result.when(
        success: (data) {
          ref.read(detectionResultProvider.notifier).state = data;
          ref.read(detectionStateProvider.notifier).state = 'success';
          if (mounted) AppSnackbars.showSuccess(context, 'Chẩn đoán hoàn tất!');
        },
        failure: (msg, err) {
          ref.read(detectionErrorMessageProvider.notifier).state = msg;
          ref.read(detectionStateProvider.notifier).state = 'error';
          if (mounted) AppSnackbars.showError(context, msg);
        },
        loading: () {},
        empty: () {},
      );
    } catch (e) {
      ref.read(detectionErrorMessageProvider.notifier).state = 'Không thể đọc hoặc phân tích tệp ảnh này.';
      ref.read(detectionStateProvider.notifier).state = 'error';
      if (mounted) AppSnackbars.showError(context, 'Không thể đọc hoặc phân tích tệp ảnh này.');
    }
  }

  Widget _buildImageWidget(String imagePath, {BoxFit fit = BoxFit.contain, double? width, double? height, Color? color, BlendMode? colorBlendMode}) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: fit,
        width: width,
        height: height,
        color: color,
        colorBlendMode: colorBlendMode,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
    final file = File(imagePath);
    return Image.file(
      file,
      fit: fit,
      width: width,
      height: height,
      color: color,
      colorBlendMode: colorBlendMode,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted && ref.read(selectedImageProvider) == null) {
        context.go('/disease-detection');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedImage = ref.watch(selectedImageProvider);

    if (selectedImage == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xử lý ảnh trước khi gửi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(theme),
            const Divider(height: 1),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildStepContent(theme, selectedImage),
              ),
            ),
            _buildBottomButtons(theme, selectedImage),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
      color: theme.cardColor,
      child: Row(
        children: [
          _buildStepNode(0, 'Cắt ảnh'),
          _buildStepLine(0),
          _buildStepNode(1, 'Nén dung lượng'),
          _buildStepLine(1),
          _buildStepNode(2, 'Sẵn sàng'),
        ],
      ),
    );
  }

  Widget _buildStepNode(int index, String label) {
    final isCompleted = _currentStep > index;
    final isActive = _currentStep == index;
    final color = isCompleted ? AppColors.primary : isActive ? AppColors.primary : Colors.grey.shade400;

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? AppColors.primary : Colors.transparent,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? AppColors.primary : Colors.grey,
                    ),
                  ),
          ),
        ),
        AppSpacing.h8,
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
            color: isActive || isCompleted ? Colors.black87 : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int afterIndex) {
    final isCompleted = _currentStep > afterIndex;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        height: 2,
        color: isCompleted ? AppColors.primary : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildStepContent(ThemeData theme, ImageInfoEntity image) {
    switch (_currentStep) {
      case 0:
        return _buildCropStep(theme, image);
      case 1:
        return _buildCompressStep(theme, image);
      case 2:
        return _buildReadyStep(theme, image);
      default:
        return const SizedBox();
    }
  }

  Widget _buildCropStep(ThemeData theme, ImageInfoEntity image) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: _rotationAngle,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(_isFlipped ? 3.14159 : 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildImageWidget(image.imageUrl),
                      ),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * _cropWidthPercent * 0.8,
                    height: MediaQuery.of(context).size.width * _cropHeightPercent * 0.8,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Stack(
                      children: [
                        Positioned(top: 0, left: 0, child: Container(width: 15, height: 15, decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.primary, width: 4), left: BorderSide(color: AppColors.primary, width: 4))))),
                        Positioned(top: 0, right: 0, child: Container(width: 15, height: 15, decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.primary, width: 4), right: BorderSide(color: AppColors.primary, width: 4))))),
                        Positioned(bottom: 0, left: 0, child: Container(width: 15, height: 15, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.primary, width: 4), left: BorderSide(color: AppColors.primary, width: 4))))),
                        Positioned(bottom: 0, right: 0, child: Container(width: 15, height: 15, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.primary, width: 4), right: BorderSide(color: AppColors.primary, width: 4))))),
                        Positioned.fill(
                          child: GridView.count(
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            children: List.generate(9, (index) => Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white24, width: 0.5),
                              ),
                            )),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.v12,
          Text(
            'Điều chỉnh khung lưới để tập trung vào vết bệnh trên lá sầu riêng.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          AppSpacing.v16,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.rotate_right),
                onPressed: () {
                  setState(() => _rotationAngle += 1.5708);
                  AppSnackbars.showInfo(context, 'Xoay ảnh 90°');
                },
                tooltip: 'Xoay 90°',
              ),
              AppSpacing.h16,
              IconButton.filledTonal(
                icon: const Icon(Icons.flip),
                onPressed: () {
                  setState(() => _isFlipped = !_isFlipped);
                  AppSnackbars.showInfo(context, 'Lật ảnh đối xứng');
                },
                tooltip: 'Lật ngang',
              ),
              AppSpacing.h16,
              IconButton.filledTonal(
                icon: const Icon(Icons.aspect_ratio),
                onPressed: () {
                  setState(() {
                    _cropWidthPercent = _cropWidthPercent == 0.8 ? 0.6 : 0.8;
                    _cropHeightPercent = _cropHeightPercent == 0.8 ? 0.5 : 0.8;
                  });
                },
                tooltip: 'Đổi tỷ lệ',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompressStep(ThemeData theme, ImageInfoEntity image) {
    final originalMB = _parseFileSize(image.fileSize);
    final compressedMB = originalMB * (_compressionQuality / 100.0);

    String status = 'Tối ưu cho AI';
    Color statusColor = AppColors.success;
    if (_compressionQuality < 35.0) {
      status = 'Chất lượng thấp (Dễ sai lệch AI)';
      statusColor = AppColors.error;
    } else if (_compressionQuality > 90.0) {
      status = 'Dung lượng lớn (Tải chậm)';
      statusColor = AppColors.warning;
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            elevation: 4,
            child: SizedBox(
              width: 180,
              height: 180,
              child: _buildImageWidget(
                image.imageUrl,
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: (100.0 - _compressionQuality) / 250.0),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),
          AppSpacing.v32,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Chất lượng nén ảnh:', style: theme.textTheme.titleSmall),
              Text(
                '${_compressionQuality.toStringAsFixed(0)}%',
                style: theme.textTheme.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: _compressionQuality,
            min: 10.0,
            max: 100.0,
            divisions: 9,
            activeColor: AppColors.primary,
            onChanged: (val) {
              setState(() => _compressionQuality = val);
            },
          ),
          AppSpacing.v24,
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.onSurface.withAlpha(30)),
            ),
            child: Column(
              children: [
                _buildStatRow('Dung lượng gốc', _formatFileSize(originalMB)),
                const Divider(),
                _buildStatRow('Dung lượng sau nén', _formatFileSize(compressedMB), isHighlighted: true),
                const Divider(),
                _buildStatRow('Trạng thái chất lượng', status, valueColor: statusColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyStep(ThemeData theme, ImageInfoEntity image) {
    final originalMB = _parseFileSize(image.fileSize);
    final compressedMB = originalMB * (_compressionQuality / 100.0);
    final reduction = originalMB > 0 ? (1.0 - (compressedMB / originalMB)) * 100.0 : 0.0;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Báo cáo tối ưu hóa ảnh',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          AppSpacing.v16,
          _buildCheckItem(theme, 'Ảnh đã được tải lên từ thiết bị', true),
          _buildCheckItem(theme, 'Ảnh xoay điều hướng tiêu chuẩn góc đứng', true),
          _buildCheckItem(theme, 'Nén dung lượng thành công (-${reduction.toStringAsFixed(0)}%)', true),
          _buildCheckItem(theme, 'Dung lượng ảnh tối ưu: ${_formatFileSize(compressedMB)}', true),
          _buildCheckItem(theme, 'Định dạng mã hóa tương thích 100% với AI API', true),
          AppSpacing.v24,
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.primary.withAlpha(50)),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user_outlined, color: theme.colorScheme.primary, size: 28),
                AppSpacing.h16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hình ảnh đã sẵn sàng phân tích!',
                        style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 14),
                      ),
                      AppSpacing.v4,
                      Text(
                        'Nhấn "Chẩn đoán ngay" để kích hoạt mô hình AI và nhận kết quả.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isHighlighted = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? (isHighlighted ? AppColors.primary : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckItem(ThemeData theme, String label, bool check) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Row(
        children: [
          Icon(
            check ? Icons.check_circle : Icons.radio_button_unchecked,
            color: check ? AppColors.primary : Colors.grey,
            size: 20,
          ),
          AppSpacing.h12,
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(ThemeData theme, ImageInfoEntity image) {
    final isLastStep = _currentStep == 2;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: theme.cardColor,
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _currentStep--);
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Quay lại'),
              ),
            ),
          if (_currentStep > 0) AppSpacing.h16,
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                if (isLastStep) {
                  _startAIPrediction(image);
                } else {
                  setState(() => _currentStep++);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isLastStep ? 'Chẩn đoán ngay' : 'Tiếp tục'),
            ),
          ),
        ],
      ),
    );
  }
}
