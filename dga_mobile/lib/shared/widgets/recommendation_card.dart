import 'package:flutter/material.dart';
import 'app_card.dart';
import '../styles/app_styles.dart';

class RecommendationCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData categoryIcon;
  final String categoryName;
  final VoidCallback? onApplyTap;

  const RecommendationCard({
    super.key,
    required this.title,
    required this.content,
    required this.categoryIcon,
    required this.categoryName,
    this.onApplyTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                radius: 16,
                child: Icon(categoryIcon, size: 16, color: theme.colorScheme.primary),
              ),
              AppSpacing.h8,
              Text(
                categoryName,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          AppSpacing.v12,
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.v8,
          Text(
            content,
            style: theme.textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (onApplyTap != null) ...[
            AppSpacing.v16,
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onApplyTap,
                child: const Text('Áp dụng khuyến nghị'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
