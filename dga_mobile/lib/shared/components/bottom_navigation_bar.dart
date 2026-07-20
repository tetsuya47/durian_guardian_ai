import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../styles/app_styles.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        boxShadow: AppShadow.medium,
        borderRadius: const BorderRadius.only(
          topLeft: AppRadius.radiusMedium,
          topRight: AppRadius.radiusMedium,
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: AppRadius.radiusMedium,
          topRight: AppRadius.radiusMedium,
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: theme.brightness == Brightness.light
                ? theme.scaffoldBackgroundColor
                : theme.cardColor,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            selectedLabelStyle: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: theme.textTheme.labelSmall,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: AppStrings.dashboard,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.camera_alt_outlined),
                activeIcon: Icon(Icons.camera_alt),
                label: AppStrings.diseaseDetection,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.star_border),
                activeIcon: Icon(Icons.star),
                label: AppStrings.recommendation,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: AppStrings.history,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: AppStrings.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
