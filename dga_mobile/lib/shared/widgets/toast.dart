import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../styles/app_styles.dart';

class AppToast {
  AppToast._();

  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    final theme = Theme.of(context);
    final overlayState = Overlay.of(context);

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100.0,
        left: 24.0,
        right: 24.0,
        child: Material(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light
                    ? AppColors.lightTextPrimary.withValues(alpha: 0.9)
                    : AppColors.darkCard.withValues(alpha: 0.9),
                borderRadius: AppRadius.borderLarge,
                boxShadow: AppShadow.medium,
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }
}
