import 'package:flutter/material.dart';
import 'app_card.dart';
import '../styles/app_styles.dart';

class WeatherCard extends StatelessWidget {
  final String location;
  final double temperature;
  final double humidity;
  final String condition;
  final IconData weatherIcon;

  const WeatherCard({
    super.key,
    required this.location,
    required this.temperature,
    required this.humidity,
    required this.condition,
    required this.weatherIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.v4,
                  Text(
                    condition,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              Icon(weatherIcon, size: 40, color: theme.colorScheme.primary),
            ],
          ),
          AppSpacing.v16,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.thermostat, size: 20, color: theme.colorScheme.secondary),
                  AppSpacing.h4,
                  Text(
                    '${temperature.toStringAsFixed(1)}°C',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.water_drop, size: 20, color: theme.colorScheme.secondary),
                  AppSpacing.h4,
                  Text(
                    '${humidity.toStringAsFixed(0)}%',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
