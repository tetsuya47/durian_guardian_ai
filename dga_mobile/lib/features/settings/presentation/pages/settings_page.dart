import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loading.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/loading/loading_dialog.dart';
import '../../../../shared/utils/ui_helpers.dart';
import '../../domain/entities/settings_entities.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../providers/settings_providers.dart';
import '../widgets/about_card.dart';
import '../widgets/settings_card.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_switch_tile.dart';
import '../widgets/settings_tile.dart';
import '../widgets/theme_bottom_sheet.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    ref.read(settingsStateProvider.notifier).state = 'loading';
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final result = await repo.getAppSettings();
      result.when(
        success: (settings) {
          ref.read(appSettingsProvider.notifier).state = settings;
          ref.read(settingsStateProvider.notifier).state = 'loaded';
        },
        failure: (msg, err) {
          ref.read(settingsStateProvider.notifier).state = 'error';
        },
        loading: () {},
        empty: () {},
      );
    } catch (_) {
      ref.read(settingsStateProvider.notifier).state = 'error';
    }
  }

  Future<void> _updateSettings(AppSettingsEntity newSettings) async {
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final result = await repo.updateAppSettings(newSettings);
      result.when(
        success: (updated) {
          ref.read(appSettingsProvider.notifier).state = updated;
        },
        failure: (msg, err) {
          if (mounted) AppSnackbars.showError(context, msg);
        },
        loading: () {},
        empty: () {},
      );
    } catch (_) {
      if (mounted) AppSnackbars.showError(context, 'Không thể cập nhật cài đặt.');
    }
  }

  void _showThemeSelector(BuildContext context, AppSettingsEntity settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ThemeBottomSheet(
        currentTheme: settings.themeMode,
        onSelectTheme: (newTheme) {
          _updateSettings(settings.copyWith(themeMode: newTheme));
        },
      ),
    );
  }

  Future<void> _clearCache() async {
    LoadingDialog.show(context, message: 'Đang xóa bộ nhớ đệm...');
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final result = await repo.clearCache();
      if (!mounted) return;
      LoadingDialog.hide(context);
      result.when(
        success: (updated) {
          ref.read(appSettingsProvider.notifier).state = updated;
          AppSnackbars.showSuccess(context, AppStrings.clearCacheSuccess);
        },
        failure: (msg, err) {
          AppSnackbars.showError(context, msg);
        },
        loading: () {},
        empty: () {},
      );
    } catch (_) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      AppSnackbars.showError(context, AppStrings.clearCacheFailed);
    }
  }

  void _showClearCacheDialog(BuildContext context) {
    AppDialogs.showConfirmation(
      context,
      title: AppStrings.clearCacheConfirmTitle,
      message: AppStrings.clearCacheConfirmMessage,
      confirmText: 'Xóa cache',
      cancelText: AppStrings.cancel,
      onConfirm: _clearCache,
    );
  }

  Future<void> _resetDefaults() async {
    LoadingDialog.show(context, message: 'Đang khôi phục cài đặt...');
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final result = await repo.resetToDefault();
      if (!mounted) return;
      LoadingDialog.hide(context);
      result.when(
        success: (updated) {
          ref.read(appSettingsProvider.notifier).state = updated;
          AppSnackbars.showSuccess(context, AppStrings.resetSuccess);
        },
        failure: (msg, err) {
          AppSnackbars.showError(context, msg);
        },
        loading: () {},
        empty: () {},
      );
    } catch (_) {
      if (!mounted) return;
      LoadingDialog.hide(context);
    }
  }

  void _showResetDefaultsDialog(BuildContext context) {
    AppDialogs.showConfirmation(
      context,
      title: AppStrings.resetDefaultsTitle,
      message: AppStrings.resetDefaultsMessage,
      confirmText: 'Khôi phục',
      cancelText: AppStrings.cancel,
      onConfirm: _resetDefaults,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    AppDialogs.showConfirmation(
      context,
      title: AppStrings.logoutConfirmTitle,
      message: AppStrings.logoutConfirmMessage,
      confirmText: AppStrings.logout,
      cancelText: AppStrings.cancel,
      onConfirm: () async {
        try {
          final repo = ref.read(authRepositoryProvider);
          await repo.logout();
        } catch (_) {}
        if (context.mounted) context.go('/login');
      },
    );
  }

  void _showDevelopmentMessage(String label) {
    AppSnackbars.showInfo(context, 'Tính năng "$label" đang được phát triển.');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsStateProvider);
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildBody(context, state, settings),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, String state, AppSettingsEntity? settings) {
    if (state == 'loading') {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          SkeletonLoading.card(height: 90),
          AppSpacing.v20,
          SkeletonLoading.card(height: 180),
          AppSpacing.v16,
          SkeletonLoading.card(height: 180),
        ],
      );
    }

    if (state == 'error') {
      return Center(
        child: ErrorState(
          title: AppStrings.error,
          description: 'Nạp cấu hình thất bại.',
          onRetry: _loadSettings,
        ),
      );
    }

    if (state == 'loaded' && settings != null) {
      final theme = Theme.of(context);
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const AboutCard(),
            AppSpacing.v20,
            
            // Account
            SettingsSection(
              title: AppStrings.accountSection,
              child: SettingsCard(
                children: [
                  SettingsTile(
                    icon: Icons.person_outline,
                    title: AppStrings.menuAccountInfo,
                    onTap: () => _showDevelopmentMessage(AppStrings.menuAccountInfo),
                  ),
                  SettingsTile(
                    icon: Icons.lock_outline,
                    title: AppStrings.menuChangePassword,
                    onTap: () => _showDevelopmentMessage(AppStrings.menuChangePassword),
                  ),
                  SettingsTile(
                    icon: Icons.logout,
                    iconColor: AppColors.error,
                    title: AppStrings.logout,
                    onTap: () => _showLogoutDialog(context),
                  ),
                ],
              ),
            ),

            // Notifications
            SettingsSection(
              title: AppStrings.notificationSection,
              child: SettingsCard(
                children: [
                  SettingsSwitchTile(
                    icon: Icons.notifications_active_outlined,
                    title: AppStrings.aiNotification,
                    value: settings.notifications.aiAlerts,
                    onChanged: (val) {
                      _updateSettings(settings.copyWith(
                        notifications: settings.notifications.copyWith(aiAlerts: val),
                      ));
                    },
                  ),
                  SettingsSwitchTile(
                    icon: Icons.cloud_outlined,
                    title: AppStrings.weatherNotification,
                    value: settings.notifications.weatherAlerts,
                    onChanged: (val) {
                      _updateSettings(settings.copyWith(
                        notifications: settings.notifications.copyWith(weatherAlerts: val),
                      ));
                    },
                  ),
                  SettingsSwitchTile(
                    icon: Icons.bug_report_outlined,
                    title: AppStrings.diseaseNotification,
                    value: settings.notifications.diseaseAlerts,
                    onChanged: (val) {
                      _updateSettings(settings.copyWith(
                        notifications: settings.notifications.copyWith(diseaseAlerts: val),
                      ));
                    },
                  ),
                  SettingsSwitchTile(
                    icon: Icons.settings_input_component,
                    title: AppStrings.systemNotification,
                    value: settings.notifications.systemAlerts,
                    onChanged: (val) {
                      _updateSettings(settings.copyWith(
                        notifications: settings.notifications.copyWith(systemAlerts: val),
                      ));
                    },
                  ),
                ],
              ),
            ),

            // Display
            SettingsSection(
              title: AppStrings.displaySection,
              child: SettingsCard(
                children: [
                  SettingsTile(
                    icon: Icons.color_lens_outlined,
                    title: AppStrings.themeModeLabel,
                    trailingText: settings.themeMode == 'Sáng'
                        ? AppStrings.themeLight
                        : settings.themeMode == 'Tối'
                            ? AppStrings.themeDark
                            : AppStrings.themeSystem,
                    onTap: () => _showThemeSelector(context, settings),
                  ),
                ],
              ),
            ),

            // Language
            SettingsSection(
              title: AppStrings.languageSection,
              child: SettingsCard(
                children: [
                  ListTile(
                    leading: Icon(Icons.language, color: theme.colorScheme.primary),
                    title: Text(
                      AppStrings.languageSection,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Text(
                      AppStrings.vietnamese,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(140),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Security
            SettingsSection(
              title: AppStrings.securitySection,
              child: SettingsCard(
                children: [
                  SettingsTile(
                    icon: Icons.dialpad,
                    title: AppStrings.changePin,
                    onTap: () => _showDevelopmentMessage(AppStrings.changePin),
                  ),
                  SettingsSwitchTile(
                    icon: Icons.fingerprint,
                    title: AppStrings.biometricAuth,
                    value: settings.security.biometricEnabled,
                    onChanged: (val) {
                      _updateSettings(settings.copyWith(
                        security: settings.security.copyWith(biometricEnabled: val),
                      ));
                    },
                  ),
                ],
              ),
            ),

            // Data
            SettingsSection(
              title: AppStrings.dataSection,
              child: AppCard(
                child: Column(
                  children: [
                    _buildDataRow(context, label: AppStrings.cacheSizeLabel, value: '${settings.cache.cacheSize.toStringAsFixed(1)} MB'),
                    const Divider(),
                    _buildDataRow(context, label: AppStrings.photoSizeLabel, value: '${settings.cache.photoSize.toStringAsFixed(1)} MB'),
                    const Divider(),
                    _buildDataRow(context, label: AppStrings.aiCacheSizeLabel, value: '${settings.cache.aiCacheSize.toStringAsFixed(1)} MB'),
                    AppSpacing.v16,
                    ElevatedButton.icon(
                      onPressed: () => _showClearCacheDialog(context),
                      icon: const Icon(Icons.cleaning_services),
                      label: const Text(AppStrings.clearDataAction),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error.withAlpha(20),
                        foregroundColor: AppColors.error,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // About Links
            SettingsSection(
              title: AppStrings.aboutSection,
              child: SettingsCard(
                children: [
                  SettingsTile(
                    icon: Icons.article_outlined,
                    title: AppStrings.menuTermsOfUse,
                    onTap: () => _showDevelopmentMessage(AppStrings.menuTermsOfUse),
                  ),
                  SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: AppStrings.menuPrivacyPolicy,
                    onTap: () => _showDevelopmentMessage(AppStrings.menuPrivacyPolicy),
                  ),
                  SettingsTile(
                    icon: Icons.contact_support_outlined,
                    title: AppStrings.contactSupport,
                    onTap: () => _showDevelopmentMessage(AppStrings.contactSupport),
                  ),
                  SettingsTile(
                    icon: Icons.help_center_outlined,
                    title: AppStrings.userGuide,
                    onTap: () => _showDevelopmentMessage(AppStrings.userGuide),
                  ),
                  SettingsTile(
                    icon: Icons.card_membership_outlined,
                    title: AppStrings.openSourceLicenses,
                    onTap: () => _showDevelopmentMessage(AppStrings.openSourceLicenses),
                  ),
                ],
              ),
            ),

            AppSpacing.v16,
            // Reset Defaults Button
            OutlinedButton.icon(
              onPressed: () => _showResetDefaultsDialog(context),
              icon: const Icon(Icons.restore),
              label: const Text(AppStrings.resetDefaultsTitle),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            AppSpacing.v32,
          ],
        ),
      );
    }

    return EmptyState(
      icon: Icons.settings_outlined,
      title: 'Không thể nạp cài đặt',
      description: 'Đã xảy ra lỗi khi tải dữ liệu cài đặt. Vui lòng thử lại.',
      actionLabel: 'Thử lại',
      onActionPressed: _loadSettings,
    );
  }

  Widget _buildDataRow(BuildContext context, {required String label, required String value}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
