import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'bottom_navigation_bar.dart';
import '../../features/history/presentation/providers/history_providers.dart';

class TabScaffold extends ConsumerWidget {
  final Widget child;

  const TabScaffold({
    super.key,
    required this.child,
  });

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/disease-detection')) return 1;
    if (location.startsWith('/history')) return 2;
    if (location.startsWith('/community')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0; // Default to Dashboard (/dashboard - Trang chủ)
  }

  void _onTabTapped(BuildContext context, WidgetRef ref, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/disease-detection');
        break;
      case 2:
        ref.invalidate(historyRawLogsProvider);
        context.go('/history');
        break;
      case 3:
        context.go('/community');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _getCurrentIndex(context),
        onTap: (index) => _onTabTapped(context, ref, index),
      ),
    );
  }
}
