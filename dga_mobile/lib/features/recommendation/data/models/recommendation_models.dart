class MockWeather {
  final double temperature;
  final double humidity;
  final double rainfall;
  final double windSpeed;

  const MockWeather({
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    required this.windSpeed,
  });
}

class MockCareRecommendation {
  final String title;
  final String description;
  final String priority; // 'Khẩn cấp', 'Cao', 'Trung bình', 'Thấp'

  const MockCareRecommendation({
    required this.title,
    required this.description,
    required this.priority,
  });
}

class MockCareSchedule {
  final String date;
  final String task;
  final String status; // 'Hoàn thành', 'Chờ thực hiện'

  const MockCareSchedule({
    required this.date,
    required this.task,
    required this.status,
  });
}

class MockMaterialDetail {
  final String name;
  final String type;
  final String dosage;
  final String purpose;

  const MockMaterialDetail({
    required this.name,
    required this.type,
    required this.dosage,
    required this.purpose,
  });
}

class MockRecommendationResult {
  final String riskLevel; // 'Nguy cơ thấp', 'Nguy cơ trung bình', 'Nguy cơ cao'
  final MockWeather weather;
  final List<MockCareRecommendation> careRecommendations;
  final List<MockCareSchedule> careSchedules;
  final List<MockMaterialDetail> materialDetails;
  final List<String> aiNotes;

  const MockRecommendationResult({
    required this.riskLevel,
    required this.weather,
    required this.careRecommendations,
    required this.careSchedules,
    required this.materialDetails,
    required this.aiNotes,
  });
}
