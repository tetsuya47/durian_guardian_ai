import '../models/settings_dtos.dart';

abstract class SettingsRemoteDataSource {
  Future<AppSettingsDto> getAppSettings();
  Future<AppSettingsDto> updateAppSettings(AppSettingsDto settings);
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  const SettingsRemoteDataSourceImpl();

  @override
  Future<AppSettingsDto> getAppSettings() {
    throw UnimplementedError('SettingsRemoteDataSourceImpl.getAppSettings is not implemented');
  }

  @override
  Future<AppSettingsDto> updateAppSettings(AppSettingsDto settings) {
    throw UnimplementedError('SettingsRemoteDataSourceImpl.updateAppSettings is not implemented');
  }
}
