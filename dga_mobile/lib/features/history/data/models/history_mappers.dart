import '../../domain/entities/history_entities.dart';
import 'history_dtos.dart';

extension HistoryWeatherDtoMapper on HistoryWeatherDto {
  HistoryWeatherEntity toEntity() {
    return HistoryWeatherEntity(
      temperature: temperature,
      humidity: humidity,
    );
  }
}

extension HistoryWeatherEntityMapper on HistoryWeatherEntity {
  HistoryWeatherDto toDto() {
    return HistoryWeatherDto(
      temperature: temperature,
      humidity: humidity,
    );
  }
}

extension HistoryLogDtoMapper on HistoryLogDto {
  HistoryLogEntity toEntity() {
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
      weather: weather.toEntity(),
      recommendations: recommendations,
      riskScore: riskScore,
    );
  }
}

extension HistoryLogEntityMapper on HistoryLogEntity {
  HistoryLogDto toDto() {
    return HistoryLogDto(
      id: id,
      treeName: treeName,
      imageUrl: imageUrl,
      diseaseName: diseaseName,
      confidence: confidence,
      severity: severity,
      date: date,
      time: time,
      inspectorName: inspectorName,
      weather: weather.toDto(),
      recommendations: recommendations,
      riskScore: riskScore,
    );
  }
}
