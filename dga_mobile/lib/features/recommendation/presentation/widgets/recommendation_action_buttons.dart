import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';

class RecommendationActionButtons extends StatelessWidget {
  final VoidCallback onShare;
  final VoidCallback onPrint;

  const RecommendationActionButtons({
    super.key,
    required this.onShare,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Share Button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.share_outlined),
            label: const Text(AppStrings.share),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        AppSpacing.h12,
        // Print Button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPrint,
            icon: const Icon(Icons.print_outlined),
            label: const Text(AppStrings.printReport),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
