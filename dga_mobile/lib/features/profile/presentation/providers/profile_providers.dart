import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_api_client.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../data/repository_impl/profile_repository_impl.dart';
import '../../domain/entities/profile_entities.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  final apiClient = ref.watch(dioApiClientProvider);
  return ProfileRemoteDataSourceImpl(apiClient);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final remoteDataSource = ref.watch(profileRemoteDataSourceProvider);
  return ProfileRepositoryImpl(remoteDataSource);
});

// Trạng thái màn hình hồ sơ: 'idle', 'loading', 'loaded', 'empty', 'error'
final profileStateProvider = StateProvider<String>((ref) => 'idle');

final userProfileProvider = StateProvider<UserProfileEntity?>((ref) => null);
