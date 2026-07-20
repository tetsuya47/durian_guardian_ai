import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/result.dart';
import '../../../../services/storage_service.dart';
import '../../domain/entities/settings_entities.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';
import '../models/settings_dtos.dart';
import '../models/settings_mappers.dart';

const _defaultSettingsJson = {
  'theme_mode': 'Theo hệ thống',
  'language': 'Tiếng Việt',
  'notifications': {
    'ai_alerts': true,
    'weather_alerts': true,
    'disease_alerts': true,
    'system_alerts': false,
  },
  'security': {
    'biometric_enabled': false,
    'has_pin': false,
  },
  'cache': {
    'cache_size': 0.0,
    'photo_size': 0.0,
    'ai_cache_size': 0.0,
  },
};

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _localDataSource;

  const SettingsRepositoryImpl(this._localDataSource);

  @override
  Future<Result<AppSettingsEntity>> getAppSettings() async {
    try {
      final dto = await _localDataSource.getCachedSettings();
      if (dto == null) {
        final defaultDto = AppSettingsDto.fromJson(_defaultSettingsJson);
        await _localDataSource.saveSettings(defaultDto);
        return Success(defaultDto.toEntity());
      }
      return Success(dto.toEntity());
    } catch (e) {
      return Failure('Không thể tải cấu hình cài đặt', e);
    }
  }

  @override
  Future<Result<AppSettingsEntity>> updateAppSettings(AppSettingsEntity settings) async {
    try {
      final dto = settings.toDto();
      await _localDataSource.saveSettings(dto);
      return Success(settings);
    } catch (e) {
      return Failure('Không thể lưu cấu hình cài đặt', e);
    }
  }

  @override
  Future<Result<AppSettingsEntity>> clearCache() async {
    try {
      final current = await _localDataSource.getCachedSettings();
      final base = current ?? AppSettingsDto.fromJson(_defaultSettingsJson);
      final cleared = AppSettingsDto(
        themeMode: base.themeMode,
        language: base.language,
        notifications: base.notifications,
        security: base.security,
        cache: const CacheDetailsDto(cacheSize: 0.0, photoSize: 0.0, aiCacheSize: 0.0),
      );
      await _localDataSource.saveSettings(cleared);
      return Success(cleared.toEntity());
    } catch (e) {
      return Failure('Không thể xoá bộ nhớ tạm', e);
    }
  }

  @override
  Future<Result<AppSettingsEntity>> resetToDefault() async {
    try {
      final defaultDto = AppSettingsDto.fromJson(_defaultSettingsJson);
      await _localDataSource.saveSettings(defaultDto);
      return Success(defaultDto.toEntity());
    } catch (e) {
      return Failure('Không thể đặt lại cài đặt gốc', e);
    }
  }
}

final settingsLocalDataSourceProvider = Provider<SettingsLocalDataSource>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return SettingsLocalDataSourceImpl(storageService);
});
