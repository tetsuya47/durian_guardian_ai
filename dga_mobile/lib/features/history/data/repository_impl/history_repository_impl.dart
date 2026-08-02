import 'dart:convert';
import '../../../../core/network/result.dart';
import '../../../../core/errors/failure.dart' as err;
import '../../../../services/storage_service.dart';
import '../../domain/entities/history_entities.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_remote_datasource.dart';
import '../models/history_dtos.dart';
import '../models/history_mappers.dart';
import '../../../../core/network/environment_config.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryRemoteDataSource _remoteDataSource;
  final StorageService _storageService;

  const HistoryRepositoryImpl(this._remoteDataSource, this._storageService);

  @override
  Future<Result<List<HistoryLogEntity>>> getHistoryLogs() async {
    try {
      final trees = await _remoteDataSource.getTrees();
      final List<HistoryLogDto> allLogs = [];

      final treeMap = <String, String>{};
      for (final tree in trees) {
        final id = tree['id'] as String?;
        final code = tree['tree_code'] as String? ?? 'Cây chưa đặt tên';
        if (id != null && id.isNotEmpty) {
          treeMap[id] = code;
        }
      }
      const fallbackTreeId = '6a6cc2ba3432b70022fba65d';
      if (!treeMap.containsKey(fallbackTreeId)) {
        treeMap[fallbackTreeId] = 'Cây sầu riêng #01 (Mặc định)';
      }

      // Query histories in parallel for target trees (up to 150 sampled trees + fallback)
      final entries = treeMap.entries.toList();
      final targetEntries = entries.length > 150 ? entries.sublist(0, 150) : entries;
      const batchSize = 30;
      for (var i = 0; i < targetEntries.length; i += batchSize) {
        final batch = targetEntries.sublist(i, i + batchSize > targetEntries.length ? targetEntries.length : i + batchSize);
        final futures = batch.map((entry) async {
          final treeId = entry.key;
          final treeCode = entry.value;
          try {
            final historyResponse = await _remoteDataSource.getTreeHistory(treeId);
            for (final record in historyResponse.diseaseHistory) {
              String dateStr = '';
              String timeStr = '';
              try {
                final parsed = DateTime.parse(record.createdAt).toLocal();
                dateStr = '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
                timeStr = '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
              } catch (_) {
                dateStr = record.createdAt;
              }

              // ─── Resolve risk score, recommendations & weather ───
              double riskVal = 50.0;
              List<String> recommendations = _getMockRecommendations(record.diseaseName);
              double temperature = 0;
              double humidity = 0;

              final cacheKey = 'metadata_${treeId}_${record.createdAt}';
              final cachedString = _storageService.getString(cacheKey);
              if (cachedString != null && cachedString.isNotEmpty) {
                try {
                  final cachedMeta = json.decode(cachedString) as Map<String, dynamic>;
                  riskVal = (cachedMeta['risk_score'] as num?)?.toDouble() ?? 50.0;
                  recommendations = (cachedMeta['recommendations'] as List<dynamic>?)
                          ?.map((e) => e as String)
                          .toList() ??
                      recommendations;
                  temperature = (cachedMeta['temperature'] as num?)?.toDouble() ?? 0;
                  humidity = (cachedMeta['humidity'] as num?)?.toDouble() ?? 0;
                } catch (_) {}
              } else {
                // Fallback default calculation matching server state
                final lowerDisease = record.diseaseName.toLowerCase();
                if (lowerDisease.contains('healthy') || lowerDisease.contains('không phát hiện')) {
                  riskVal = 20.0;
                } else if (lowerDisease.contains('rot') || lowerDisease.contains('phytophthora') || lowerDisease.contains('thối') || lowerDisease.contains('xì mủ')) {
                  riskVal = 90.0;
                }
              }

              allLogs.add(
                HistoryLogDto(
                  id: record.id,
                  treeName: treeCode,
                  imageUrl: _resolveUrl(record.imageUrl),
                  diseaseName: _translateDisease(record.diseaseName),
                  confidence: record.confidence,
                  severity: _translateSeverity(record.severity),
                  date: dateStr,
                  time: timeStr,
                  inspectorName: 'Hệ thống AI',
                  weather: HistoryWeatherDto(
                    temperature: temperature,
                    humidity: humidity,
                  ),
                  recommendations: recommendations,
                  riskScore: riskVal,
                ),
              );
            }
          } catch (_) {
            // Suppress errors for a single tree, continue loading other trees
          }
        });
        await Future.wait(futures);
      }

      // Sort logs descending by date/time (or raw createdAt)
      allLogs.sort((a, b) {
        // Try parsing combining date (DD/MM/YYYY) and time (HH:MM) to sort correctly
        try {
          final partsA = a.date.split('/');
          final timePartsA = a.time.split(':');
          final dateA = DateTime(
            int.parse(partsA[2]),
            int.parse(partsA[1]),
            int.parse(partsA[0]),
            int.parse(timePartsA[0]),
            int.parse(timePartsA[1]),
          );

          final partsB = b.date.split('/');
          final timePartsB = b.time.split(':');
          final dateB = DateTime(
            int.parse(partsB[2]),
            int.parse(partsB[1]),
            int.parse(partsB[0]),
            int.parse(timePartsB[0]),
            int.parse(timePartsB[1]),
          );
          return dateB.compareTo(dateA); // Descending order
        } catch (_) {
          return b.date.compareTo(a.date);
        }
      });

      return Success(allLogs.map((dto) => dto.toEntity()).toList());
    } catch (e) {
      return Failure(err.Failure.fromException(e).message, e);
    }
  }

  String _translateDisease(String name) {
    switch (name.toLowerCase()) {
      case 'healthy':
        return 'Không phát hiện bệnh hại';
      case 'root rot':
        return 'Bệnh thối rễ';
      case 'leaf spot':
        return 'Bệnh đốm lá';
      case 'fruit borer':
        return 'Sâu đục quả';
      case 'powdery mildew':
        return 'Bệnh phấn trắng';
      case 'phytophthora':
        return 'Bệnh xì mủ thân Phytophthora';
      default:
        return name;
    }
  }

  String _translateSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return 'Nhẹ';
      case 'medium':
        return 'Trung bình';
      case 'high':
        return 'Nặng';
      default:
        return severity;
    }
  }

  List<String> _getMockRecommendations(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('spot') || lower.contains('đốm lá')) {
      return [
        'Cắt tỉa các cành lá nhiễm bệnh và tiêu hủy xa vườn sầu riêng.',
        'Phun thuốc trị nấm gốc Đồng hoặc Carbendazim định kỳ 7-10 ngày.',
        'Bón phân cân đối, tránh bón thừa đạm làm tăng nguy cơ lây lan.'
      ];
    } else if (lower.contains('rot') || lower.contains('phytophthora') || lower.contains('thối') || lower.contains('xì mủ')) {
      return [
        'Thoát nước nhanh cho vườn sầu riêng, tránh ngập úng gốc.',
        'Sử dụng chế phẩm sinh học Trichoderma bón gốc để hạn chế nấm hại.',
        'Cạo nhẹ vết mủ thân và quét thuốc Aliette hoặc Metalaxyl lên vết thương.'
      ];
    } else {
      return [
        'Duy trì chế độ chăm sóc hiện tại của vườn.',
        'Kiểm tra định kỳ hàng tuần để phát hiện sớm sâu bệnh.'
      ];
    }
  }

  String _resolveUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return '';
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }
    var cleaned = relativePath.replaceAll(r'\', '/');
    if (cleaned.contains('/uploads/')) {
      cleaned = cleaned.substring(cleaned.indexOf('/uploads/') + '/uploads/'.length);
    } else if (cleaned.startsWith('uploads/')) {
      cleaned = cleaned.substring('uploads/'.length);
    }
    cleaned = cleaned.replaceFirst(RegExp(r'^\.\/'), '').replaceFirst(RegExp(r'^\/'), '');
    return '${EnvironmentConfig.uploadsBaseUrl}/$cleaned';
  }
}
