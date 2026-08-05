import 'dart:convert';
import 'dart:developer' as dev;
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
      const mockList = MockDetectionDatasource.mockImages;
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
      dev.log('[DGA] detectDisease START: ${imageInfo.imageUrl}', name: 'DGA');

      final localImagePath = await _resolveLocalImagePath(imageInfo.imageUrl);
      dev.log('[DGA] localImagePath resolved: $localImagePath', name: 'DGA');

      try {
        dev.log('[DGA] Calling checkImageQuality...', name: 'DGA');
        final qualityResponse = await _remoteDataSource.checkImageQuality(localImagePath);
        dev.log('[DGA] qualityResponse: passed=${qualityResponse.passed}', name: 'DGA');
      } catch (e) {
        dev.log('[DGA] Quality check non-blocking warning: $e', name: 'DGA');
      }

      String? treeId;
      try {
        dev.log('[DGA] Fetching trees list...', name: 'DGA');
        final treesListResponse = await _apiClient.get<Map<String, dynamic>>(
          path: '/trees',
          decoder: (json) => json as Map<String, dynamic>,
        ).timeout(const Duration(seconds: 10));
        dev.log('[DGA] Trees response data keys: ${treesListResponse.data?.keys}', name: 'DGA');
        final items = treesListResponse.data?['items'] as List<dynamic>? ?? [];
        dev.log('[DGA] Trees items count: ${items.length}', name: 'DGA');
        if (items.isNotEmpty) {
          final first = items.first as Map<String, dynamic>;
          treeId = (first['id'] ?? first['_id'])?.toString();
          dev.log('[DGA] Using treeId: $treeId', name: 'DGA');
        }
      } catch (e) {
        dev.log('[DGA] ERROR fetching trees (will use fallback): $e', name: 'DGA');
      }

      if (treeId == null || treeId.isEmpty) {
        // Fallback to valid seeded tree ID from MongoDB
        treeId = '6a6cc2ba3432b70022fba65d';
        dev.log('[DGA] Using fallback treeId: $treeId', name: 'DGA');
      }

      dev.log('[DGA] Calling detectDisease API with treeId=$treeId', name: 'DGA');
      final detectionDto = await _remoteDataSource.detectDisease(treeId, localImagePath).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Quá thời gian chờ phân tích (Timeout 60s). Vui lòng kiểm tra lại kết nối mạng và thử lại.');
        },
      );
      dev.log('[DGA] detectionDto received: disease=${detectionDto.detection.disease}, confidence=${detectionDto.detection.confidence}', name: 'DGA');
      final diseaseBrief = detectionDto.detection;

      double riskScore;
      if (detectionDto.riskProbability != null) {
        riskScore = detectionDto.riskProbability! * 100;
      } else {
        riskScore = _calculateRiskScore(diseaseBrief.disease, diseaseBrief.confidence);
      }

      final mockDisease = _getMockDiseaseInfo(diseaseBrief.disease);

      final List<String> recommendations = [
        if (detectionDto.recommendation != null && detectionDto.recommendation!.isNotEmpty)
          detectionDto.recommendation!,
        ...mockDisease.quickRecommendations,
      ];

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

      // Save local history item for instant UI update on History Page
      try {
        final localHistoryItem = {
          'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
          'treeName': 'Cây sầu riêng #01 (Mặc định)',
          'imageUrl': imageInfo.imageUrl.startsWith('assets/') ? imageInfo.imageUrl : localImagePath,
          'diseaseName': _translateDisease(diseaseBrief.disease),
          'confidence': diseaseBrief.confidence,
          'severity': _translateSeverity(diseaseBrief.severity),
          'date': _formatScanDateOnly(detectionDto.createdAt),
          'time': _formatScanTimeOnly(detectionDto.createdAt),
          'inspectorName': 'Hệ thống AI',
          'weather': {'temperature': 29.5, 'humidity': 75.0},
          'recommendations': recommendations,
          'riskScore': riskScore,
        };

        final existingJsonStr = _storageService.getString('local_scan_history');
        List<dynamic> existingList = [];
        if (existingJsonStr != null && existingJsonStr.isNotEmpty) {
          existingList = json.decode(existingJsonStr) as List<dynamic>;
        }
        existingList.insert(0, localHistoryItem);
        if (existingList.length > 50) {
          existingList = existingList.sublist(0, 50);
        }
        await _storageService.setString('local_scan_history', json.encode(existingList));
        dev.log('[DGA] Local history log saved successfully!', name: 'DGA');
      } catch (e) {
        dev.log('[DGA] Error saving local scan history: $e', name: 'DGA');
      }

      dev.log('[DGA] Returning Success!', name: 'DGA');
      return Success(resultDto.toDomain());
    } catch (e) {
      dev.log('[DGA] EXCEPTION in detectDisease: $e', name: 'DGA');
      final failure = err.Failure.fromException(e);
      dev.log('[DGA] Returning Failure: ${failure.message}', name: 'DGA');
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

  String _formatScanDateOnly(String rawDate) {
    try {
      final parsed = DateTime.parse(rawDate).toLocal();
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
    } catch (_) {
      final now = DateTime.now();
      return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    }
  }

  String _formatScanTimeOnly(String rawDate) {
    try {
      final parsed = DateTime.parse(rawDate).toLocal();
      return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      final now = DateTime.now();
      return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
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
    if (lowerName.contains('thán thư') || lowerName.contains('anthracnose')) {
      return MockDetectionDatasource.getDiseaseInfo('anthracnose_disease');
    } else if (lowerName.contains('sẹo') || lowerName.contains('canker')) {
      return MockDetectionDatasource.getDiseaseInfo('canker_disease');
    } else if (lowerName.contains('thối quả') || lowerName.contains('thối trái') || lowerName.contains('fruit_rot') || lowerName.contains('fruit rot')) {
      return MockDetectionDatasource.getDiseaseInfo('fruit_rot');
    } else if (lowerName.contains('rệp sáp') || lowerName.contains('mealybug')) {
      return MockDetectionDatasource.getDiseaseInfo('mealybug_infestation');
    } else if (lowerName.contains('hồng thân') || lowerName.contains('pink_disease') || lowerName.contains('pink disease')) {
      return MockDetectionDatasource.getDiseaseInfo('pink_disease');
    } else if (lowerName.contains('bồ hóng') || lowerName.contains('sooty_mold') || lowerName.contains('sooty mold')) {
      return MockDetectionDatasource.getDiseaseInfo('sooty_mold');
    } else if (lowerName.contains('cháy thân') || lowerName.contains('cháy lá') || lowerName.contains('stem_blight') || lowerName.contains('stem blight')) {
      return MockDetectionDatasource.getDiseaseInfo('stem_blight');
    } else if (lowerName.contains('nứt thân') || lowerName.contains('gummosis') || lowerName.contains('stem_cracking')) {
      return MockDetectionDatasource.getDiseaseInfo('stem_cracking_ gummosis');
    } else if (lowerName.contains('bọ trĩ') || lowerName.contains('thrips')) {
      return MockDetectionDatasource.getDiseaseInfo('thrips_disease');
    } else if (lowerName.contains('vàng lá') || lowerName.contains('yellow_leaf') || lowerName.contains('yellow leaf')) {
      return MockDetectionDatasource.getDiseaseInfo('yellow_leaf');
    } else {
      return MockDetectionDatasource.getDiseaseInfo('Healthy');
    }
  }
}
