import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final String content;
  final IconData? icon;
  final Color? iconColor;
  final List<Widget>? actions;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.icon,
    this.iconColor,
    this.actions,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String content,
    IconData? icon,
    Color? iconColor,
    List<Widget>? actions,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => AppDialog(
        title: title,
        content: content,
        icon: icon,
        iconColor: iconColor,
        actions: actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderLarge,
      ),
      backgroundColor: theme.brightness == Brightness.light
          ? theme.scaffoldBackgroundColor
          : theme.cardColor,
      titlePadding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, 0),
      contentPadding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.lg, AppSpacing.xxl, AppSpacing.xxl),
      actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.xxl),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor ?? theme.colorScheme.primary, size: 28),
            AppSpacing.h12,
          ],
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        content,
        style: theme.textTheme.bodyMedium,
      ),
      actions: actions,
    );
  }
}
