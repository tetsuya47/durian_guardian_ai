import 'package:flutter/foundation.dart';

@immutable
class HistoryWeatherEntity {
  final double temperature;
  final double humidity;

  const HistoryWeatherEntity({
    required this.temperature,
    required this.humidity,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoryWeatherEntity &&
        other.temperature == temperature &&
        other.humidity == humidity;
  }

  @override
  int get hashCode {
    return Object.hash(temperature, humidity);
  }
}

@immutable
class HistoryLogEntity {
  final String id;
  final String treeName;
  final String imageUrl;
  final String diseaseName;
  final double confidence;
  final String severity;
  final String date;
  final String time;
  final String inspectorName;
  final HistoryWeatherEntity weather;
  final List<String> recommendations;
  final double riskScore;

  const HistoryLogEntity({
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoryLogEntity &&
        other.id == id &&
        other.treeName == treeName &&
        other.imageUrl == imageUrl &&
        other.diseaseName == diseaseName &&
        other.confidence == confidence &&
        other.severity == severity &&
        other.date == date &&
        other.time == time &&
        other.inspectorName == inspectorName &&
        other.weather == weather &&
        listEquals(other.recommendations, recommendations) &&
        other.riskScore == riskScore;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      treeName,
      imageUrl,
      diseaseName,
      confidence,
      severity,
      date,
      time,
      inspectorName,
      weather,
      Object.hashAll(recommendations),
      riskScore,
    );
  }
}
