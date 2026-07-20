import 'package:flutter_test/flutter_test.dart';

// Authentication
import 'package:dga_mobile/features/authentication/domain/entities/auth_entities.dart';

// Dashboard
import 'package:dga_mobile/features/dashboard/data/models/dashboard_dtos.dart' as dash_dto;
import 'package:dga_mobile/features/dashboard/data/models/dashboard_mappers.dart';

// Disease Detection
import 'package:dga_mobile/features/disease_detection/data/models/disease_detection_dtos.dart' as det_dto;
import 'package:dga_mobile/features/disease_detection/data/models/disease_detection_mappers.dart';

// Recommendation
import 'package:dga_mobile/features/recommendation/data/models/recommendation_dtos.dart' as rec_dto;
import 'package:dga_mobile/features/recommendation/data/models/recommendation_mappers.dart';

// History
import 'package:dga_mobile/features/history/data/models/history_dtos.dart' as hist_dto;
import 'package:dga_mobile/features/history/data/models/history_mappers.dart';

// Profile
import 'package:dga_mobile/features/profile/data/models/profile_dtos.dart' as prof_dto;
import 'package:dga_mobile/features/profile/data/models/profile_mappers.dart';

// Settings
import 'package:dga_mobile/features/settings/data/models/settings_dtos.dart' as set_dto;
import 'package:dga_mobile/features/settings/data/models/settings_mappers.dart';

void main() {
  group('Mapper Layer and Entity Value-Equality Tests', () {
    test('Authentication Domain Entity Equality', () {
      const farm1 = FarmEntity(
        farmName: 'Vườn Sầu Riêng Chín Hóa',
        farmCode: 'FARM-999',
        address: 'Bến Tre, Việt Nam',
        treeCount: 150,
        joinedDate: '15/06/2026',
      );

      const farm2 = FarmEntity(
        farmName: 'Vườn Sầu Riêng Chín Hóa',
        farmCode: 'FARM-999',
        address: 'Bến Tre, Việt Nam',
        treeCount: 150,
        joinedDate: '15/06/2026',
      );

      expect(farm1, equals(farm2));
      expect(farm1.hashCode, equals(farm2.hashCode));

      const user1 = UserEntity(
        fullName: 'Trần Văn Chinh',
        email: 'chinh.tran@dga.ai',
        role: 'Chủ vườn',
        phoneNumber: '0987654321',
        workUnit: 'Hợp tác xã Bến Tre',
        address: 'Chợ Lách, Bến Tre',
        dob: '01/01/1985',
        gender: 'Nam',
        farmInfo: farm1,
      );

      const user2 = UserEntity(
        fullName: 'Trần Văn Chinh',
        email: 'chinh.tran@dga.ai',
        role: 'Chủ vườn',
        phoneNumber: '0987654321',
        workUnit: 'Hợp tác xã Bến Tre',
        address: 'Chợ Lách, Bến Tre',
        dob: '01/01/1985',
        gender: 'Nam',
        farmInfo: farm2,
      );

      expect(user1, equals(user2));
      expect(user1.hashCode, equals(user2.hashCode));
    });

    test('Dashboard Model Mappers & Value Equality', () {
      const weatherDto = dash_dto.WeatherDto(
        location: 'Bến Tre',
        temperature: 32.5,
        humidity: 78.0,
        rainfall: 0.0,
        windSpeed: 5.0,
        condition: 'Mưa rào nhẹ',
        diseaseRisk: 'Thấp',
      );

      final weatherEntity1 = weatherDto.toEntity();
      final weatherEntity2 = weatherDto.toEntity();

      expect(weatherEntity1, equals(weatherEntity2));
      expect(weatherEntity1.condition, equals('Mưa rào nhẹ'));

      const farmStatusDto = dash_dto.FarmStatusDto(
        healthyTrees: 100,
        diseasedTrees: 20,
        highRiskTrees: 5,
        totalTrees: 125,
      );

      final statusEntity1 = farmStatusDto.toEntity();
      final statusEntity2 = farmStatusDto.toEntity();

      expect(statusEntity1, equals(statusEntity2));
      expect(statusEntity1.totalTrees, equals(125));

      const statItemDto = dash_dto.StatItemDto(
        label: 'Cây đã kiểm tra',
        value: '142',
        icon: 'spa',
        color: 'success',
      );

      final statEntity1 = statItemDto.toEntity();
      final statEntity2 = statItemDto.toEntity();

      expect(statEntity1, equals(statEntity2));
      expect(statEntity1.label, equals('Cây đã kiểm tra'));

      const inspectionDto = dash_dto.InspectionItemDto(
        id: 'insp_001',
        diseaseName: 'Cây số 45',
        confidence: 0.95,
        date: '12/07/2026',
        time: '10:30',
        imageUrl: 'https://example.com/tree.jpg',
      );

      final inspectionEntity1 = inspectionDto.toEntity();
      final inspectionEntity2 = inspectionDto.toEntity();

      expect(inspectionEntity1, equals(inspectionEntity2));
      expect(inspectionEntity1.id, equals('insp_001'));
    });

    test('Disease Detection Model Mappers & Value Equality', () {
      const imageMetadataDto = det_dto.ScanImageMetadataDto(
        fileName: 'leaf.jpg',
        fileSize: '2.4 MB',
        dimensions: '3024 x 4032',
        createdDate: '12/07/2026',
        device: 'iPhone 13',
        imageUrl: 'https://example.com/leaf.jpg',
      );

      final imageEntity1 = imageMetadataDto.toEntity();
      final imageEntity2 = imageMetadataDto.toEntity();

      expect(imageEntity1, equals(imageEntity2));
      expect(imageEntity1.fileSize, equals('2.4 MB'));

      const diseaseDto = det_dto.DiseaseResponseDto(
        diseaseName: 'Bệnh xì mủ thối gốc',
        symptoms: 'Vết thối trên vỏ thân.',
        causes: 'Nấm Phytophthora.',
        impactLevel: 'Trung bình',
        spreadMethod: 'Qua nước tưới',
        quickRecommendations: ['Phun thuốc diệt nấm Fosetyl-Aluminium.'],
      );

      final diseaseEntity1 = diseaseDto.toEntity();
      final diseaseEntity2 = diseaseDto.toEntity();

      expect(diseaseEntity1, equals(diseaseEntity2));
      expect(diseaseEntity1.symptoms, equals('Vết thối trên vỏ thân.'));

      const resultDto = det_dto.DetectionResultDto(
        diseaseName: 'Bệnh xì mủ thối gốc',
        confidence: 0.94,
        severity: 'Trung bình',
        scanDate: '12/07/2026 14:35',
        diseaseInfo: diseaseDto,
        imageInfo: imageMetadataDto,
      );

      final resultEntity1 = resultDto.toEntity();
      final resultEntity2 = resultDto.toEntity();

      expect(resultEntity1, equals(resultEntity2));
      expect(resultEntity1.confidence, equals(0.94));
    });

    test('Recommendation Model Mappers & Value Equality', () {
      const weatherDto = rec_dto.WeatherDto(
        temperature: 30.5,
        humidity: 80.0,
        rainfall: 12.0,
        windSpeed: 8.0,
      );

      final advisoryEntity1 = weatherDto.toDomain();
      final advisoryEntity2 = weatherDto.toDomain();

      expect(advisoryEntity1, equals(advisoryEntity2));
      expect(advisoryEntity1.temperature, equals(30.5));

      const careDto = rec_dto.CareRecommendationDto(
        title: 'Bón phân hữu cơ định kỳ',
        description: 'Bón lân và kali đầu mùa mưa.',
        priority: 'Cao',
      );

      final careEntity1 = careDto.toDomain();
      final careEntity2 = careDto.toDomain();

      expect(careEntity1, equals(careEntity2));
      expect(careEntity1.priority, equals('Cao'));

      const scheduleDto = rec_dto.CareScheduleDto(
        date: '12/07/2026',
        task: 'Tưới nước vừa đủ',
        status: 'Chờ thực hiện',
      );

      final scheduleEntity1 = scheduleDto.toDomain();
      final scheduleEntity2 = scheduleDto.toDomain();

      expect(scheduleEntity1, equals(scheduleEntity2));
      expect(scheduleEntity1.task, equals('Tưới nước vừa đủ'));

      const materialDto = rec_dto.MaterialDetailDto(
        name: 'Fosetyl-Aluminium',
        type: 'Thuốc diệt nấm',
        dosage: '500g',
        purpose: 'Phòng ngừa thối gốc',
      );

      final materialEntity1 = materialDto.toDomain();
      final materialEntity2 = materialDto.toDomain();

      expect(materialEntity1, equals(materialEntity2));
      expect(materialEntity1.dosage, equals('500g'));

      const responseDto = rec_dto.RecommendationResponseDto(
        riskLevel: 'Thấp',
        weather: weatherDto,
        careRecommendations: [careDto],
        careSchedules: [scheduleDto],
        materialDetails: [materialDto],
        aiNotes: ['Vườn ẩm ướt cần đề phòng nấm.'],
      );

      final resultEntity1 = responseDto.toEntity();
      final resultEntity2 = responseDto.toEntity();

      expect(resultEntity1, equals(resultEntity2));
      expect(resultEntity1.aiNotes.first, equals('Vườn ẩm ướt cần đề phòng nấm.'));
    });

    test('History Model Mappers & Value Equality', () {
      const historyWeatherDto = hist_dto.HistoryWeatherDto(
        temperature: 29.5,
        humidity: 82.0,
      );

      final weatherEntity1 = historyWeatherDto.toDomain();
      final weatherEntity2 = historyWeatherDto.toDomain();

      expect(weatherEntity1, equals(weatherEntity2));
      expect(weatherEntity1.temperature, equals(29.5));

      const logDto = hist_dto.HistoryLogDto(
        id: 'log_002',
        treeName: 'Cây sầu riêng gốc Ri6',
        imageUrl: 'https://example.com/log2.jpg',
        diseaseName: 'Thối rễ tơ',
        confidence: 0.88,
        severity: 'Nhẹ',
        date: '10/07/2026',
        time: '15:20',
        inspectorName: 'Trần Văn Chinh',
        weather: historyWeatherDto,
        recommendations: ['Tưới phân kích rễ', 'Giảm lượng nước tưới'],
        riskScore: 25.0,
      );

      final logEntity1 = logDto.toEntity();
      final logEntity2 = logDto.toEntity();

      expect(logEntity1, equals(logEntity2));
      expect(logEntity1.id, equals('log_002'));
    });

    test('Profile Model Mappers & Value Equality', () {
      const statsDto = prof_dto.ProfileStatsDto(
        totalInspections: 12,
        detectedDiseases: 3,
        viewedRecommendations: 8,
        healthyTreeRate: 75.0,
      );

      final statsEntity1 = statsDto.toEntity();
      final statsEntity2 = statsDto.toEntity();

      expect(statsEntity1, equals(statsEntity2));
      expect(statsEntity1.totalInspections, equals(12));

      const farmInfoDto = prof_dto.FarmInfoDto(
        farmName: 'Vườn Sầu Riêng Chín Hóa',
        farmCode: 'FARM-999',
        address: 'Bến Tre, Việt Nam',
        treeCount: 150,
        joinedDate: '15/06/2026',
      );

      final farmEntity1 = farmInfoDto.toDomain();
      final farmEntity2 = farmInfoDto.toDomain();

      expect(farmEntity1, equals(farmEntity2));

      const userProfileDto = prof_dto.UserProfileResponseDto(
        avatarUrl: 'https://example.com/avatar.jpg',
        fullName: 'Trần Văn Chinh',
        role: 'Chủ vườn',
        email: 'chinh.tran@dga.ai',
        phoneNumber: '0987654321',
        workUnit: 'Hợp tác xã Bến Tre',
        address: 'Chợ Lách, Bến Tre',
        dob: '01/01/1985',
        gender: 'Nam',
        farmInfo: farmInfoDto,
        stats: statsDto,
      );

      final profileEntity1 = userProfileDto.toEntity();
      final profileEntity2 = userProfileDto.toEntity();

      expect(profileEntity1, equals(profileEntity2));
      expect(profileEntity1.fullName, equals('Trần Văn Chinh'));
    });

    test('Settings Model Mappers & Value Equality', () {
      const notificationSettingsDto = set_dto.NotificationSettingsDto(
        aiAlerts: true,
        weatherAlerts: true,
        diseaseAlerts: false,
        systemAlerts: true,
      );

      final notificationEntity1 = notificationSettingsDto.toEntity();
      final notificationEntity2 = notificationSettingsDto.toEntity();

      expect(notificationEntity1, equals(notificationEntity2));
      expect(notificationEntity1.diseaseAlerts, isFalse);

      const securitySettingsDto = set_dto.SecuritySettingsDto(
        biometricEnabled: true,
        hasPin: true,
      );

      final securityEntity1 = securitySettingsDto.toEntity();
      final securityEntity2 = securitySettingsDto.toEntity();

      expect(securityEntity1, equals(securityEntity2));
      expect(securityEntity1.biometricEnabled, isTrue);

      const cacheDetailsDto = set_dto.CacheDetailsDto(
        cacheSize: 12.5,
        photoSize: 45.0,
        aiCacheSize: 3.2,
      );

      final cacheEntity1 = cacheDetailsDto.toEntity();
      final cacheEntity2 = cacheDetailsDto.toEntity();

      expect(cacheEntity1, equals(cacheEntity2));
      expect(cacheEntity1.cacheSize, equals(12.5));

      const appSettingsDto = set_dto.AppSettingsDto(
        themeMode: 'Sáng',
        language: 'Tiếng Anh',
        notifications: notificationSettingsDto,
        security: securitySettingsDto,
        cache: cacheDetailsDto,
      );

      final appSettingsEntity1 = appSettingsDto.toEntity();
      final appSettingsEntity2 = appSettingsDto.toEntity();

      expect(appSettingsEntity1, equals(appSettingsEntity2));
      expect(appSettingsEntity1.themeMode, equals('Sáng'));
    });
  });
}
