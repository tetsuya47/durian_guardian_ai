import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_api_client.dart';
import '../../../../services/storage_service.dart';
import '../../data/datasources/recommendation_remote_datasource.dart';
import '../../domain/repositories/recommendation_repository.dart';
import '../../data/repository_impl/recommendation_repository_impl.dart';
import '../../domain/entities/recommendation_entities.dart';

final recommendationRemoteDataSourceProvider = Provider<RecommendationRemoteDataSource>((ref) {
  final apiClient = ref.watch(dioApiClientProvider);
  return RecommendationRemoteDataSourceImpl(apiClient);
});

final recommendationRepositoryProvider = Provider<RecommendationRepository>((ref) {
  final remoteDataSource = ref.watch(recommendationRemoteDataSourceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return RecommendationRepositoryImpl(remoteDataSource, storageService);
});

// Trạng thái màn hình khuyến nghị: 'idle', 'loading', 'success', 'error'
final recommendationStateProvider = StateProvider<String>((ref) => 'idle');

final recommendationResultProvider = StateProvider<RecommendationResultEntity?>((ref) => null);
