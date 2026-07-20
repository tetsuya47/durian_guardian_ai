import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../../core/network/result.dart';
import '../../../../core/errors/failure.dart' as err;
import '../../../../services/storage_service.dart';
import '../../domain/entities/disease_detection_entities.dart';
import '../../domain/repositories/disease_detection_repository.dart';
import '../datasources/disease_detection_remote_datasource.dart';
import '../../../../core/network/dio_api_client.dart';
import '../models/disease_detection_dtos.dart';
import '../models/disease_detection_models.dart';
import '../datasources/mock_detection_datasource.dart';
import '../../../../core/network/environment_config.dart';

class DiseaseDetectionRepositoryImpl implements DiseaseDetectionRepository {
  final DiseaseDetectionRemoteDataSource _remoteDataSource;
  final DioApiClient _apiClient;
  final StorageService _storageService;

  const DiseaseDetectionRepositoryImpl(
    this._remoteDataSource,
    this._apiClient,
    this._storageService,
  );

  @override
  Future<Result<List<ImageInfoEntity>>> getMockImages() async {
    try {
      final mockList = MockDetectionDatasource.mockImages;
      final dtos = mockList.map((mock) => ScanImageMetadataDto(
        fileName: mock.fileName,
        fileSize: mock.fileSize,
        dimensions: mock.dimensions,
        createdDate: mock.createdDate,
        device: mock.device,
        imageUrl: mock.imageUrl,
      )).toList();
      return Success(dtos.map((dto) => dto.toDomain()).toList());
    } catch (e) {
      return Failure('Không thể nạp danh sách ảnh mẫu', e);
    }
  }

  Future<String> _resolveLocalImagePath(String imagePath) async {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'dga_${DateTime.now().millisecondsSinceEpoch}_${p.basename(Uri.parse(imagePath).path)}';
      final localFile = File('${tempDir.path}/$fileName');

      final httpClient = HttpClient();
      try {
        final request = await httpClient.getUrl(Uri.parse(imagePath));
        final response = await request.close();
        final sink = localFile.openWrite();
        await response.pipe(sink);
        return localFile.path;
      } finally {
        httpClient.close();
      }
    }

    if (imagePath.startsWith('assets/')) {
      final tempDir = await getTemporaryDirectory();
      final fileName = p.basename(imagePath);
      final localFile = File('${tempDir.path}/$fileName');

      if (!await localFile.exists()) {
        final byteData = await rootBundle.load(imagePath);
        await localFile.writeAsBytes(
          byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        );
      }
      return localFile.path;
    }

    final file = File(imagePath);
    if (!await file.exists()) {
      throw FileSystemException('Image file not found', imagePath);
    }
    return imagePath;
  }

  @override
  Future<Result<DetectionResultEntity>> detectDisease(ImageInfoEntity imageInfo) async {
    try {
      final localImagePath = await _resolveLocalImagePath(imageInfo.imageUrl);

      final qualityResponse = await _remoteDataSource.checkImageQuality(localImagePath);
      if (!qualityResponse.passed) {
        String errorDesc = 'Chất lượng ảnh không đạt yêu cầu.';
        if (qualityResponse.blur) {
          errorDesc = 'Ảnh quá mờ. Vui lòng chụp lại ảnh rõ nét hơn.';
        } else if (!qualityResponse.leafDetected) {
          errorDesc = 'Không phát hiện lá cây sầu riêng trong ảnh. Vui lòng căn chỉnh lại.';
        } else if (qualityResponse.brightness == 'dark') {
          errorDesc = 'Ảnh quá tối. Vui lòng chụp ở nơi đủ ánh sáng.';
        }
        return Failure(errorDesc);
      }

      String? treeId;
      try {
        final treesListResponse = await _apiClient.get<Map<String, dynamic>>(
          path: '/trees',
          decoder: (json) => json as Map<String, dynamic>,
        );
        final items = treesListResponse.data?['items'] as List<dynamic>? ?? [];
        if (items.isNotEmpty) {
          treeId = items.first['id'] as String?;
        }
      } catch (_) {}

      if (treeId == null || treeId.isEmpty) {
        return const Failure('Không tìm thấy cây sầu riêng nào trong hệ thống. Vui lòng thêm cây trước khi chẩn đoán.');
      }

      final detectionDto = await _remoteDataSource.detectDisease(treeId, localImagePath);
      final diseaseBrief = detectionDto.detection;

      double riskScore;
      if (detectionDto.riskProbability != null) {
        riskScore = detectionDto.riskProbability! * 100;
      } else {
        riskScore = _calculateRiskScore(diseaseBrief.disease, diseaseBrief.confidence);
      }

      final mockDisease = _getMockDiseaseInfo(diseaseBrief.disease);

      final List<String> recommendations;
      if (detectionDto.recommendation != null && detectionDto.recommendation!.isNotEmpty) {
        recommendations = [detectionDto.recommendation!];
      } else {
        recommendations = mockDisease.quickRecommendations;
      }

      final metadata = {
        'risk_score': riskScore,
        'risk_level': detectionDto.riskLevel ?? _getRiskLevel(riskScore),
        'recommendations': recommendations,
        'prediction_time': DateTime.now().toIso8601String(),
        'inspection_status': 'Completed',
        'recommendation_status': 'Generated',
        'processing_time_ms': detectionDto.processingTimeMs,
      };

      final cacheKey = 'metadata_${treeId}_${detectionDto.createdAt}';
      await _storageService.setString(cacheKey, json.encode(metadata));
      await _storageService.setString('latest_scanned_disease', diseaseBrief.disease);

      final baseUrl = EnvironmentConfig.uploadsBaseUrl;
      final resolvedHeatmapUrl = _resolveUrl(detectionDto.heatmapUrl, baseUrl);
      final resolvedOverlayUrl = _resolveUrl(detectionDto.overlayUrl, baseUrl);

      final fileSizeStr = await _getFileSizeString(localImagePath);

      final resultDto = DetectionResultDto(
        diseaseName: _translateDisease(diseaseBrief.disease),
        confidence: diseaseBrief.confidence,
        severity: _translateSeverity(diseaseBrief.severity),
        scanDate: _formatScanDate(detectionDto.createdAt),
        diseaseInfo: DiseaseResponseDto(
          diseaseName: mockDisease.diseaseName,
          symptoms: mockDisease.symptoms,
          causes: mockDisease.causes,
          impactLevel: mockDisease.impactLevel,
          spreadMethod: mockDisease.spreadMethod,
          quickRecommendations: recommendations,
        ),
        imageInfo: ScanImageMetadataDto(
          fileName: imageInfo.fileName,
          fileSize: fileSizeStr,
          dimensions: imageInfo.dimensions,
          createdDate: imageInfo.createdDate,
          device: imageInfo.device,
          imageUrl: localImagePath,
          heatmapUrl: resolvedHeatmapUrl,
          overlayUrl: resolvedOverlayUrl,
        ),
      );

      return Success(resultDto.toDomain());
    } catch (e) {
      final failure = err.Failure.fromException(e);
      return Failure(failure.message, e);
    }
  }

  String _resolveUrl(String? relativePath, String baseUrl) {
    if (relativePath == null || relativePath.isEmpty) return '';
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }
    final cleaned = relativePath.replaceFirst(RegExp(r'^\.\/'), '').replaceFirst(RegExp(r'^\/'), '');
    return '$baseUrl/$cleaned';
  }

  double _calculateRiskScore(String diseaseName, double confidence) {
    final lower = diseaseName.toLowerCase();
    if (lower.contains('healthy') || lower.contains('không phát hiện')) {
      return 10.0 + (confidence * 10).clamp(0, 15);
    } else if (lower.contains('phytophthora') || lower.contains('xì mủ')) {
      return 75.0 + (confidence * 20).clamp(0, 20);
    } else if (lower.contains('rot') || lower.contains('thối')) {
      return 70.0 + (confidence * 20).clamp(0, 25);
    } else if (lower.contains('spot') || lower.contains('đốm')) {
      return 40.0 + (confidence * 30).clamp(0, 30);
    } else if (lower.contains('borer') || lower.contains('sâu')) {
      return 50.0 + (confidence * 25).clamp(0, 25);
    }
    return 30.0 + (confidence * 40).clamp(0, 40);
  }

  String _getRiskLevel(double riskScore) {
    if (riskScore >= 70) return 'high';
    if (riskScore >= 40) return 'medium';
    return 'low';
  }

  String _translateDisease(String name) {
    switch (name.toLowerCase()) {
      case 'healthy':
        return 'Không phát hiện bệnh hại';
      case 'root rot':
        return 'Bệnh thối rễ';
      case 'leaf spot':
        return 'Bệnh đốm lá';
      case 'fruit borer':
        return 'Sâu đục quả';
      case 'powdery mildew':
        return 'Bệnh phấn trắng';
      case 'phytophthora':
        return 'Bệnh xì mủ thân Phytophthora';
      default:
        return name;
    }
  }

  String _translateSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return 'Nhẹ';
      case 'medium':
        return 'Trung bình';
      case 'high':
        return 'Nặng';
      default:
        return severity;
    }
  }

  String _formatScanDate(String rawDate) {
    try {
      final parsed = DateTime.parse(rawDate).toLocal();
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return rawDate;
    }
  }

  Future<String> _getFileSizeString(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final size = await file.length();
        if (size < 1024) return '$size B';
        if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(0)} KB';
        return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (_) {}
    return 'Không xác định';
  }

  MockDiseaseInfo _getMockDiseaseInfo(String diseaseName) {
    final lowerName = diseaseName.toLowerCase();
    if (lowerName.contains('spot') || lowerName.contains('đốm lá')) {
      return MockDetectionDatasource.mockDiseases[0];
    } else if (lowerName.contains('rot') || lowerName.contains('phytophthora') || lowerName.contains('thối') || lowerName.contains('xì mủ')) {
      return MockDetectionDatasource.mockDiseases[1];
    } else {
      return MockDetectionDatasource.mockDiseases[2];
    }
  }
}
