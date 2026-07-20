import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_api_client.dart';
import '../../../../services/storage_service.dart';
import '../../data/datasources/disease_detection_remote_datasource.dart';
import '../../domain/repositories/disease_detection_repository.dart';
import '../../data/repository_impl/disease_detection_repository_impl.dart';
import '../../domain/entities/disease_detection_entities.dart';

final diseaseDetectionRemoteDataSourceProvider = Provider<DiseaseDetectionRemoteDataSource>((ref) {
  final apiClient = ref.watch(dioApiClientProvider);
  return DiseaseDetectionRemoteDataSourceImpl(apiClient);
});

final diseaseDetectionRepositoryProvider = Provider<DiseaseDetectionRepository>((ref) {
  final remoteDataSource = ref.watch(diseaseDetectionRemoteDataSourceProvider);
  final apiClient = ref.watch(dioApiClientProvider);
  final storageService = ref.watch(storageServiceProvider);
  return DiseaseDetectionRepositoryImpl(remoteDataSource, apiClient, storageService);
});

final detectionStateProvider = StateProvider<String>((ref) => 'idle');

final selectedImageProvider = StateProvider<ImageInfoEntity?>((ref) => null);

final detectionResultProvider = StateProvider<DetectionResultEntity?>((ref) => null);

final detectionErrorMessageProvider = StateProvider<String?>((ref) => null);
