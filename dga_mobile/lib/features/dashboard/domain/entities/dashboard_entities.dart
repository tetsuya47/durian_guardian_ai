import 'package:flutter/material.dart';

@immutable
class WeatherEntity {
  final String location;
  final double temperature;
  final double humidity;
  final double rainfall;
  final double windSpeed;
  final String condition;
  final String diseaseRisk;

  const WeatherEntity({
    required this.location,
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    required this.windSpeed,
    required this.condition,
    required this.diseaseRisk,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeatherEntity &&
        other.location == location &&
        other.temperature == temperature &&
        other.humidity == humidity &&
        other.rainfall == rainfall &&
        other.windSpeed == windSpeed &&
        other.condition == condition &&
        other.diseaseRisk == diseaseRisk;
  }

  @override
  int get hashCode => Object.hash(location, temperature, humidity, rainfall, windSpeed, condition, diseaseRisk);
}

@immutable
class AlertEntity {
  final String title;
  final String content;
  final String createdAt;

  const AlertEntity({
    required this.title,
    required this.content,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlertEntity &&
        other.title == title &&
        other.content == content &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(title, content, createdAt);
}

@immutable
class FarmStatusEntity {
  final int healthyTrees;
  final int diseasedTrees;
  final int highRiskTrees;
  final int totalTrees;

  const FarmStatusEntity({
    required this.healthyTrees,
    required this.diseasedTrees,
    required this.highRiskTrees,
    required this.totalTrees,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FarmStatusEntity &&
        other.healthyTrees == healthyTrees &&
        other.diseasedTrees == diseasedTrees &&
        other.highRiskTrees == highRiskTrees &&
        other.totalTrees == totalTrees;
  }

  @override
  int get hashCode => Object.hash(healthyTrees, diseasedTrees, highRiskTrees, totalTrees);
}

@immutable
class StatItemEntity {
  final String label;
  final String value;
  final String icon;
  final String color;
  final String? subtitle;
  final bool? isPositiveTrend;

  const StatItemEntity({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.isPositiveTrend,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StatItemEntity &&
        other.label == label &&
        other.value == value &&
        other.icon == icon &&
        other.color == color &&
        other.subtitle == subtitle &&
        other.isPositiveTrend == isPositiveTrend;
  }

  @override
  int get hashCode => Object.hash(label, value, icon, color, subtitle, isPositiveTrend);
}

@immutable
class InspectionItemEntity {
  final String id;
  final String diseaseName;
  final double confidence;
  final String date;
  final String time;
  final String imageUrl;

  const InspectionItemEntity({
    required this.id,
    required this.diseaseName,
    required this.confidence,
    required this.date,
    required this.time,
    required this.imageUrl,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InspectionItemEntity &&
        other.id == id &&
        other.diseaseName == diseaseName &&
        other.confidence == confidence &&
        other.date == date &&
        other.time == time &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode => Object.hash(id, diseaseName, confidence, date, time, imageUrl);
}
