import 'package:flutter/material.dart';
import '../../../../shared/widgets/statistic_tile.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/dashboard_entities.dart';

IconData _mapIcon(String name) {
  switch (name) {
    case 'check_circle_outline':
      return Icons.check_circle_outline;
    case 'error_outline':
      return Icons.error_outline;
    case 'warning_amber_outlined':
      return Icons.warning_amber_outlined;
    case 'qr_code_scanner':
      return Icons.qr_code_scanner;
    default:
      return Icons.help_outline;
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
    if (statistics.length < 4) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatisticTile(
                label: statistics[0].label,
                value: statistics[0].value,
                icon: _mapIcon(statistics[0].icon),
              ),
            ),
            AppSpacing.h12,
            Expanded(
              child: StatisticTile(
                label: statistics[1].label,
                value: statistics[1].value,
                icon: _mapIcon(statistics[1].icon),
              ),
            ),
          ],
        ),
        AppSpacing.v12,
        Row(
          children: [
            Expanded(
              child: StatisticTile(
                label: statistics[2].label,
                value: statistics[2].value,
                icon: _mapIcon(statistics[2].icon),
              ),
            ),
            AppSpacing.h12,
            Expanded(
              child: StatisticTile(
                label: statistics[3].label,
                value: statistics[3].value,
                icon: _mapIcon(statistics[3].icon),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
