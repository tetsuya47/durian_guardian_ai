import '../../domain/entities/disease_detection_entities.dart';

class ScanImageMetadataDto {
  final String fileName;
  final String fileSize;
  final String dimensions;
  final String createdDate;
  final String device;
  final String imageUrl;
  final String? heatmapUrl;
  final String? overlayUrl;

  const ScanImageMetadataDto({
    required this.fileName,
    required this.fileSize,
    required this.dimensions,
    required this.createdDate,
    required this.device,
    required this.imageUrl,
    this.heatmapUrl,
    this.overlayUrl,
  });

  factory ScanImageMetadataDto.fromJson(Map<String, dynamic> json) {
    return ScanImageMetadataDto(
      fileName: json['file_name'] as String? ?? '',
      fileSize: json['file_size'] as String? ?? '',
      dimensions: json['dimensions'] as String? ?? '',
      createdDate: json['created_date'] as String? ?? '',
      device: json['device'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      heatmapUrl: json['heatmap_url'] as String?,
      overlayUrl: json['overlay_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'file_name': fileName,
      'file_size': fileSize,
      'dimensions': dimensions,
      'created_date': createdDate,
      'device': device,
      'image_url': imageUrl,
      'heatmap_url': heatmapUrl,
      'overlay_url': overlayUrl,
    };
  }

  ImageInfoEntity toDomain() {
    return ImageInfoEntity(
      fileName: fileName,
      fileSize: fileSize,
      dimensions: dimensions,
      createdDate: createdDate,
      device: device,
      imageUrl: imageUrl,
      heatmapUrl: heatmapUrl,
      overlayUrl: overlayUrl,
    );
  }
}

class DiseaseResponseDto {
  final String diseaseName;
  final String symptoms;
  final String causes;
  final String impactLevel;
  final String spreadMethod;
  final List<String> quickRecommendations;

  const DiseaseResponseDto({
    required this.diseaseName,
    required this.symptoms,
    required this.causes,
    required this.impactLevel,
    required this.spreadMethod,
    required this.quickRecommendations,
  });

  factory DiseaseResponseDto.fromJson(Map<String, dynamic> json) {
    return DiseaseResponseDto(
      diseaseName: json['disease_name'] as String? ?? '',
      symptoms: json['symptoms'] as String? ?? '',
      causes: json['causes'] as String? ?? '',
      impactLevel: json['impact_level'] as String? ?? '',
      spreadMethod: json['spread_method'] as String? ?? '',
      quickRecommendations: (json['quick_recommendations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'disease_name': diseaseName,
      'symptoms': symptoms,
      'causes': causes,
      'impact_level': impactLevel,
      'spread_method': spreadMethod,
      'quick_recommendations': quickRecommendations,
    };
  }

  DiseaseInfoEntity toDomain() {
    return DiseaseInfoEntity(
      diseaseName: diseaseName,
      symptoms: symptoms,
      causes: causes,
      impactLevel: impactLevel,
      spreadMethod: spreadMethod,
      quickRecommendations: quickRecommendations,
    );
  }
}

class DetectionResultDto {
  final String diseaseName;
  final double confidence;
  final String severity;
  final String scanDate;
  final DiseaseResponseDto diseaseInfo;
  final ScanImageMetadataDto imageInfo;

  const DetectionResultDto({
    required this.diseaseName,
    required this.confidence,
    required this.severity,
    required this.scanDate,
    required this.diseaseInfo,
    required this.imageInfo,
  });

  factory DetectionResultDto.fromJson(Map<String, dynamic> json) {
    return DetectionResultDto(
      diseaseName: json['disease_name'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      severity: json['severity'] as String? ?? '',
      scanDate: json['scan_date'] as String? ?? '',
      diseaseInfo: DiseaseResponseDto.fromJson(
          json['disease_info'] as Map<String, dynamic>? ?? const {}),
      imageInfo: ScanImageMetadataDto.fromJson(
          json['image_info'] as Map<String, dynamic>? ?? const {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'disease_name': diseaseName,
      'confidence': confidence,
      'severity': severity,
      'scan_date': scanDate,
      'disease_info': diseaseInfo.toJson(),
      'image_info': imageInfo.toJson(),
    };
  }

  DetectionResultEntity toDomain() {
    return DetectionResultEntity(
      diseaseName: diseaseName,
      confidence: confidence,
      severity: severity,
      scanDate: scanDate,
      diseaseInfo: diseaseInfo.toDomain(),
      imageInfo: imageInfo.toDomain(),
    );
  }
}

class DetectionResponseDto {
  final String treeId;
  final String imageUrl;
  final DetectionResultBriefDto detection;
  final String createdAt;
  final String? heatmapUrl;
  final String? overlayUrl;
  final String? riskLevel;
  final double? riskProbability;
  final String? recommendation;
  final double? processingTimeMs;

  const DetectionResponseDto({
    required this.treeId,
    required this.imageUrl,
    required this.detection,
    required this.createdAt,
    this.heatmapUrl,
    this.overlayUrl,
    this.riskLevel,
    this.riskProbability,
    this.recommendation,
    this.processingTimeMs,
  });

  factory DetectionResponseDto.fromJson(Map<String, dynamic> json) {
    return DetectionResponseDto(
      treeId: json['tree_id'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      detection: DetectionResultBriefDto.fromJson(
          json['detection'] as Map<String, dynamic>? ?? const {}),
      createdAt: json['created_at'] as String? ?? '',
      heatmapUrl: json['heatmap_url'] as String?,
      overlayUrl: json['overlay_url'] as String?,
      riskLevel: json['risk_level'] as String?,
      riskProbability: (json['risk_probability'] as num?)?.toDouble(),
      recommendation: json['recommendation'] as String?,
      processingTimeMs: (json['processing_time_ms'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tree_id': treeId,
      'image_url': imageUrl,
      'detection': detection.toJson(),
      'created_at': createdAt,
      'heatmap_url': heatmapUrl,
      'overlay_url': overlayUrl,
      'risk_level': riskLevel,
      'risk_probability': riskProbability,
      'recommendation': recommendation,
      'processing_time_ms': processingTimeMs,
    };
  }
}

class DetectionResultBriefDto {
  final String disease;
  final double confidence;
  final String severity;

  const DetectionResultBriefDto({
    required this.disease,
    required this.confidence,
    required this.severity,
  });

  factory DetectionResultBriefDto.fromJson(Map<String, dynamic> json) {
    return DetectionResultBriefDto(
      disease: json['disease'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      severity: json['severity'] as String? ?? 'low',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'disease': disease,
      'confidence': confidence,
      'severity': severity,
    };
  }
}

class ImageQualityResponseDto {
  final bool blur;
  final String brightness;
  final bool leafDetected;
  final bool passed;

  const ImageQualityResponseDto({
    required this.blur,
    required this.brightness,
    required this.leafDetected,
    required this.passed,
  });

  factory ImageQualityResponseDto.fromJson(Map<String, dynamic> json) {
    return ImageQualityResponseDto(
      blur: json['blur'] as bool? ?? false,
      brightness: json['brightness'] as String? ?? 'good',
      leafDetected: json['leaf_detected'] as bool? ?? false,
      passed: json['passed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blur': blur,
      'brightness': brightness,
      'leaf_detected': leafDetected,
      'passed': passed,
    };
  }
}
