import 'package:flutter/foundation.dart';

@immutable
class WeatherAdvisoryEntity {
  final double temperature;
  final double humidity;
  final double rainfall;
  final double windSpeed;

  const WeatherAdvisoryEntity({
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    required this.windSpeed,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeatherAdvisoryEntity &&
        other.temperature == temperature &&
        other.humidity == humidity &&
        other.rainfall == rainfall &&
        other.windSpeed == windSpeed;
  }

  @override
  int get hashCode {
    return Object.hash(temperature, humidity, rainfall, windSpeed);
  }
}

@immutable
class CareRecommendationEntity {
  final String title;
  final String description;
  final String priority;

  const CareRecommendationEntity({
    required this.title,
    required this.description,
    required this.priority,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CareRecommendationEntity &&
        other.title == title &&
        other.description == description &&
        other.priority == priority;
  }

  @override
  int get hashCode {
    return Object.hash(title, description, priority);
  }
}

@immutable
class CareScheduleEntity {
  final String date;
  final String task;
  final String status;

  const CareScheduleEntity({
    required this.date,
    required this.task,
    required this.status,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CareScheduleEntity &&
        other.date == date &&
        other.task == task &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(date, task, status);
  }
}

@immutable
class MaterialDetailEntity {
  final String name;
  final String type;
  final String dosage;
  final String purpose;

  const MaterialDetailEntity({
    required this.name,
    required this.type,
    required this.dosage,
    required this.purpose,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MaterialDetailEntity &&
        other.name == name &&
        other.type == type &&
        other.dosage == dosage &&
        other.purpose == purpose;
  }

  @override
  int get hashCode {
    return Object.hash(name, type, dosage, purpose);
  }
}

@immutable
class RecommendationResultEntity {
  final String riskLevel;
  final WeatherAdvisoryEntity weather;
  final List<CareRecommendationEntity> careRecommendations;
  final List<CareScheduleEntity> careSchedules;
  final List<MaterialDetailEntity> materialDetails;
  final List<String> aiNotes;

  const RecommendationResultEntity({
    required this.riskLevel,
    required this.weather,
    required this.careRecommendations,
    required this.careSchedules,
    required this.materialDetails,
    required this.aiNotes,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecommendationResultEntity &&
        other.riskLevel == riskLevel &&
        other.weather == weather &&
        listEquals(other.careRecommendations, careRecommendations) &&
        listEquals(other.careSchedules, careSchedules) &&
        listEquals(other.materialDetails, materialDetails) &&
        listEquals(other.aiNotes, aiNotes);
  }

  @override
  int get hashCode {
    return Object.hash(
      riskLevel,
      weather,
      Object.hashAll(careRecommendations),
      Object.hashAll(careSchedules),
      Object.hashAll(materialDetails),
      Object.hashAll(aiNotes),
    );
  }
}
