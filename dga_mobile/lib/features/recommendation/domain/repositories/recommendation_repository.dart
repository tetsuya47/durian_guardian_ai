import '../../../../core/network/result.dart';
import '../entities/recommendation_entities.dart';

abstract class RecommendationRepository {
  Future<Result<RecommendationResultEntity>> getRecommendations();
}
