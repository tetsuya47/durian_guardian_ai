import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/outlined_button.dart';
import '../providers/auth_providers.dart';
import '../widgets/login_form.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppSpacing.v20,
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withAlpha(25),
                  ),
                  child: Icon(
                    Icons.spa,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                ),
                AppSpacing.v20,
                Text(
                  'Durian Guardian AI',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                AppSpacing.v32,
                const LoginForm(),
                AppSpacing.v20,
                // Guest Login
                CustomOutlinedButton(
                  text: AppStrings.loginWithGuest,
                  icon: Icons.explore_outlined,
                  onPressed: () async {
                    ref.read(guestModeProvider.notifier).state = true;
                    context.go('/dashboard');
                  },
                ),
                AppSpacing.v16,
                // Create Account link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Chưa có tài khoản? ',
                      style: theme.textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: Text(
                        'Đăng ký ngay',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.v48,
                Text(
                  AppStrings.appVersion,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(128),
                  ),
                ),
                AppSpacing.v20,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
