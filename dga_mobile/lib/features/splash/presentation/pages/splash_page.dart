import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../services/storage_service.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    _loadSettingsAndNavigate();
  }

  Future<void> _loadSettingsAndNavigate() async {
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final result = await repo.getAppSettings();
      result.when(
        success: (settings) {
          ref.read(appSettingsProvider.notifier).state = settings;
        },
        failure: (_, __) {},
        loading: () {},
        empty: () {},
      );
    } catch (_) {}

    await _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    try {
      final storageService = ref.read(storageServiceProvider);
      final token = await storageService.readSecure(StorageKeys.token);
      final refreshToken =
          await storageService.readSecure(StorageKeys.refreshToken);
      final isFirstTime =
          storageService.getBool(StorageKeys.firstTimeUser) ?? true;

      if (token != null && token.isNotEmpty && refreshToken != null && refreshToken.isNotEmpty) {
        if (mounted) context.go('/dashboard');
      } else if (isFirstTime) {
        storageService.setBool(StorageKeys.firstTimeUser, false);
        if (mounted) context.go('/onboarding');
      } else {
        if (mounted) context.go('/login');
      }
    } catch (_) {
      if (mounted) context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withAlpha(25),
                ),
                child: Icon(
                  Icons.spa,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
              ),
              AppSpacing.v24,
              Text(
                'Durian Guardian AI',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              AppSpacing.v8,
              Text(
                AppStrings.appSlogan,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
              AppSpacing.v48,
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
