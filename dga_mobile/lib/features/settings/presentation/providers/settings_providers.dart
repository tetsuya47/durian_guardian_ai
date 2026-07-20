import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../data/repository_impl/settings_repository_impl.dart';
import '../../domain/entities/settings_entities.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final localDataSource = ref.watch(settingsLocalDataSourceProvider);
  return SettingsRepositoryImpl(localDataSource);
});

// Trạng thái màn hình cài đặt: 'idle', 'loading', 'loaded', 'error'
final settingsStateProvider = StateProvider<String>((ref) => 'idle');

final appSettingsProvider = StateProvider<AppSettingsEntity?>((ref) => null);
