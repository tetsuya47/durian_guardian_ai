import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_api_client.dart';
import '../models/weather_dtos.dart';

abstract class WeatherRemoteDataSource {
  Future<WeatherCurrentDto> getCurrentWeather();
}

class WeatherRemoteDataSourceImpl implements WeatherRemoteDataSource {
  final DioApiClient _apiClient;

  const WeatherRemoteDataSourceImpl(this._apiClient);

  @override
  Future<WeatherCurrentDto> getCurrentWeather() async {
    final response = await _apiClient.request<WeatherCurrentDto>(
      path: ApiEndpoints.weatherCurrent,
      method: 'GET',
      decoder: (json) => WeatherCurrentDto.fromJson(json as Map<String, dynamic>),
    );

    return response.data ??
        const WeatherCurrentDto(
          locationName: 'Trang Trại Sầu Riêng',
          tempCelsius: 29.0,
          feelsLikeCelsius: 30.5,
          humidityPercent: 78,
          windSpeedMS: 2.5,
          description: 'Nắng nhẹ, độ ẩm vừa phải',
          iconUrl: 'https://openweathermap.org/img/wn/02d@2x.png',
          fungalDiseaseRisk: 'LOW',
          agriculturalAdvice: 'Thời tiết thuận lợi cho cây sầu riêng phát triển.',
        );
  }
}
