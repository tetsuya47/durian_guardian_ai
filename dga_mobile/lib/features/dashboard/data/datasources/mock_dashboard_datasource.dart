import 'package:flutter/material.dart';
import '../models/dashboard_data_models.dart';
import '../../../../core/theme/app_colors.dart';

class MockDashboardDatasource {
  MockDashboardDatasource._();

  static const WeatherInfo mockWeather = WeatherInfo(
    location: 'Phong Điền, Cần Thơ',
    temperature: 28.5,
    humidity: 82.0,
    rainfall: 12.5,
    windSpeed: 4.2,
    condition: 'Mưa rào nhẹ',
    riskLevel: 'Thấp',
    weatherIcon: Icons.cloudy_snowing,
  );

  static const FarmStatus mockFarmStatus = FarmStatus(
    healthyTrees: 342,
    diseasedTrees: 18,
    highRiskTrees: 8,
    totalTrees: 368,
    inspectionToday: 24,
  );

  static const List<StatItem> mockStatistics = [
    StatItem(
      title: 'Cây Khỏe Mạnh',
      value: '342',
      icon: Icons.check_circle_outline,
      color: AppColors.success,
    ),
    StatItem(
      title: 'Cây Bị Bệnh',
      value: '18',
      icon: Icons.error_outline,
      color: AppColors.error,
    ),
    StatItem(
      title: 'Rủi Ro Cao',
      value: '8',
      icon: Icons.warning_amber_outlined,
      color: AppColors.warning,
    ),
    StatItem(
      title: 'Lượt Quét Hôm Nay',
      value: '24',
      icon: Icons.qr_code_scanner,
      color: AppColors.primary,
    ),
  ];

  static const List<InspectionItem> mockInspections = [
    InspectionItem(
      id: 'ISP-001',
      diseaseName: 'Xì mủ thân (Phytophthora)',
      confidence: 0.94,
      date: '13/07/2026 14:32',
      status: 'Danger',
      leafImageUrl: 'https://images.unsplash.com/photo-1598902108854-10e335adac99?auto=format&fit=crop&w=100&q=80',
    ),
    InspectionItem(
      id: 'ISP-002',
      diseaseName: 'Không phát hiện bệnh hại',
      confidence: 0.99,
      date: '13/07/2026 10:15',
      status: 'Healthy',
      leafImageUrl: 'https://images.unsplash.com/photo-1502082553048-f009c37129b9?auto=format&fit=crop&w=100&q=80',
    ),
    InspectionItem(
      id: 'ISP-003',
      diseaseName: 'Thán thư (Colletotrichum)',
      confidence: 0.78,
      date: '12/07/2026 16:45',
      status: 'Warning',
      leafImageUrl: 'https://images.unsplash.com/photo-1597423498219-04418210827d?auto=format&fit=crop&w=100&q=80',
    ),
    InspectionItem(
      id: 'ISP-004',
      diseaseName: 'Cháy lá (Rhizoctonia)',
      confidence: 0.85,
      date: '12/07/2026 09:20',
      status: 'Danger',
      leafImageUrl: 'https://images.unsplash.com/photo-1588880331179-bc9b93a8c5c8?auto=format&fit=crop&w=100&q=80',
    ),
    InspectionItem(
      id: 'ISP-005',
      diseaseName: 'Không phát hiện bệnh hại',
      confidence: 0.98,
      date: '11/07/2026 15:10',
      status: 'Healthy',
      leafImageUrl: 'https://images.unsplash.com/photo-1463936575829-25148e1db1b8?auto=format&fit=crop&w=100&q=80',
    ),
  ];
}
