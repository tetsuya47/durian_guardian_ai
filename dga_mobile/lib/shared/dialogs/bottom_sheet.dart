import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class AppBottomSheet {
  AppBottomSheet._();

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    final theme = Theme.of(context);

    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor: theme.brightness == Brightness.light
          ? theme.scaffoldBackgroundColor
          : theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: AppRadius.radiusLarge,
          topRight: AppRadius.radiusLarge,
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSpacing.v12,
              // Drag Indicator handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  borderRadius: AppRadius.borderSmall,
                ),
              ),
              if (title != null) ...[
                AppSpacing.v16,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                AppSpacing.v8,
                const Divider(height: 1),
              ],
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: child,
              ),
            ],
          ),
        );
      },
    );
  }
}
