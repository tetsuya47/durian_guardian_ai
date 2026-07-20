import '../../../../core/network/result.dart';
import '../../../../core/errors/failure.dart' as err;
import '../../../../services/storage_service.dart';
import '../../domain/entities/recommendation_entities.dart';
import '../../domain/repositories/recommendation_repository.dart';
import '../datasources/recommendation_remote_datasource.dart';

class RecommendationRepositoryImpl implements RecommendationRepository {
  final RecommendationRemoteDataSource _remoteDataSource;
  final StorageService _storageService;

  const RecommendationRepositoryImpl(this._remoteDataSource, this._storageService);

  @override
  Future<Result<RecommendationResultEntity>> getRecommendations() async {
    try {
      final latestDisease = _storageService.getString('latest_scanned_disease') ?? 'Healthy';
      final dto = await _remoteDataSource.getRecommendations(latestDisease);
      return Success(dto.toDomain());
    } catch (e) {
      return Failure(err.Failure.fromException(e).message, e);
    }
  }
}
