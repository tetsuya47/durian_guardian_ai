import 'package:flutter/material.dart';
import 'app_dialog.dart';
import '../theme/app_colors.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String cancelLabel;
  final String confirmLabel;
  final bool isDangerous;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.cancelLabel = 'Hủy',
    this.confirmLabel = 'Xác nhận',
    this.isDangerous = false,
    required this.onConfirm,
    this.onCancel,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    String cancelLabel = 'Hủy',
    String confirmLabel = 'Xác nhận',
    bool isDangerous = false,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        content: content,
        cancelLabel: cancelLabel,
        confirmLabel: confirmLabel,
        isDangerous: isDangerous,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confirmColor = isDangerous ? AppColors.error : theme.colorScheme.primary;

    return AppDialog(
      title: title,
      content: content,
      icon: isDangerous ? Icons.warning_amber_outlined : Icons.help_outline,
      iconColor: confirmColor,
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            if (onCancel != null) onCancel!();
          },
          child: Text(
            cancelLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: AppColors.white,
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
