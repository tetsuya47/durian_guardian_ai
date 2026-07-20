import 'package:flutter/foundation.dart';

@immutable
class NotificationSettingsEntity {
  final bool aiAlerts;
  final bool weatherAlerts;
  final bool diseaseAlerts;
  final bool systemAlerts;

  const NotificationSettingsEntity({
    required this.aiAlerts,
    required this.weatherAlerts,
    required this.diseaseAlerts,
    required this.systemAlerts,
  });

  NotificationSettingsEntity copyWith({
    bool? aiAlerts,
    bool? weatherAlerts,
    bool? diseaseAlerts,
    bool? systemAlerts,
  }) {
    return NotificationSettingsEntity(
      aiAlerts: aiAlerts ?? this.aiAlerts,
      weatherAlerts: weatherAlerts ?? this.weatherAlerts,
      diseaseAlerts: diseaseAlerts ?? this.diseaseAlerts,
      systemAlerts: systemAlerts ?? this.systemAlerts,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationSettingsEntity &&
        other.aiAlerts == aiAlerts &&
        other.weatherAlerts == weatherAlerts &&
        other.diseaseAlerts == diseaseAlerts &&
        other.systemAlerts == systemAlerts;
  }

  @override
  int get hashCode {
    return Object.hash(aiAlerts, weatherAlerts, diseaseAlerts, systemAlerts);
  }
}

@immutable
class SecuritySettingsEntity {
  final bool biometricEnabled;
  final bool hasPin;

  const SecuritySettingsEntity({
    required this.biometricEnabled,
    required this.hasPin,
  });

  SecuritySettingsEntity copyWith({
    bool? biometricEnabled,
    bool? hasPin,
  }) {
    return SecuritySettingsEntity(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      hasPin: hasPin ?? this.hasPin,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SecuritySettingsEntity &&
        other.biometricEnabled == biometricEnabled &&
        other.hasPin == hasPin;
  }

  @override
  int get hashCode {
    return Object.hash(biometricEnabled, hasPin);
  }
}

@immutable
class CacheDetailsEntity {
  final double cacheSize;
  final double photoSize;
  final double aiCacheSize;

  const CacheDetailsEntity({
    required this.cacheSize,
    required this.photoSize,
    required this.aiCacheSize,
  });

  CacheDetailsEntity copyWith({
    double? cacheSize,
    double? photoSize,
    double? aiCacheSize,
  }) {
    return CacheDetailsEntity(
      cacheSize: cacheSize ?? this.cacheSize,
      photoSize: photoSize ?? this.photoSize,
      aiCacheSize: aiCacheSize ?? this.aiCacheSize,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CacheDetailsEntity &&
        other.cacheSize == cacheSize &&
        other.photoSize == photoSize &&
        other.aiCacheSize == aiCacheSize;
  }

  @override
  int get hashCode {
    return Object.hash(cacheSize, photoSize, aiCacheSize);
  }
}

@immutable
class AppSettingsEntity {
  final String themeMode;
  final String language;
  final NotificationSettingsEntity notifications;
  final SecuritySettingsEntity security;
  final CacheDetailsEntity cache;

  const AppSettingsEntity({
    required this.themeMode,
    required this.language,
    required this.notifications,
    required this.security,
    required this.cache,
  });

  AppSettingsEntity copyWith({
    String? themeMode,
    String? language,
    NotificationSettingsEntity? notifications,
    SecuritySettingsEntity? security,
    CacheDetailsEntity? cache,
  }) {
    return AppSettingsEntity(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      notifications: notifications ?? this.notifications,
      security: security ?? this.security,
      cache: cache ?? this.cache,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettingsEntity &&
        other.themeMode == themeMode &&
        other.language == language &&
        other.notifications == notifications &&
        other.security == security &&
        other.cache == cache;
  }

  @override
  int get hashCode {
    return Object.hash(themeMode, language, notifications, security, cache);
  }
}
