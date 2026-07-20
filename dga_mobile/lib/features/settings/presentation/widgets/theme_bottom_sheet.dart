import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';

class ThemeBottomSheet extends StatelessWidget {
  final String currentTheme;
  final ValueChanged<String> onSelectTheme;

  const ThemeBottomSheet({
    super.key,
    required this.currentTheme,
    required this.onSelectTheme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final themes = [
      {'label': AppStrings.themeLight, 'value': 'Sáng'},
      {'label': AppStrings.themeDark, 'value': 'Tối'},
      {'label': AppStrings.themeSystem, 'value': 'Theo hệ thống'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withAlpha(40),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.themeModeLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          AppSpacing.v16,
          ...themes.map((item) {
            final isSelected = currentTheme == item['value'];
            return ListTile(
              title: Text(
                item['label']!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : null,
              onTap: () {
                Navigator.of(context).pop();
                onSelectTheme(item['value']!);
              },
            );
          }),
          AppSpacing.v16,
        ],
      ),
    );
  }
}
