import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../weather/presentation/providers/weather_providers.dart';
import '../../domain/entities/recommendation_entities.dart';

class WeatherConditionsCard extends ConsumerWidget {
  final WeatherAdvisoryEntity? weather;

  const WeatherConditionsCard({
    super.key,
    this.weather,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final weatherAsync = ref.watch(currentWeatherProvider);

    final String tempStr = weatherAsync.when(
      data: (w) => '${w.tempCelsius.toStringAsFixed(1)}°C',
      loading: () => weather != null ? '${weather!.temperature}°C' : '...',
      error: (_, __) => weather != null ? '${weather!.temperature}°C' : 'N/A',
    );

    final String humidityStr = weatherAsync.when(
      data: (w) => '${w.humidityPercent}%',
      loading: () => weather != null ? '${weather!.humidity}%' : '...',
      error: (_, __) => weather != null ? '${weather!.humidity}%' : 'N/A',
    );

    final String rainStr = weatherAsync.when(
      data: (w) => w.description,
      loading: () => weather != null ? '${weather!.rainfall} mm' : '...',
      error: (_, __) => weather != null ? '${weather!.rainfall} mm' : 'N/A',
    );

    final String windStr = weatherAsync.when(
      data: (w) => '${w.windSpeedMS} m/s',
      loading: () => weather != null ? '${weather!.windSpeed} km/h' : '...',
      error: (_, __) => weather != null ? '${weather!.windSpeed} km/h' : 'N/A',
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.thermostat_outlined, color: theme.colorScheme.primary, size: 22),
              AppSpacing.h8,
              Text(
                AppStrings.weatherConditions,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          AppSpacing.v16,
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            children: [
              _buildWeatherIndicator(
                context,
                icon: Icons.device_thermostat_outlined,
                label: AppStrings.tempLabel,
                value: tempStr,
              ),
              _buildWeatherIndicator(
                context,
                icon: Icons.water_drop_outlined,
                label: AppStrings.humidityLabel,
                value: humidityStr,
              ),
              _buildWeatherIndicator(
                context,
                icon: Icons.umbrella_outlined,
                label: AppStrings.rain,
                value: rainStr,
              ),
              _buildWeatherIndicator(
                context,
                icon: Icons.air_outlined,
                label: AppStrings.wind,
                value: windStr,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherIndicator(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: theme.colorScheme.primary),
          AppSpacing.h8,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(140),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
