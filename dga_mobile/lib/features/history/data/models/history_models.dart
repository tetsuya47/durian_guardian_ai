class MockHistoryWeather {
  final double temperature;
  final double humidity;

  const MockHistoryWeather({
    required this.temperature,
    required this.humidity,
  });
}

class MockHistoryLog {
  final String id; // Mã cây hoặc ID lượt quét, ví dụ: DGA-001
  final String treeName;
  final String imageUrl;
  final String diseaseName;
  final double confidence; // 0.0 to 1.0
  final String severity; // 'Khỏe mạnh', 'Nhẹ', 'Trung bình', 'Nặng'
  final String date; // dd/MM/yyyy
  final String time; // HH:mm
  final String inspectorName;
  final MockHistoryWeather weather;
  final List<String> recommendations;

  const MockHistoryLog({
    required this.id,
    required this.treeName,
    required this.imageUrl,
    required this.diseaseName,
    required this.confidence,
    required this.severity,
    required this.date,
    required this.time,
    required this.inspectorName,
    required this.weather,
    required this.recommendations,
  });
}
