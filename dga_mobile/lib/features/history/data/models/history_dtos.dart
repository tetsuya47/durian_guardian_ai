import '../../domain/entities/history_entities.dart';

class HistoryWeatherDto {
  final double temperature;
  final double humidity;

  const HistoryWeatherDto({
    required this.temperature,
    required this.humidity,
  });

  factory HistoryWeatherDto.fromJson(Map<String, dynamic> json) {
    return HistoryWeatherDto(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
    };
  }

  HistoryWeatherEntity toDomain() {
    return HistoryWeatherEntity(
      temperature: temperature,
      humidity: humidity,
    );
  }
}

class HistoryLogDto {
  final String id;
  final String treeName;
  final String imageUrl;
  final String diseaseName;
  final double confidence;
  final String severity;
  final String date;
  final String time;
  final String inspectorName;
  final HistoryWeatherDto weather;
  final List<String> recommendations;
  final double riskScore;

  const HistoryLogDto({
    required this.id,
    required this.treeName,
    required this.imageUrl,
    required this.diseaseName,
    required this.confidence,
    required this.severity,
    required this.date,
    required this.time,
    required this.inspectorName,
    required this.weather,
    required this.recommendations,
    required this.riskScore,
  });

  factory HistoryLogDto.fromJson(Map<String, dynamic> json) {
    return HistoryLogDto(
      id: json['id'] as String? ?? '',
      treeName: json['tree_name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      diseaseName: json['disease_name'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      severity: json['severity'] as String? ?? '',
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      inspectorName: json['inspector_name'] as String? ?? '',
      weather: HistoryWeatherDto.fromJson(
          json['weather'] as Map<String, dynamic>? ?? const {}),
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 50.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tree_name': treeName,
      'image_url': imageUrl,
      'disease_name': diseaseName,
      'confidence': confidence,
      'severity': severity,
      'date': date,
      'time': time,
      'inspector_name': inspectorName,
      'weather': weather.toJson(),
      'recommendations': recommendations,
      'risk_score': riskScore,
    };
  }

  HistoryLogEntity toDomain() {
    return HistoryLogEntity(
      id: id,
      treeName: treeName,
      imageUrl: imageUrl,
      diseaseName: diseaseName,
      confidence: confidence,
      severity: severity,
      date: date,
      time: time,
      inspectorName: inspectorName,
      weather: weather.toDomain(),
      recommendations: recommendations,
      riskScore: riskScore,
    );
  }
}

class HistoryResponseDto {
  final List<HistoryLogDto> logs;

  const HistoryResponseDto({required this.logs});

  factory HistoryResponseDto.fromJson(Map<String, dynamic> json) {
    return HistoryResponseDto(
      logs: (json['logs'] as List<dynamic>?)
              ?.map((e) => HistoryLogDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'logs': logs.map((e) => e.toJson()).toList(),
    };
  }
}

class TreeHistoryResponseDto {
  final String treeId;
  final List<DiseaseHistoryRecordDto> diseaseHistory;

  const TreeHistoryResponseDto({
    required this.treeId,
    required this.diseaseHistory,
  });

  factory TreeHistoryResponseDto.fromJson(Map<String, dynamic> json) {
    return TreeHistoryResponseDto(
      treeId: json['tree_id'] as String? ?? '',
      diseaseHistory: (json['disease_history'] as List<dynamic>?)
              ?.map((e) => DiseaseHistoryRecordDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tree_id': treeId,
      'disease_history': diseaseHistory.map((e) => e.toJson()).toList(),
    };
  }
}

class DiseaseHistoryRecordDto {
  final String id;
  final String treeId;
  final String diseaseName;
  final String severity;
  final double confidence;
  final String imageUrl;
  final String createdAt;

  const DiseaseHistoryRecordDto({
    required this.id,
    required this.treeId,
    required this.diseaseName,
    required this.severity,
    required this.confidence,
    required this.imageUrl,
    required this.createdAt,
  });

  factory DiseaseHistoryRecordDto.fromJson(Map<String, dynamic> json) {
    return DiseaseHistoryRecordDto(
      id: json['id'] as String? ?? '',
      treeId: json['tree_id'] as String? ?? '',
      diseaseName: json['disease_name'] as String? ?? '',
      severity: json['severity'] as String? ?? 'low',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tree_id': treeId,
      'disease_name': diseaseName,
      'severity': severity,
      'confidence': confidence,
      'image_url': imageUrl,
      'created_at': createdAt,
    };
  }
}
