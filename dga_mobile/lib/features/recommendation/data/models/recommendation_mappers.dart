import '../../domain/entities/recommendation_entities.dart';
import 'recommendation_dtos.dart';

extension WeatherDtoMapper on WeatherDto {
  WeatherAdvisoryEntity toEntity() {
    return WeatherAdvisoryEntity(
      temperature: temperature,
      humidity: humidity,
      rainfall: rainfall,
      windSpeed: windSpeed,
    );
  }
}

extension WeatherAdvisoryEntityMapper on WeatherAdvisoryEntity {
  WeatherDto toDto() {
    return WeatherDto(
      temperature: temperature,
      humidity: humidity,
      rainfall: rainfall,
      windSpeed: windSpeed,
    );
  }
}

extension CareRecommendationDtoMapper on CareRecommendationDto {
  CareRecommendationEntity toEntity() {
    return CareRecommendationEntity(
      title: title,
      description: description,
      priority: priority,
    );
  }
}

extension CareRecommendationEntityMapper on CareRecommendationEntity {
  CareRecommendationDto toDto() {
    return CareRecommendationDto(
      title: title,
      description: description,
      priority: priority,
    );
  }
}

extension CareScheduleDtoMapper on CareScheduleDto {
  CareScheduleEntity toEntity() {
    return CareScheduleEntity(
      date: date,
      task: task,
      status: status,
    );
  }
}

extension CareScheduleEntityMapper on CareScheduleEntity {
  CareScheduleDto toDto() {
    return CareScheduleDto(
      date: date,
      task: task,
      status: status,
    );
  }
}

extension MaterialDetailDtoMapper on MaterialDetailDto {
  MaterialDetailEntity toEntity() {
    return MaterialDetailEntity(
      name: name,
      type: type,
      dosage: dosage,
      purpose: purpose,
    );
  }
}

extension MaterialDetailEntityMapper on MaterialDetailEntity {
  MaterialDetailDto toDto() {
    return MaterialDetailDto(
      name: name,
      type: type,
      dosage: dosage,
      purpose: purpose,
    );
  }
}

extension RecommendationResponseDtoMapper on RecommendationResponseDto {
  RecommendationResultEntity toEntity() {
    return RecommendationResultEntity(
      riskLevel: riskLevel,
      weather: weather.toEntity(),
      careRecommendations: careRecommendations.map((e) => e.toEntity()).toList(),
      careSchedules: careSchedules.map((e) => e.toEntity()).toList(),
      materialDetails: materialDetails.map((e) => e.toEntity()).toList(),
      aiNotes: aiNotes,
    );
  }
}

extension RecommendationResultEntityMapper on RecommendationResultEntity {
  RecommendationResponseDto toDto() {
    return RecommendationResponseDto(
      riskLevel: riskLevel,
      weather: weather.toDto(),
      careRecommendations: careRecommendations.map((e) => e.toDto()).toList(),
      careSchedules: careSchedules.map((e) => e.toDto()).toList(),
      materialDetails: materialDetails.map((e) => e.toDto()).toList(),
      aiNotes: aiNotes,
    );
  }
}
