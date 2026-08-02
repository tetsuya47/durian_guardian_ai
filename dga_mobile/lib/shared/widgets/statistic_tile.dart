import 'package:flutter/material.dart';
import 'app_card.dart';
import '../styles/app_styles.dart';

class StatisticTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? trendLabel;
  final bool? isPositiveTrend;

  const StatisticTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.trendLabel,
    this.isPositiveTrend,
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
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppSpacing.h4,
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(icon, size: 16, color: theme.colorScheme.primary),
              ),
            ],
          ),
          AppSpacing.v12,
          Text(
            value,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (trendLabel != null) ...[
            AppSpacing.v8,
            Row(
              children: [
                if (isPositiveTrend != null) ...[
                  Icon(
                    isPositiveTrend! ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: isPositiveTrend! ? Colors.green : Colors.red,
                  ),
                  AppSpacing.h4,
                ],
                Text(
                  trendLabel!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isPositiveTrend == null
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                        : (isPositiveTrend! ? Colors.green : Colors.red),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
