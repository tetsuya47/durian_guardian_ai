import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/disease_detection_dtos.dart';

abstract class DiseaseDetectionLocalDataSource {
  Future<void> saveScanResult(DetectionResultDto result);
  Future<List<DetectionResultDto>> getCachedScanResults();
}

class DiseaseDetectionLocalDataSourceImpl implements DiseaseDetectionLocalDataSource {
  static const String _cacheKey = 'cached_scan_results';
  static const int _maxCachedResults = 50;

  const DiseaseDetectionLocalDataSourceImpl();

  @override
  Future<void> saveScanResult(DetectionResultDto result) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getCachedScanResults();
    final updated = [result, ...existing];
    final trimmed = updated.length > _maxCachedResults
        ? updated.sublist(0, _maxCachedResults)
        : updated;
    final jsonList = trimmed.map((r) => r.toJson()).toList();
    await prefs.setString(_cacheKey, json.encode(jsonList));
  }

  @override
  Future<List<DetectionResultDto>> getCachedScanResults() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = json.decode(raw) as List<dynamic>;
      return decoded
          .map((item) => DetectionResultDto.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
