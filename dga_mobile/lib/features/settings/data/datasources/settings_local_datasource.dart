import 'dart:convert';
import '../../../../services/storage_service.dart';
import '../models/settings_dtos.dart';

abstract class SettingsLocalDataSource {
  Future<void> saveSettings(AppSettingsDto settings);
  Future<AppSettingsDto?> getCachedSettings();
  Future<void> clearSettingsCache();
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final StorageService _storageService;
  static const String _settingsKey = 'app_settings';

  const SettingsLocalDataSourceImpl(this._storageService);

  @override
  Future<void> saveSettings(AppSettingsDto settings) async {
    final jsonStr = json.encode(settings.toJson());
    await _storageService.setString(_settingsKey, jsonStr);
  }

  @override
  Future<AppSettingsDto?> getCachedSettings() async {
    final jsonStr = _storageService.getString(_settingsKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      return AppSettingsDto.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearSettingsCache() async {
    await _storageService.remove(_settingsKey);
  }
}
