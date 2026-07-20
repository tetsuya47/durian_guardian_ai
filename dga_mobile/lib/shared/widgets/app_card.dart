import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../styles/app_styles.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool showBorder;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = backgroundColor ?? theme.cardColor;

    Widget cardWidget = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      margin: margin,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppRadius.borderMedium,
        boxShadow: AppShadow.low,
        border: showBorder
            ? Border.all(
                color: theme.brightness == Brightness.light
                    ? AppColors.lightBorder
                    : AppColors.darkBorder,
                width: 0.5,
              )
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: AppRadius.borderMedium,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderMedium,
          child: cardWidget,
        ),
      );
    }

    return cardWidget;
  }
}
