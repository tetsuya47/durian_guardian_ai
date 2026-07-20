class MockNotificationSettings {
  final bool aiAlerts;
  final bool weatherAlerts;
  final bool diseaseAlerts;
  final bool systemAlerts;

  const MockNotificationSettings({
    required this.aiAlerts,
    required this.weatherAlerts,
    required this.diseaseAlerts,
    required this.systemAlerts,
  });

  MockNotificationSettings copyWith({
    bool? aiAlerts,
    bool? weatherAlerts,
    bool? diseaseAlerts,
    bool? systemAlerts,
  }) {
    return MockNotificationSettings(
      aiAlerts: aiAlerts ?? this.aiAlerts,
      weatherAlerts: weatherAlerts ?? this.weatherAlerts,
      diseaseAlerts: diseaseAlerts ?? this.diseaseAlerts,
      systemAlerts: systemAlerts ?? this.systemAlerts,
    );
  }
}

class MockSecuritySettings {
  final bool biometricEnabled;
  final bool hasPin;

  const MockSecuritySettings({
    required this.biometricEnabled,
    required this.hasPin,
  });

  MockSecuritySettings copyWith({
    bool? biometricEnabled,
    bool? hasPin,
  }) {
    return MockSecuritySettings(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      hasPin: hasPin ?? this.hasPin,
    );
  }
}

class MockCacheDetails {
  final double cacheSize; // in MB
  final double photoSize; // in MB
  final double aiCacheSize; // in MB

  const MockCacheDetails({
    required this.cacheSize,
    required this.photoSize,
    required this.aiCacheSize,
  });

  MockCacheDetails copyWith({
    double? cacheSize,
    double? photoSize,
    double? aiCacheSize,
  }) {
    return MockCacheDetails(
      cacheSize: cacheSize ?? this.cacheSize,
      photoSize: photoSize ?? this.photoSize,
      aiCacheSize: aiCacheSize ?? this.aiCacheSize,
    );
  }
}

class MockAppSettings {
  final String themeMode; // 'Sáng', 'Tối', 'Theo hệ thống'
  final String language; // 'Tiếng Việt'
  final MockNotificationSettings notifications;
  final MockSecuritySettings security;
  final MockCacheDetails cache;

  const MockAppSettings({
    required this.themeMode,
    required this.language,
    required this.notifications,
    required this.security,
    required this.cache,
  });

  MockAppSettings copyWith({
    String? themeMode,
    String? language,
    MockNotificationSettings? notifications,
    MockSecuritySettings? security,
    MockCacheDetails? cache,
  }) {
    return MockAppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      notifications: notifications ?? this.notifications,
      security: security ?? this.security,
      cache: cache ?? this.cache,
    );
  }
}
