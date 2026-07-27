import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/routes/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'services/storage_service.dart';
import 'features/settings/presentation/providers/settings_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences and SecureStorage
  final sharedPreferences = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();

  runApp(
    ProviderScope(
      overrides: [
        // Override the storageServiceProvider with initialized dependencies
        storageServiceProvider.overrideWithValue(
          StorageService(sharedPreferences, secureStorage),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterWithoutGeneratorProvider);
    final settings = ref.watch(appSettingsProvider);

    ThemeMode themeMode = ThemeMode.dark;
    if (settings != null) {
      switch (settings.themeMode) {
        case 'Sáng':
          themeMode = ThemeMode.light;
          break;
        case 'Tối':
          themeMode = ThemeMode.dark;
          break;
        case 'Theo hệ thống':
          themeMode = ThemeMode.system;
          break;
      }
    }

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
