class WeatherCurrentDto {
  final String locationName;
  final double tempCelsius;
  final double feelsLikeCelsius;
  final int humidityPercent;
  final double windSpeedMS;
  final String description;
  final String iconUrl;
  final String fungalDiseaseRisk;
  final String agriculturalAdvice;

  const WeatherCurrentDto({
    required this.locationName,
    required this.tempCelsius,
    required this.feelsLikeCelsius,
    required this.humidityPercent,
    required this.windSpeedMS,
    required this.description,
    required this.iconUrl,
    required this.fungalDiseaseRisk,
    required this.agriculturalAdvice,
  });

  factory WeatherCurrentDto.fromJson(Map<String, dynamic> json) {
    return WeatherCurrentDto(
      locationName: json['location_name'] as String? ?? 'Vườn Sầu Riêng',
      tempCelsius: (json['temp_celsius'] as num?)?.toDouble() ?? 29.0,
      feelsLikeCelsius: (json['feels_like_celsius'] as num?)?.toDouble() ?? 30.5,
      humidityPercent: json['humidity_percent'] as int? ?? 75,
      windSpeedMS: (json['wind_speed_m_s'] as num?)?.toDouble() ?? 2.5,
      description: json['description'] as String? ?? 'Thời tiết ổn định',
      iconUrl: json['icon_url'] as String? ?? 'https://openweathermap.org/img/wn/02d@2x.png',
      fungalDiseaseRisk: json['fungal_disease_risk'] as String? ?? 'LOW',
      agriculturalAdvice: json['agricultural_advice'] as String? ?? 'Thời tiết tốt cho cây sầu riêng phát triển.',
    );
  }
}
