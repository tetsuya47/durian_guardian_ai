import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_api_client.dart';
import '../models/disease_detection_dtos.dart';

abstract class DiseaseDetectionRemoteDataSource {
  Future<DetectionResponseDto> detectDisease(String treeId, String imagePath);
  Future<ImageQualityResponseDto> checkImageQuality(String imagePath);
}

class DiseaseDetectionRemoteDataSourceImpl implements DiseaseDetectionRemoteDataSource {
  final DioApiClient _apiClient;

  const DiseaseDetectionRemoteDataSourceImpl(this._apiClient);

  Future<MultipartFile> _getMultipartFile(String imagePath) async {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      throw ArgumentError('Cannot upload network URL directly. Download the image first.');
    }

    final file = File(imagePath);
    if (!await file.exists()) {
      throw FileSystemException('Image file not found', imagePath);
    }

    final fileName = p.basename(imagePath);
    return MultipartFile.fromFile(imagePath, filename: fileName);
  }

  @override
  Future<DetectionResponseDto> detectDisease(String treeId, String imagePath) async {
    final multipartFile = await _getMultipartFile(imagePath);
    final formData = FormData.fromMap({
      'tree_id': treeId,
      'file': multipartFile,
    });

    final response = await _apiClient.requestMultipart<DetectionResponseDto>(
      path: ApiEndpoints.aiDetect,
      formData: formData,
      decoder: (json) => DetectionResponseDto.fromJson(json as Map<String, dynamic>),
    );

    if (response.data == null) {
      throw Exception('Phản hồi từ server rỗng');
    }
    return response.data!;
  }

  @override
  Future<ImageQualityResponseDto> checkImageQuality(String imagePath) async {
    final multipartFile = await _getMultipartFile(imagePath);
    final formData = FormData.fromMap({
      'file': multipartFile,
    });

    final response = await _apiClient.requestMultipart<ImageQualityResponseDto>(
      path: ApiEndpoints.aiImageQuality,
      formData: formData,
      decoder: (json) => ImageQualityResponseDto.fromJson(json as Map<String, dynamic>),
    );

    if (response.data == null) {
      throw Exception('Phản hồi kiểm tra chất lượng ảnh rỗng');
    }
    return response.data!;
  }
}
