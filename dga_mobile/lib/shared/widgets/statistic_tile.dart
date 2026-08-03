import 'package:flutter/material.dart';
import 'app_card.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.65),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              CircleAvatar(
                radius: 13,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(icon, size: 14, color: theme.colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (trendLabel != null && trendLabel!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (isPositiveTrend != null) ...[
                  Icon(
                    isPositiveTrend! ? Icons.trending_up : Icons.trending_down,
                    size: 13,
                    color: isPositiveTrend! ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 3),
                ],
                Expanded(
                  child: Text(
                    trendLabel!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: isPositiveTrend == null
                          ? theme.colorScheme.onSurface.withOpacity(0.6)
                          : (isPositiveTrend! ? Colors.green : Colors.red),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
