import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/dashboard_entities.dart';

class DashboardWeatherCard extends StatelessWidget {
  final WeatherEntity weatherInfo;

  const DashboardWeatherCard({
    super.key,
    required this.weatherInfo,
  });

  Color _getRiskColor() {
    return weatherInfo.diseaseRisk == 'Thấp'
        ? AppColors.success
        : (weatherInfo.diseaseRisk == 'Trung bình' ? AppColors.warning : AppColors.error);
  }

  IconData _getWeatherIcon(String condition) {
    if (condition.contains('Mưa')) return Icons.cloudy_snowing;
    if (condition.contains('Nắng') || condition.contains('Quang')) return Icons.wb_sunny_outlined;
    return Icons.cloud_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final riskColor = _getRiskColor();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on_outlined, color: theme.colorScheme.primary, size: 20),
                  AppSpacing.h4,
                  Text(
                    weatherInfo.location,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: riskColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: riskColor.withAlpha(50)),
                ),
                child: Text(
                  '${AppStrings.risk}: ${weatherInfo.diseaseRisk}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: riskColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.v16,
          Row(
            children: [
              Icon(_getWeatherIcon(weatherInfo.condition), size: 48, color: theme.colorScheme.primary),
              AppSpacing.h16,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weatherInfo.temperature}°C',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  AppSpacing.v4,
                  Text(
                    weatherInfo.condition,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
          AppSpacing.v20,
          const Divider(height: 1),
          AppSpacing.v16,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWeatherDetail(
                context,
                icon: Icons.water_drop_outlined,
                label: AppStrings.humidityLabel,
                value: '${weatherInfo.humidity}%',
              ),
              _buildWeatherDetail(
                context,
                icon: Icons.umbrella_outlined,
                label: AppStrings.rain,
                value: '${weatherInfo.rainfall}mm',
              ),
              _buildWeatherDetail(
                context,
                icon: Icons.air,
                label: AppStrings.wind,
                value: '${weatherInfo.windSpeed}km/h',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.secondary),
        AppSpacing.h4,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall,
            ),
            Text(
              value,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
