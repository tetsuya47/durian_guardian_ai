import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/authentication/presentation/pages/forgot_password_page.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/register_page.dart';
import '../../features/authentication/presentation/pages/onboarding_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/disease_detection/presentation/pages/disease_detection_page.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/recommendation/presentation/pages/recommendation_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/disease_detection/presentation/pages/camera_simulator_page.dart';
import '../../features/disease_detection/presentation/pages/image_editor_wizard.dart';
import '../../features/authentication/presentation/providers/auth_providers.dart';
import '../../core/constants/storage_keys.dart';
import '../../services/storage_service.dart';
import '../../shared/components/tab_scaffold.dart';
import 'route_names.dart';

final appRouterWithoutGeneratorProvider = Provider<GoRouter>((ref) {
  final storageService = ref.watch(storageServiceProvider);

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding',
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/settings',
        name: RouteNames.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/camera-simulator',
        name: RouteNames.cameraSimulator,
        builder: (context, state) => const CameraSimulatorPage(),
      ),
      GoRoute(
        path: '/image-editor-wizard',
        name: RouteNames.imageEditorWizard,
        builder: (context, state) => const ImageEditorWizard(),
      ),

      ShellRoute(
        builder: (context, state, child) {
          return TabScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            name: RouteNames.dashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardPage(),
            ),
          ),
          GoRoute(
            path: '/disease-detection',
            name: RouteNames.diseaseDetection,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DiseaseDetectionPage(),
            ),
          ),
          GoRoute(
            path: '/recommendation',
            name: RouteNames.recommendation,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: RecommendationPage(),
            ),
          ),
          GoRoute(
            path: '/history',
            name: RouteNames.history,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HistoryPage(),
            ),
          ),
          GoRoute(
            path: '/profile',
            name: RouteNames.profile,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfilePage(),
            ),
          ),
        ],
      ),
    ],
    redirect: (context, state) async {
      final path = state.matchedLocation;

      // Always allow unauthenticated routes
      if (path == '/splash' ||
          path == '/onboarding' ||
          path == '/login' ||
          path == '/forgot-password' ||
          path == '/register') {
        return null;
      }

      // Check guest mode
      final isGuest = ref.read(guestModeProvider);
      if (isGuest) return null;

      // Read tokens from SecureStorage (NOT SharedPreferences)
      final token = await storageService.readSecure(StorageKeys.token);
      final refreshToken = await storageService.readSecure(StorageKeys.refreshToken);
      final hasTokens = token != null && token.isNotEmpty && refreshToken != null && refreshToken.isNotEmpty;

      if (!hasTokens) {
        return '/login';
      }

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Lỗi')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 72, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 20),
              Text(
                'Không tìm thấy trang',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Trang bạn yêu cầu không tồn tại hoặc đã bị di chuyển.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/dashboard'),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Về trang chủ'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});
