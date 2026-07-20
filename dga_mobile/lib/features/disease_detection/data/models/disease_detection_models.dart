class MockImageInfo {
  final String fileName;
  final String fileSize;
  final String dimensions;
  final String createdDate;
  final String device;
  final String imageUrl;

  const MockImageInfo({
    required this.fileName,
    required this.fileSize,
    required this.dimensions,
    required this.createdDate,
    required this.device,
    required this.imageUrl,
  });
}

class MockDiseaseInfo {
  final String diseaseName;
  final String symptoms;
  final String causes;
  final String impactLevel;
  final String spreadMethod;
  final List<String> quickRecommendations;

  const MockDiseaseInfo({
    required this.diseaseName,
    required this.symptoms,
    required this.causes,
    required this.impactLevel,
    required this.spreadMethod,
    required this.quickRecommendations,
  });
}

class MockDetectionResult {
  final String diseaseName;
  final double confidence; // 0.0 to 1.0
  final String severity; // 'Nhẹ', 'Trung bình', 'Nặng'
  final String scanDate;
  final MockDiseaseInfo diseaseInfo;
  final MockImageInfo imageInfo;

  const MockDetectionResult({
    required this.diseaseName,
    required this.confidence,
    required this.severity,
    required this.scanDate,
    required this.diseaseInfo,
    required this.imageInfo,
  });
}
