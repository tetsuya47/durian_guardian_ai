import '../../domain/entities/settings_entities.dart';
import 'settings_dtos.dart';

extension NotificationSettingsDtoMapper on NotificationSettingsDto {
  NotificationSettingsEntity toEntity() {
    return NotificationSettingsEntity(
      aiAlerts: aiAlerts,
      weatherAlerts: weatherAlerts,
      diseaseAlerts: diseaseAlerts,
      systemAlerts: systemAlerts,
    );
  }
}

extension NotificationSettingsEntityMapper on NotificationSettingsEntity {
  NotificationSettingsDto toDto() {
    return NotificationSettingsDto(
      aiAlerts: aiAlerts,
      weatherAlerts: weatherAlerts,
      diseaseAlerts: diseaseAlerts,
      systemAlerts: systemAlerts,
    );
  }
}

extension SecuritySettingsDtoMapper on SecuritySettingsDto {
  SecuritySettingsEntity toEntity() {
    return SecuritySettingsEntity(
      biometricEnabled: biometricEnabled,
      hasPin: hasPin,
    );
  }
}

extension SecuritySettingsEntityMapper on SecuritySettingsEntity {
  SecuritySettingsDto toDto() {
    return SecuritySettingsDto(
      biometricEnabled: biometricEnabled,
      hasPin: hasPin,
    );
  }
}

extension CacheDetailsDtoMapper on CacheDetailsDto {
  CacheDetailsEntity toEntity() {
    return CacheDetailsEntity(
      cacheSize: cacheSize,
      photoSize: photoSize,
      aiCacheSize: aiCacheSize,
    );
  }
}

extension CacheDetailsEntityMapper on CacheDetailsEntity {
  CacheDetailsDto toDto() {
    return CacheDetailsDto(
      cacheSize: cacheSize,
      photoSize: photoSize,
      aiCacheSize: aiCacheSize,
    );
  }
}

extension AppSettingsDtoMapper on AppSettingsDto {
  AppSettingsEntity toEntity() {
    return AppSettingsEntity(
      themeMode: themeMode,
      language: language,
      notifications: notifications.toEntity(),
      security: security.toEntity(),
      cache: cache.toEntity(),
    );
  }
}

extension AppSettingsEntityMapper on AppSettingsEntity {
  AppSettingsDto toDto() {
    return AppSettingsDto(
      themeMode: themeMode,
      language: language,
      notifications: notifications.toDto(),
      security: security.toDto(),
      cache: cache.toDto(),
    );
  }
}
