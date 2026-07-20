import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class CustomFAB extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onPressed;
  final String? heroTag;

  const CustomFAB({
    super.key,
    required this.icon,
    this.label,
    required this.onPressed,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExtended = label != null && label!.isNotEmpty;

    Widget fabChild = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24),
        if (isExtended) ...[
          AppSpacing.h8,
          Text(
            label!,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );

    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: onPressed,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderMedium,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isExtended ? AppSpacing.lg : 0.0,
        ),
        child: fabChild,
      ),
    );
  }
}
