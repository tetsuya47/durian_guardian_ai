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
import '../../features/history/presentation/pages/compare_page.dart';
import '../../features/history/presentation/pages/leaderboard_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/community/presentation/pages/community_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/disease_detection/presentation/pages/camera_simulator_page.dart';
import '../../features/disease_detection/presentation/pages/image_editor_wizard.dart';
import '../../features/farms/presentation/pages/register_farm_page.dart';
import '../../features/farms/presentation/pages/farm_garden_hub_page.dart';
import '../../features/iot/presentation/pages/iot_shop_page.dart';
import '../../features/iot/presentation/pages/iot_management_page.dart';
import '../../features/iot/presentation/pages/farm_management_iot_page.dart';
import '../../features/farm_activity/presentation/pages/today_activity_page.dart';
import '../../features/authentication/presentation/providers/auth_providers.dart';
import '../../features/recommendation/presentation/pages/farming_techniques_page.dart';
import '../../features/recommendation/presentation/pages/pests_and_diseases_page.dart';
import '../../features/recommendation/presentation/pages/biocontrol_measures_page.dart';
import '../../features/weather/presentation/pages/weather_page.dart';
import '../../features/subscription/presentation/pages/subscription_packages_page.dart';
import '../../features/news/presentation/pages/durian_news_page.dart';
import '../../features/farm/presentation/pages/smart_garden_management_page.dart';
import '../../features/notification/presentation/pages/daily_ai_notifications_page.dart';
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
        path: '/today-activity',
        name: RouteNames.todayActivity,
        builder: (context, state) => const TodayActivityPage(),
      ),

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
      GoRoute(
        path: '/register-farm',
        name: RouteNames.registerFarm,
        builder: (context, state) => const RegisterFarmPage(),
      ),
      GoRoute(
        path: '/iot-shop',
        name: RouteNames.iotShop,
        builder: (context, state) => const IoTShopPage(),
      ),
      GoRoute(
        path: '/iot-management',
        name: RouteNames.iotManagement,
        builder: (context, state) => const IoTManagementPage(),
      ),
      GoRoute(
        path: '/farm-management-iot',
        name: 'farmManagementIoT',
        builder: (context, state) => const FarmManagementIoTPage(),
      ),
      GoRoute(
        path: '/farming-techniques',
        name: 'farmingTechniques',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return FarmingTechniquesPage(
            varietyId: extra?['varietyId'] ?? 'ri6',
            varietyName: extra?['varietyName'] ?? 'Sầu riêng Ri6',
          );
        },
      ),
      GoRoute(
        path: '/pests-and-diseases',
        name: 'pestsAndDiseases',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PestsAndDiseasesPage(
            varietyId: extra?['varietyId'] ?? 'ri6',
            varietyName: extra?['varietyName'] ?? 'Sầu riêng Ri6',
          );
        },
      ),
      GoRoute(
        path: '/weather',
        name: 'weatherPage',
        builder: (context, state) => const WeatherPage(),
      ),
      GoRoute(
        path: '/subscription-packages',
        name: 'subscriptionPackages',
        builder: (context, state) => const SubscriptionPackagesPage(),
      ),
      GoRoute(
        path: '/durian-news',
        name: 'durianNews',
        builder: (context, state) => const DurianNewsPage(),
      ),
      GoRoute(
        path: '/biocontrol-measures',
        name: 'biocontrolMeasures',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BiocontrolMeasuresPage(
            varietyId: extra?['varietyId'] ?? 'ri6',
            varietyName: extra?['varietyName'] ?? 'Sầu riêng Ri6',
          );
        },
      ),
      GoRoute(
        path: '/smart-garden-management',
        name: 'smartGardenManagement',
        builder: (context, state) => const FarmManagementIoTPage(),
      ),
      GoRoute(
        path: '/daily-ai-notifications',
        name: 'dailyAiNotifications',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final hasIoT = extra?['hasIoTDevices'] as bool? ?? false;
          return DailyAiNotificationsPage(hasIoTDevices: hasIoT);
        },
      ),
      GoRoute(
        path: '/register-farm',
        name: 'registerFarm',
        builder: (context, state) => const RegisterFarmPage(),
      ),
      GoRoute(
        path: '/iot-shop',
        name: 'iotShop',
        builder: (context, state) => const IoTShopPage(),
      ),
      GoRoute(
        path: '/iot-management',
        name: 'iotManagement',
        builder: (context, state) => const IoTManagementPage(),
      ),
      GoRoute(
        path: '/history-logs',
        name: 'historyLogs',
        builder: (context, state) => const HistoryPage(),
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
            path: '/farm-hub',
            name: 'farmHub',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FarmGardenHubPage(),
            ),
          ),
          GoRoute(
            path: '/history',
            name: RouteNames.history,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FarmGardenHubPage(),
            ),
            routes: [
              GoRoute(
                path: 'compare',
                name: 'history-compare',
                builder: (context, state) {
                  final initialTreeName = state.uri.queryParameters['treeName'];
                  return ComparePage(initialTreeName: initialTreeName);
                },
              ),
              GoRoute(
                path: 'leaderboard',
                name: 'history-leaderboard',
                builder: (context, state) => const LeaderboardPage(),
              ),
            ],
          ),
          GoRoute(
            path: '/community',
            name: 'community',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CommunityPage(),
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
