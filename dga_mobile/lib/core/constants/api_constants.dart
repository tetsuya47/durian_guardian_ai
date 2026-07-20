import '../network/environment_config.dart';

/// Legacy API constants — kept for backward compatibility.
/// New code should use [ApiEndpoints] for path constants
/// and [EnvironmentConfig.baseUrl] for the base URL.
class ApiConstants {
  ApiConstants._();

  /// Runtime base URL driven by [EnvironmentConfig].
  static String get baseUrl => EnvironmentConfig.baseUrl;

  static const int connectTimeout = 30000; // ms
  static const int receiveTimeout = 30000; // ms

  // ─── Auth ─────────────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';

  // ─── Corrected from old skeleton ──────────────────────────────────────
  // OLD:  profile = '/user/profile'   → WRONG
  // NEW:  profile = '/auth/profile'   → correct backend route
  static const String profile = '/auth/profile';

  // OLD:  diseaseDetection = '/disease/detect'  → WRONG
  // NEW:  aiDetect = '/ai/detect'               → correct backend route
  static const String aiDetect = '/ai/detect';

  // OLD:  recommendations = '/recommendations'  → endpoint does not exist yet
  static const String recommendations = '/recommendations'; // placeholder — no backend yet

  // OLD:  history = '/history'  → missing /{tree_id} path param
  static const String history = '/history'; // use ApiEndpoints.historyByTree(id) instead
}
