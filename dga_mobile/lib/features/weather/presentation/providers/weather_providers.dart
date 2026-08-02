import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_api_client.dart';
import '../../data/datasources/weather_remote_datasource.dart';
import '../../data/models/weather_dtos.dart';

final weatherRemoteDataSourceProvider = Provider<WeatherRemoteDataSource>((ref) {
  final apiClient = ref.watch(dioApiClientProvider);
  return WeatherRemoteDataSourceImpl(apiClient);
});

final currentWeatherProvider = FutureProvider<WeatherCurrentDto>((ref) async {
  final datasource = ref.watch(weatherRemoteDataSourceProvider);
  return await datasource.getCurrentWeather();
});
