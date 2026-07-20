import 'dashboard_dtos.dart';
import '../../domain/entities/dashboard_entities.dart';

extension WeatherDtoMapper on WeatherDto {
  WeatherEntity toEntity() {
    return WeatherEntity(
      location: location,
      temperature: temperature,
      humidity: humidity,
      rainfall: rainfall,
      windSpeed: windSpeed,
      condition: condition,
      diseaseRisk: diseaseRisk,
    );
  }
}

extension FarmStatusDtoMapper on FarmStatusDto {
  FarmStatusEntity toEntity() {
    return FarmStatusEntity(
      healthyTrees: healthyTrees,
      diseasedTrees: diseasedTrees,
      highRiskTrees: highRiskTrees,
      totalTrees: totalTrees,
    );
  }
}

extension StatItemDtoMapper on StatItemDto {
  StatItemEntity toEntity() {
    return StatItemEntity(
      label: label,
      value: value,
      icon: icon,
      color: color,
    );
  }
}

extension InspectionItemDtoMapper on InspectionItemDto {
  InspectionItemEntity toEntity() {
    return InspectionItemEntity(
      id: id,
      diseaseName: diseaseName,
      confidence: confidence,
      date: date,
      time: time,
      imageUrl: imageUrl,
    );
  }
}
