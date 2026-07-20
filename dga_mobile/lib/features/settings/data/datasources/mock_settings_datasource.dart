import '../models/settings_models.dart';

class MockSettingsDatasource {
  MockSettingsDatasource._();

  static const MockNotificationSettings defaultNotifications = MockNotificationSettings(
    aiAlerts: true,
    weatherAlerts: true,
    diseaseAlerts: true,
    systemAlerts: false,
  );

  static const MockSecuritySettings defaultSecurity = MockSecuritySettings(
    biometricEnabled: true,
    hasPin: true,
  );

  static const MockCacheDetails defaultCache = MockCacheDetails(
    cacheSize: 24.5,
    photoSize: 156.2,
    aiCacheSize: 85.0,
  );

  static MockAppSettings currentSettings = const MockAppSettings(
    themeMode: 'Theo hệ thống',
    language: 'Tiếng Việt',
    notifications: defaultNotifications,
    security: defaultSecurity,
    cache: defaultCache,
  );
}
