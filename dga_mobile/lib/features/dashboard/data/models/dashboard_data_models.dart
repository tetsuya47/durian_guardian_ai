import 'package:flutter/material.dart';

class WeatherInfo {
  final String location;
  final double temperature;
  final double humidity;
  final double rainfall;
  final double windSpeed;
  final String condition;
  final String riskLevel;
  final IconData weatherIcon;

  const WeatherInfo({
    required this.location,
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    required this.windSpeed,
    required this.condition,
    required this.riskLevel,
    required this.weatherIcon,
  });
}

class FarmStatus {
  final int healthyTrees;
  final int diseasedTrees;
  final int highRiskTrees;
  final int totalTrees;
  final int inspectionToday;

  const FarmStatus({
    required this.healthyTrees,
    required this.diseasedTrees,
    required this.highRiskTrees,
    required this.totalTrees,
    required this.inspectionToday,
  });
}

class StatItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class InspectionItem {
  final String id;
  final String diseaseName;
  final double confidence;
  final String date;
  final String status; // 'Healthy', 'Warning', 'Danger'
  final String leafImageUrl;

  const InspectionItem({
    required this.id,
    required this.diseaseName,
    required this.confidence,
    required this.date,
    required this.status,
    required this.leafImageUrl,
  });
}
