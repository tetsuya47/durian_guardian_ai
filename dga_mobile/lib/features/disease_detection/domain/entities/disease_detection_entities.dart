import 'package:flutter/foundation.dart';

@immutable
class ImageInfoEntity {
  final String fileName;
  final String fileSize;
  final String dimensions;
  final String createdDate;
  final String device;
  final String imageUrl;
  final String? heatmapUrl;
  final String? overlayUrl;

  const ImageInfoEntity({
    required this.fileName,
    required this.fileSize,
    required this.dimensions,
    required this.createdDate,
    required this.device,
    required this.imageUrl,
    this.heatmapUrl,
    this.overlayUrl,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImageInfoEntity &&
        other.fileName == fileName &&
        other.fileSize == fileSize &&
        other.dimensions == dimensions &&
        other.createdDate == createdDate &&
        other.device == device &&
        other.imageUrl == imageUrl &&
        other.heatmapUrl == heatmapUrl &&
        other.overlayUrl == overlayUrl;
  }

  @override
  int get hashCode {
    return Object.hash(
      fileName,
      fileSize,
      dimensions,
      createdDate,
      device,
      imageUrl,
      heatmapUrl,
      overlayUrl,
    );
  }
}

@immutable
class DiseaseInfoEntity {
  final String diseaseName;
  final String symptoms;
  final String causes;
  final String impactLevel;
  final String spreadMethod;
  final List<String> quickRecommendations;

  const DiseaseInfoEntity({
    required this.diseaseName,
    required this.symptoms,
    required this.causes,
    required this.impactLevel,
    required this.spreadMethod,
    required this.quickRecommendations,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiseaseInfoEntity &&
        other.diseaseName == diseaseName &&
        other.symptoms == symptoms &&
        other.causes == causes &&
        other.impactLevel == impactLevel &&
        other.spreadMethod == spreadMethod &&
        listEquals(other.quickRecommendations, quickRecommendations);
  }

  @override
  int get hashCode {
    return Object.hash(
      diseaseName,
      symptoms,
      causes,
      impactLevel,
      spreadMethod,
      Object.hashAll(quickRecommendations),
    );
  }
}

@immutable
class DetectionResultEntity {
  final String diseaseName;
  final double confidence;
  final String severity;
  final String scanDate;
  final DiseaseInfoEntity diseaseInfo;
  final ImageInfoEntity imageInfo;

  const DetectionResultEntity({
    required this.diseaseName,
    required this.confidence,
    required this.severity,
    required this.scanDate,
    required this.diseaseInfo,
    required this.imageInfo,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DetectionResultEntity &&
        other.diseaseName == diseaseName &&
        other.confidence == confidence &&
        other.severity == severity &&
        other.scanDate == scanDate &&
        other.diseaseInfo == diseaseInfo &&
        other.imageInfo == imageInfo;
  }

  @override
  int get hashCode {
    return Object.hash(
      diseaseName,
      confidence,
      severity,
      scanDate,
      diseaseInfo,
      imageInfo,
    );
  }
}
