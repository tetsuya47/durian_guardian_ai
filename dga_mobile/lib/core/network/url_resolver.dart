import 'environment_config.dart';

/// Centralized utility to resolve and sanitize image URLs across the app.
class UrlResolver {
  UrlResolver._();

  static String resolve(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return '';

    String url = rawUrl.trim();

    // 1. Assets
    if (url.startsWith('assets/')) {
      return url;
    }

    // 2. Local device files
    if (url.startsWith('file:') ||
        url.startsWith('/data/') ||
        url.startsWith('/var/mobile/') ||
        url.contains('/cache/') ||
        url.contains('storage/emulated/')) {
      return url;
    }

    // 3. Normalize IP / Domain (127.0.0.1, localhost, 10.0.2.2 -> EnvironmentConfig.deviceHost)
    final activeHost = EnvironmentConfig.deviceHost;
    url = url
        .replaceAll('127.0.0.1:8000', '$activeHost:8000')
        .replaceAll('localhost:8000', '$activeHost:8000')
        .replaceAll('10.0.2.2:8000', '$activeHost:8000');

    // 4. Relative upload paths (e.g. /uploads/abc.jpg or uploads/abc.jpg)
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      var cleaned = url.replaceAll(r'\', '/');
      if (cleaned.contains('/uploads/')) {
        cleaned = cleaned.substring(cleaned.indexOf('/uploads/') + '/uploads/'.length);
      } else if (cleaned.startsWith('uploads/')) {
        cleaned = cleaned.substring('uploads/'.length);
      }
      cleaned = cleaned.replaceFirst(RegExp(r'^\.\/'), '').replaceFirst(RegExp(r'^\/'), '');
      return '${EnvironmentConfig.uploadsBaseUrl}/$cleaned';
    }

    return url;
  }
}
