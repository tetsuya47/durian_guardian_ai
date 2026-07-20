import '../models/dashboard_dtos.dart';

abstract class DashboardLocalDataSource {
  Future<void> cacheWeather(WeatherDto weather);
  Future<WeatherDto?> getCachedWeather();
  Future<void> cacheFarmStatus(FarmStatusDto status);
  Future<FarmStatusDto?> getCachedFarmStatus();
}

class DashboardLocalDataSourceImpl implements DashboardLocalDataSource {
  const DashboardLocalDataSourceImpl();

  @override
  Future<void> cacheWeather(WeatherDto weather) => throw UnimplementedError();

  @override
  Future<WeatherDto?> getCachedWeather() => throw UnimplementedError();

  @override
  Future<void> cacheFarmStatus(FarmStatusDto status) => throw UnimplementedError();

  @override
  Future<FarmStatusDto?> getCachedFarmStatus() => throw UnimplementedError();
}
