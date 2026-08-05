import '../../../../core/network/result.dart';
import '../../domain/entities/disease_detection_entities.dart';
import '../../domain/repositories/disease_detection_repository.dart';
import '../datasources/mock_detection_datasource.dart';
import '../models/disease_detection_dtos.dart';

class MockDiseaseDetectionRepository implements DiseaseDetectionRepository {
  const MockDiseaseDetectionRepository();

  @override
  Future<Result<List<ImageInfoEntity>>> getMockImages() async {
    try {
      const mockList = MockDetectionDatasource.mockImages;
      final dtos = mockList.map((mock) => ScanImageMetadataDto(
        fileName: mock.fileName,
        fileSize: mock.fileSize,
        dimensions: mock.dimensions,
        createdDate: mock.createdDate,
        device: mock.device,
        imageUrl: mock.imageUrl,
      )).toList();
      return Success(dtos.map((dto) => dto.toDomain()).toList());
    } catch (e) {
      return Failure('Không thể nạp danh sách ảnh mẫu', e);
    }
  }

  @override
  Future<Result<DetectionResultEntity>> detectDisease(ImageInfoEntity imageInfo) async {
    // Giả lập xử lý AI mất 2 giây
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Xác định kết quả dựa trên file ảnh được chọn
      if (imageInfo.fileName == 'sau_rieng_benh_01.jpg') {
        final mockDisease = MockDetectionDatasource.mockDiseases[0];
        final dto = DetectionResultDto(
          diseaseName: 'Bệnh Thán Thư (Colletotrichum)',
          confidence: 0.98,
          severity: 'Nặng',
          scanDate: '13/07/2026 16:30',
          diseaseInfo: DiseaseResponseDto(
            diseaseName: mockDisease.diseaseName,
            symptoms: mockDisease.symptoms,
            causes: mockDisease.causes,
            impactLevel: mockDisease.impactLevel,
            spreadMethod: mockDisease.spreadMethod,
            quickRecommendations: mockDisease.quickRecommendations,
          ),
          imageInfo: ScanImageMetadataDto(
            fileName: imageInfo.fileName,
            fileSize: imageInfo.fileSize,
            dimensions: imageInfo.dimensions,
            createdDate: imageInfo.createdDate,
            device: imageInfo.device,
            imageUrl: imageInfo.imageUrl,
          ),
        );
        return Success(dto.toDomain());
      } else if (imageInfo.fileName == 'la_sau_rieng_dom_la.jpg') {
        final mockDisease = MockDetectionDatasource.mockDiseases[1];
        final dto = DetectionResultDto(
          diseaseName: 'Xì Mủ Thân & Cháy Lá (Phytophthora)',
          confidence: 0.85,
          severity: 'Trung bình',
          scanDate: '13/07/2026 16:31',
          diseaseInfo: DiseaseResponseDto(
            diseaseName: mockDisease.diseaseName,
            symptoms: mockDisease.symptoms,
            causes: mockDisease.causes,
            impactLevel: mockDisease.impactLevel,
            spreadMethod: mockDisease.spreadMethod,
            quickRecommendations: mockDisease.quickRecommendations,
          ),
          imageInfo: ScanImageMetadataDto(
            fileName: imageInfo.fileName,
            fileSize: imageInfo.fileSize,
            dimensions: imageInfo.dimensions,
            createdDate: imageInfo.createdDate,
            device: imageInfo.device,
            imageUrl: imageInfo.imageUrl,
          ),
        );
        return Success(dto.toDomain());
      } else if (imageInfo.fileName == 'la_khoe_manh_01.jpg') {
        final mockDisease = MockDetectionDatasource.mockDiseases[2];
        final dto = DetectionResultDto(
          diseaseName: 'Không phát hiện bệnh hại',
          confidence: 0.99,
          severity: 'Nhẹ',
          scanDate: '13/07/2026 16:32',
          diseaseInfo: DiseaseResponseDto(
            diseaseName: mockDisease.diseaseName,
            symptoms: mockDisease.symptoms,
            causes: mockDisease.causes,
            impactLevel: mockDisease.impactLevel,
            spreadMethod: mockDisease.spreadMethod,
            quickRecommendations: mockDisease.quickRecommendations,
          ),
          imageInfo: ScanImageMetadataDto(
            fileName: imageInfo.fileName,
            fileSize: imageInfo.fileSize,
            dimensions: imageInfo.dimensions,
            createdDate: imageInfo.createdDate,
            device: imageInfo.device,
            imageUrl: imageInfo.imageUrl,
          ),
        );
        return Success(dto.toDomain());
      } else {
        return const Failure('Không thể đọc hoặc phân tích tệp ảnh này.');
      }
    } catch (e) {
      return Failure('Lỗi phân tích bệnh: ${e.toString()}', e);
    }
  }
}
