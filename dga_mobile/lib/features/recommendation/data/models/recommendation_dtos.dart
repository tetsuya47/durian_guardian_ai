import '../../domain/entities/recommendation_entities.dart';

class WeatherDto {
  final double temperature;
  final double humidity;
  final double rainfall;
  final double windSpeed;

  const WeatherDto({
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    required this.windSpeed,
  });

  factory WeatherDto.fromJson(Map<String, dynamic> json) {
    return WeatherDto(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      rainfall: (json['rainfall'] as num?)?.toDouble() ?? 0.0,
      windSpeed: (json['wind_speed'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'rainfall': rainfall,
      'wind_speed': windSpeed,
    };
  }

  WeatherAdvisoryEntity toDomain() {
    return WeatherAdvisoryEntity(
      temperature: temperature,
      humidity: humidity,
      rainfall: rainfall,
      windSpeed: windSpeed,
    );
  }
}

class CareRecommendationDto {
  final String title;
  final String description;
  final String priority;

  const CareRecommendationDto({
    required this.title,
    required this.description,
    required this.priority,
  });

  factory CareRecommendationDto.fromJson(Map<String, dynamic> json) {
    return CareRecommendationDto(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priority: json['priority'] as String? ?? 'Trung bình',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'priority': priority,
    };
  }

  CareRecommendationEntity toDomain() {
    return CareRecommendationEntity(
      title: title,
      description: description,
      priority: priority,
    );
  }
}

class CareScheduleDto {
  final String date;
  final String task;
  final String status;

  const CareScheduleDto({
    required this.date,
    required this.task,
    required this.status,
  });

  factory CareScheduleDto.fromJson(Map<String, dynamic> json) {
    return CareScheduleDto(
      date: json['date'] as String? ?? '',
      task: json['task'] as String? ?? '',
      status: json['status'] as String? ?? 'Chờ thực hiện',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'task': task,
      'status': status,
    };
  }

  CareScheduleEntity toDomain() {
    return CareScheduleEntity(
      date: date,
      task: task,
      status: status,
    );
  }
}

class MaterialDetailDto {
  final String name;
  final String type;
  final String dosage;
  final String purpose;

  const MaterialDetailDto({
    required this.name,
    required this.type,
    required this.dosage,
    required this.purpose,
  });

  factory MaterialDetailDto.fromJson(Map<String, dynamic> json) {
    return MaterialDetailDto(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      purpose: json['purpose'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'dosage': dosage,
      'purpose': purpose,
    };
  }

  MaterialDetailEntity toDomain() {
    return MaterialDetailEntity(
      name: name,
      type: type,
      dosage: dosage,
      purpose: purpose,
    );
  }
}

class RecommendationResponseDto {
  final String riskLevel;
  final WeatherDto weather;
  final List<CareRecommendationDto> careRecommendations;
  final List<CareScheduleDto> careSchedules;
  final List<MaterialDetailDto> materialDetails;
  final List<String> aiNotes;

  const RecommendationResponseDto({
    required this.riskLevel,
    required this.weather,
    required this.careRecommendations,
    required this.careSchedules,
    required this.materialDetails,
    required this.aiNotes,
  });

  factory RecommendationResponseDto.fromJson(Map<String, dynamic> json) {
    return RecommendationResponseDto(
      riskLevel: json['risk_level'] as String? ?? 'Nguy cơ trung bình',
      weather: WeatherDto.fromJson(json['weather'] as Map<String, dynamic>? ?? const {}),
      careRecommendations: (json['care_recommendations'] as List<dynamic>?)
              ?.map((e) => CareRecommendationDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      careSchedules: (json['care_schedules'] as List<dynamic>?)
              ?.map((e) => CareScheduleDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      materialDetails: (json['material_details'] as List<dynamic>?)
              ?.map((e) => MaterialDetailDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      aiNotes: (json['ai_notes'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'risk_level': riskLevel,
      'weather': weather.toJson(),
      'care_recommendations': careRecommendations.map((e) => e.toJson()).toList(),
      'care_schedules': careSchedules.map((e) => e.toJson()).toList(),
      'material_details': materialDetails.map((e) => e.toJson()).toList(),
      'ai_notes': aiNotes,
    };
  }

  RecommendationResultEntity toDomain() {
    return RecommendationResultEntity(
      riskLevel: riskLevel,
      weather: weather.toDomain(),
      careRecommendations: careRecommendations.map((e) => e.toDomain()).toList(),
      careSchedules: careSchedules.map((e) => e.toDomain()).toList(),
      materialDetails: materialDetails.map((e) => e.toDomain()).toList(),
      aiNotes: aiNotes,
    );
  }
}
