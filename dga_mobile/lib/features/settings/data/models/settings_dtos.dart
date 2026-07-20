class NotificationSettingsDto {
  final bool aiAlerts;
  final bool weatherAlerts;
  final bool diseaseAlerts;
  final bool systemAlerts;

  const NotificationSettingsDto({
    required this.aiAlerts,
    required this.weatherAlerts,
    required this.diseaseAlerts,
    required this.systemAlerts,
  });

  factory NotificationSettingsDto.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsDto(
      aiAlerts: json['ai_alerts'] as bool? ?? true,
      weatherAlerts: json['weather_alerts'] as bool? ?? true,
      diseaseAlerts: json['disease_alerts'] as bool? ?? true,
      systemAlerts: json['system_alerts'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ai_alerts': aiAlerts,
      'weather_alerts': weatherAlerts,
      'disease_alerts': diseaseAlerts,
      'system_alerts': systemAlerts,
    };
  }
}

class SecuritySettingsDto {
  final bool biometricEnabled;
  final bool hasPin;

  const SecuritySettingsDto({
    required this.biometricEnabled,
    required this.hasPin,
  });

  factory SecuritySettingsDto.fromJson(Map<String, dynamic> json) {
    return SecuritySettingsDto(
      biometricEnabled: json['biometric_enabled'] as bool? ?? false,
      hasPin: json['has_pin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'biometric_enabled': biometricEnabled,
      'has_pin': hasPin,
    };
  }
}

class CacheDetailsDto {
  final double cacheSize;
  final double photoSize;
  final double aiCacheSize;

  const CacheDetailsDto({
    required this.cacheSize,
    required this.photoSize,
    required this.aiCacheSize,
  });

  factory CacheDetailsDto.fromJson(Map<String, dynamic> json) {
    return CacheDetailsDto(
      cacheSize: (json['cache_size'] as num?)?.toDouble() ?? 0.0,
      photoSize: (json['photo_size'] as num?)?.toDouble() ?? 0.0,
      aiCacheSize: (json['ai_cache_size'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cache_size': cacheSize,
      'photo_size': photoSize,
      'ai_cache_size': aiCacheSize,
    };
  }
}

class AppSettingsDto {
  final String themeMode;
  final String language;
  final NotificationSettingsDto notifications;
  final SecuritySettingsDto security;
  final CacheDetailsDto cache;

  const AppSettingsDto({
    required this.themeMode,
    required this.language,
    required this.notifications,
    required this.security,
    required this.cache,
  });

  factory AppSettingsDto.fromJson(Map<String, dynamic> json) {
    return AppSettingsDto(
      themeMode: json['theme_mode'] as String? ?? 'Theo hệ thống',
      language: json['language'] as String? ?? 'Tiếng Việt',
      notifications: NotificationSettingsDto.fromJson(
        json['notifications'] as Map<String, dynamic>? ?? const {},
      ),
      security: SecuritySettingsDto.fromJson(
        json['security'] as Map<String, dynamic>? ?? const {},
      ),
      cache: CacheDetailsDto.fromJson(
        json['cache'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme_mode': themeMode,
      'language': language,
      'notifications': notifications.toJson(),
      'security': security.toJson(),
      'cache': cache.toJson(),
    };
  }
}
