import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../styles/app_styles.dart';

enum SnackbarType { success, warning, error, info }

class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    Color getBgColor() {
      switch (type) {
        case SnackbarType.success:
          return AppColors.success;
        case SnackbarType.warning:
          return AppColors.warning;
        case SnackbarType.error:
          return AppColors.error;
        case SnackbarType.info:
          return theme.colorScheme.primary;
      }
    }

    IconData getIcon() {
      switch (type) {
        case SnackbarType.success:
          return Icons.check_circle_outline;
        case SnackbarType.warning:
          return Icons.warning_amber_outlined;
        case SnackbarType.error:
          return Icons.error_outline;
        case SnackbarType.info:
          return Icons.info_outline;
      }
    }

    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: getBgColor(),
            borderRadius: AppRadius.borderMedium,
            boxShadow: AppShadow.medium,
          ),
          child: Row(
            children: [
              Icon(getIcon(), color: AppColors.white, size: 20),
              AppSpacing.h12,
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
