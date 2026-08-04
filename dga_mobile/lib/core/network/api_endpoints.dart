/// Canonical API endpoint constants.
///
/// All paths are relative to the base URL defined in [EnvironmentConfig.baseUrl].
/// These replace the skeleton values that were previously in ApiConstants.
class ApiEndpoints {
  ApiEndpoints._();

  // ─── Auth ────────────────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String profile = '/auth/profile';
  static const String changePassword = '/auth/change-password';

  // ─── Farms ───────────────────────────────────────────────────────────────
  static const String farms = '/farms';
  static String farmById(String id) => '/farms/$id';

  // ─── Zones ───────────────────────────────────────────────────────────────
  static const String zones = '/zones';
  static String zoneById(String id) => '/zones/$id';

  // ─── Trees ───────────────────────────────────────────────────────────────
  static const String trees = '/trees';
  static String treeById(String id) => '/trees/$id';
  static String treeDigitalId(String id) => '/trees/$id/digital-id';

  // ─── AI ──────────────────────────────────────────────────────────────────
  static const String aiDetect = '/ai/detect';
  static const String aiImageQuality = '/ai/image-quality';

  // ─── Dashboard ───────────────────────────────────────────────────────────
  static const String dashboard = '/dashboard';
  static const String dashboardHeatmap = '/dashboard/heatmap';

  // ─── History ─────────────────────────────────────────────────────────────
  static String historyByTree(String treeId) => '/history/$treeId';

  // ─── Chat ────────────────────────────────────────────────────────────────
  static const String chat = '/chat';

  // ─── Notifications ───────────────────────────────────────────────────────
  static const String notifications = '/notifications';
  static const String notificationsUnread = '/notifications/unread';
  static String notificationById(String id) => '/notifications/$id';
  static String notificationMarkRead(String id) => '/notifications/$id/read';

  // ─── Companies ───────────────────────────────────────────────────────────
  static const String companies = '/companies';
  static String companyById(String id) => '/companies/$id';

  // ─── Users (admin) ───────────────────────────────────────────────────────
  static const String users = '/users';
  static String userById(String id) => '/users/$id';

  // ─── Inspections ─────────────────────────────────────────────────────────
  static const String inspections = '/inspections';
  static String inspectionById(String id) => '/inspections/$id';

  // ─── Detection Results ───────────────────────────────────────────────────
  static const String detectionResults = '/detection-results';
  static String detectionResultById(String id) => '/detection-results/$id';

  // ─── Disease History ─────────────────────────────────────────────────────
  static const String diseaseHistory = '/disease-history';
  static String diseaseHistoryById(String id) => '/disease-history/$id';

  // ─── Diseases ────────────────────────────────────────────────────────────
  static const String diseases = '/diseases';
  static String diseaseById(String id) => '/diseases/$id';

  // ─── Alerts ──────────────────────────────────────────────────────────────
  static const String alerts = '/alerts';
  static String alertById(String id) => '/alerts/$id';

  // ─── Weather ─────────────────────────────────────────────────────────────
  static const String weatherCurrent = '/weather/current';

  // ─── IoT ─────────────────────────────────────────────────────────────────
  static const String iotTelemetryLatest = '/iot/telemetry/latest';
}
