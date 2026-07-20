import '../../../../core/network/result.dart';
import '../entities/settings_entities.dart';

abstract class SettingsRepository {
  Future<Result<AppSettingsEntity>> getAppSettings();
  Future<Result<AppSettingsEntity>> updateAppSettings(AppSettingsEntity settings);
  Future<Result<AppSettingsEntity>> clearCache();
  Future<Result<AppSettingsEntity>> resetToDefault();
}
