import '../../../../core/network/result.dart';
import '../entities/disease_detection_entities.dart';

abstract class DiseaseDetectionRepository {
  Future<Result<DetectionResultEntity>> detectDisease(ImageInfoEntity imageInfo);
  Future<Result<List<ImageInfoEntity>>> getMockImages();
}
