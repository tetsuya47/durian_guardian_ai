import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/ui_helpers.dart';
import '../../domain/entities/disease_detection_entities.dart';
import '../providers/disease_detection_providers.dart';

class CameraSimulatorPage extends ConsumerStatefulWidget {
  const CameraSimulatorPage({super.key});

  @override
  ConsumerState<CameraSimulatorPage> createState() => _CameraSimulatorPageState();
}

class _CameraSimulatorPageState extends ConsumerState<CameraSimulatorPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _takePhoto() async {
    setState(() => _isLoading = true);
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (photo == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      await _processAndNavigate(photo);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackbars.showError(context, 'Không thể chụp ảnh. Vui lòng thử lại.');
      }
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() => _isLoading = true);
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (image == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      await _processAndNavigate(image);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackbars.showError(context, 'Không thể chọn ảnh. Vui lòng thử lại.');
      }
    }
  }

  Future<void> _processAndNavigate(XFile pickedFile) async {
    final file = File(pickedFile.path);

    if (!await file.exists()) {
      if (mounted) {
        setState(() => _isLoading = false);
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

    if (mounted) {
      setState(() => _isLoading = false);
      AppSnackbars.showSuccess(context, 'Ảnh đã chọn thành công!');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Máy ảnh DGA'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Đang xử lý ảnh...', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              )
            : _buildCameraView(theme),
      ),
    );
  }

  Widget _buildCameraView(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Khung ngắm lá', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.flash_off, color: Colors.white54),
                onPressed: () {
                  AppSnackbars.showInfo(context, 'Đèn flash được điều khiển bởi thiết bị');
                },
              ),
            ],
          ),
        ),

        Expanded(
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white54, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: Colors.grey.shade900,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 80, color: Colors.white24),
                        SizedBox(height: 16),
                        Text(
                          'Nhấn nút bên dưới để chụp ảnh lá sầu riêng',
                          style: TextStyle(color: Colors.white38, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    childAspectRatio: 0.6,
                    children: List.generate(9, (index) => Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white12, width: 0.5),
                      ),
                    )),
                  ),
                  Center(
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          color: Colors.black,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.photo_library, color: Colors.white, size: 28),
                onPressed: _pickFromGallery,
                tooltip: 'Chọn từ thư viện',
              ),
              GestureDetector(
                onTap: _takePhoto,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 28),
                onPressed: _takePhoto,
                tooltip: 'Chụp ảnh',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
