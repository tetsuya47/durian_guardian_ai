class WeatherDto {
  final String location;
  final double temperature;
  final double humidity;
  final double rainfall;
  final double windSpeed;
  final String condition;
  final String diseaseRisk;

  const WeatherDto({
    required this.location,
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    required this.windSpeed,
    required this.condition,
    required this.diseaseRisk,
  });

  factory WeatherDto.fromJson(Map<String, dynamic> json) {
    return WeatherDto(
      location: json['location'] as String? ?? '',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      rainfall: (json['rainfall'] as num?)?.toDouble() ?? 0.0,
      windSpeed: (json['wind_speed'] as num?)?.toDouble() ?? 0.0,
      condition: json['condition'] as String? ?? '',
      diseaseRisk: json['disease_risk'] as String? ?? 'Thấp',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'temperature': temperature,
      'humidity': humidity,
      'rainfall': rainfall,
      'wind_speed': windSpeed,
      'condition': condition,
      'disease_risk': diseaseRisk,
    };
  }
}

class FarmStatusDto {
  final int healthyTrees;
  final int diseasedTrees;
  final int highRiskTrees;
  final int totalTrees;

  const FarmStatusDto({
    required this.healthyTrees,
    required this.diseasedTrees,
    required this.highRiskTrees,
    required this.totalTrees,
  });

  factory FarmStatusDto.fromJson(Map<String, dynamic> json) {
    return FarmStatusDto(
      healthyTrees: json['healthy_trees'] as int? ?? 0,
      diseasedTrees: json['diseased_trees'] as int? ?? 0,
      highRiskTrees: json['high_risk_trees'] as int? ?? 0,
      totalTrees: json['total_trees'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'healthy_trees': healthyTrees,
      'diseased_trees': diseasedTrees,
      'high_risk_trees': highRiskTrees,
      'total_trees': totalTrees,
    };
  }
}

class StatItemDto {
  final String label;
  final String value;
  final String icon;
  final String color;

  const StatItemDto({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  factory StatItemDto.fromJson(Map<String, dynamic> json) {
    return StatItemDto(
      label: json['label'] as String? ?? '',
      value: json['value'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      color: json['color'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      'icon': icon,
      'color': color,
    };
  }
}

class InspectionItemDto {
  final String id;
  final String diseaseName;
  final double confidence;
  final String date;
  final String time;
  final String imageUrl;

  const InspectionItemDto({
    required this.id,
    required this.diseaseName,
    required this.confidence,
    required this.date,
    required this.time,
    required this.imageUrl,
  });

  factory InspectionItemDto.fromJson(Map<String, dynamic> json) {
    return InspectionItemDto(
      id: json['id'] as String? ?? '',
      diseaseName: json['disease_name'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'disease_name': diseaseName,
      'confidence': confidence,
      'date': date,
      'time': time,
      'image_url': imageUrl,
    };
  }
}

class DashboardOutDto {
  final KpiDataDto kpi;
  final List<DetectionBriefDto> recentDetection;
  final List<AlertBriefDto> alerts;
  final List<RiskTrendItemDto> riskTrend;

  const DashboardOutDto({
    required this.kpi,
    required this.recentDetection,
    required this.alerts,
    required this.riskTrend,
  });

  factory DashboardOutDto.fromJson(Map<String, dynamic> json) {
    return DashboardOutDto(
      kpi: KpiDataDto.fromJson(json['kpi'] as Map<String, dynamic>? ?? {}),
      recentDetection: (json['recent_detection'] as List<dynamic>?)
              ?.map((item) => DetectionBriefDto.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      alerts: (json['alerts'] as List<dynamic>?)
              ?.map((item) => AlertBriefDto.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      riskTrend: (json['risk_trend'] as List<dynamic>?)
              ?.map((item) => RiskTrendItemDto.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kpi': kpi.toJson(),
      'recent_detection': recentDetection.map((e) => e.toJson()).toList(),
      'alerts': alerts.map((e) => e.toJson()).toList(),
      'risk_trend': riskTrend.map((e) => e.toJson()).toList(),
    };
  }
}

class KpiDataDto {
  final int totalFarms;
  final int totalTrees;
  final int healthyTrees;
  final int diseasedTrees;
  final int highRiskTrees;

  const KpiDataDto({
    required this.totalFarms,
    required this.totalTrees,
    required this.healthyTrees,
    required this.diseasedTrees,
    required this.highRiskTrees,
  });

  factory KpiDataDto.fromJson(Map<String, dynamic> json) {
    return KpiDataDto(
      totalFarms: json['total_farms'] as int? ?? 0,
      totalTrees: json['total_trees'] as int? ?? 0,
      healthyTrees: json['healthy_trees'] as int? ?? 0,
      diseasedTrees: json['diseased_trees'] as int? ?? 0,
      highRiskTrees: json['high_risk_trees'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_farms': totalFarms,
      'total_trees': totalTrees,
      'healthy_trees': healthyTrees,
      'diseased_trees': diseasedTrees,
      'high_risk_trees': highRiskTrees,
    };
  }
}

class DetectionBriefDto {
  final String disease;
  final double confidence;
  final String severity;
  final String treeCode;
  final String createdAt;

  const DetectionBriefDto({
    required this.disease,
    required this.confidence,
    required this.severity,
    required this.treeCode,
    required this.createdAt,
  });

  factory DetectionBriefDto.fromJson(Map<String, dynamic> json) {
    return DetectionBriefDto(
      disease: json['disease'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      severity: json['severity'] as String? ?? '',
      treeCode: json['tree_code'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'disease': disease,
      'confidence': confidence,
      'severity': severity,
      'tree_code': treeCode,
      'created_at': createdAt,
    };
  }
}

class AlertBriefDto {
  final String title;
  final String content;
  final String createdAt;

  const AlertBriefDto({
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory AlertBriefDto.fromJson(Map<String, dynamic> json) {
    return AlertBriefDto(
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'created_at': createdAt,
    };
  }
}

class RiskTrendItemDto {
  final String date;
  final double avgRisk;

  const RiskTrendItemDto({
    required this.date,
    required this.avgRisk,
  });

  factory RiskTrendItemDto.fromJson(Map<String, dynamic> json) {
    return RiskTrendItemDto(
      date: json['date'] as String? ?? '',
      avgRisk: (json['avg_risk'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'avg_risk': avgRisk,
    };
  }
}
