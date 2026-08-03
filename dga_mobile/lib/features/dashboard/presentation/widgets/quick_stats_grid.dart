import 'package:flutter/material.dart';
import '../../../../shared/widgets/statistic_tile.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/dashboard_entities.dart';

IconData _mapIcon(String name) {
  switch (name) {
    case 'park':
    case 'qr_code_scanner':
      return Icons.park;
    case 'landscape':
    case 'map':
      return Icons.landscape;
    case 'favorite':
    case 'check_circle_outline':
      return Icons.favorite;
    case 'warning':
    case 'error_outline':
    case 'warning_amber_outlined':
      return Icons.warning_amber_outlined;
    case 'trending_up':
      return Icons.trending_up;
    default:
      return Icons.analytics_outlined;
  }
}

class QuickStatsGrid extends StatelessWidget {
  final List<StatItemEntity> statistics;

  const QuickStatsGrid({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    if (statistics.isEmpty) return const SizedBox.shrink();

    final List<Widget> rows = [];
    for (int i = 0; i < statistics.length; i += 2) {
      if (i > 0) rows.add(AppSpacing.v8);
      if (i + 1 < statistics.length) {
        rows.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: StatisticTile(
                  label: statistics[i].label,
                  value: statistics[i].value,
                  icon: _mapIcon(statistics[i].icon),
                  trendLabel: statistics[i].subtitle,
                  isPositiveTrend: statistics[i].isPositiveTrend,
                ),
              ),
              AppSpacing.h8,
              Expanded(
                child: StatisticTile(
                  label: statistics[i + 1].label,
                  value: statistics[i + 1].value,
                  icon: _mapIcon(statistics[i + 1].icon),
                  trendLabel: statistics[i + 1].subtitle,
                  isPositiveTrend: statistics[i + 1].isPositiveTrend,
                ),
              ),
            ],
          ),
        );
      } else {
        rows.add(
          StatisticTile(
            label: statistics[i].label,
            value: statistics[i].value,
            icon: _mapIcon(statistics[i].icon),
            trendLabel: statistics[i].subtitle,
            isPositiveTrend: statistics[i].isPositiveTrend,
          ),
        );
      }
    }

    return Column(children: rows);
  }
}
