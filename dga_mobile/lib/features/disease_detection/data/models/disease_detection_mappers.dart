import '../../domain/entities/disease_detection_entities.dart';
import 'disease_detection_dtos.dart';

extension ScanImageMetadataDtoMapper on ScanImageMetadataDto {
  ImageInfoEntity toEntity() {
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

extension ImageInfoEntityMapper on ImageInfoEntity {
  ScanImageMetadataDto toDto() {
    return ScanImageMetadataDto(
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

extension DiseaseResponseDtoMapper on DiseaseResponseDto {
  DiseaseInfoEntity toEntity() {
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

extension DiseaseInfoEntityMapper on DiseaseInfoEntity {
  DiseaseResponseDto toDto() {
    return DiseaseResponseDto(
      diseaseName: diseaseName,
      symptoms: symptoms,
      causes: causes,
      impactLevel: impactLevel,
      spreadMethod: spreadMethod,
      quickRecommendations: quickRecommendations,
    );
  }
}

extension DetectionResultDtoMapper on DetectionResultDto {
  DetectionResultEntity toEntity() {
    return DetectionResultEntity(
      diseaseName: diseaseName,
      confidence: confidence,
      severity: severity,
      scanDate: scanDate,
      diseaseInfo: diseaseInfo.toEntity(),
      imageInfo: imageInfo.toEntity(),
    );
  }
}

extension DetectionResultEntityMapper on DetectionResultEntity {
  DetectionResultDto toDto() {
    return DetectionResultDto(
      diseaseName: diseaseName,
      confidence: confidence,
      severity: severity,
      scanDate: scanDate,
      diseaseInfo: diseaseInfo.toDto(),
      imageInfo: imageInfo.toDto(),
    );
  }
}
