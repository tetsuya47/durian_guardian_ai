/// Environment configuration for all deployment targets.
/// Supports: Android emulator, iOS simulator, real device, and production.
///
/// USAGE:
///   - Development (emulator):  set FLUTTER_ENV=emulator  (default)
///   - Development (real device): set FLUTTER_ENV=device and update [deviceHost]
///   - Production: set FLUTTER_ENV=production
///
/// In practice, change [_activeEnv] to switch targets during development.
class EnvironmentConfig {
  EnvironmentConfig._();

  // ─── Change this to switch environment ───────────────────────────────────
  static const _Env _activeEnv = _Env.device;

  /// Host for real-device testing on LAN.
  /// Change this to your machine's local IP (e.g. '192.168.1.2').
  static const String deviceHost = '192.168.1.45';
  // ─────────────────────────────────────────────────────────────────────────

  /// The base URL for the currently active environment.
  static String get baseUrl {
    switch (_activeEnv) {
      case _Env.emulator:
        // Fallback or emulator mapped route using deviceHost
        return 'http://$deviceHost:8000/api/v1';
      case _Env.device:
        return 'http://$deviceHost:8000/api/v1';
      case _Env.production:
        return 'https://api.durian-guardian.ai/v1';
    }
  }

  /// Uploads static-file base (served by FastAPI StaticFiles at /uploads)
  static String get uploadsBaseUrl {
    switch (_activeEnv) {
      case _Env.emulator:
        return 'http://$deviceHost:8000/uploads';
      case _Env.device:
        return 'http://$deviceHost:8000/uploads';
      case _Env.production:
        return 'https://api.durian-guardian.ai/uploads';
    }
  }

  static bool get isProduction => _activeEnv == _Env.production;
  static bool get isDebug => _activeEnv != _Env.production;
}

enum _Env { emulator, device, production }
