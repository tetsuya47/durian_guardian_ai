import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../providers/weather_providers.dart';

class WeatherCard extends ConsumerWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(currentWeatherProvider);

    return weatherAsync.when(
      data: (weather) {
        final isHighRisk = weather.fungalDiseaseRisk == 'HIGH';
        final isMediumRisk = weather.fungalDiseaseRisk == 'MEDIUM';

        final gradientColors = isHighRisk
            ? [const Color(0xFFD84315), const Color(0xFFF4511E)]
            : isMediumRisk
                ? [const Color(0xFFE65100), const Color(0xFFF57C00)]
                : [const Color(0xFF1B5E20), const Color(0xFF2E7D32)];

        final riskBadgeColor = isHighRisk
            ? Colors.red.shade900
            : isMediumRisk
                ? Colors.orange.shade900
                : Colors.green.shade900;

        final riskBadgeText = isHighRisk
            ? 'CẢNH BÁO NẤM BỆNH CAO'
            : isMediumRisk
                ? 'CHÚ Ý NẤM BỆNH'
                : 'THỜI TIẾT AN TOÀN';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                weather.locationName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.v4,
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${weather.tempCelsius.toStringAsFixed(1)}°C',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              weather.description,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Image.network(
                      weather.iconUrl,
                      width: 52,
                      height: 52,
                      errorBuilder: (_, __, ___) => const Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 36),
                    ),
                  ),
                ],
              ),
              AppSpacing.v12,
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildMetricPill(
                    icon: Icons.water_drop_outlined,
                    label: 'Độ ẩm: ${weather.humidityPercent}%',
                  ),
                  _buildMetricPill(
                    icon: Icons.air_outlined,
                    label: 'Gió: ${weather.windSpeedMS} m/s',
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: riskBadgeColor.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      riskBadgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Divider(color: Colors.white24, height: 1),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      weather.agriculturalAdvice,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.3,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.green.shade900.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMetricPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
