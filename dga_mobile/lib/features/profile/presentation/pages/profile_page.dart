import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loading.dart';
import '../../../../shared/loading/loading_dialog.dart';
import '../../../../shared/utils/ui_helpers.dart';
import '../../domain/entities/profile_entities.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../providers/profile_providers.dart';
import '../widgets/edit_profile_sheet.dart';
import '../widgets/farm_information_card.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_information_card.dart';
import '../widgets/profile_menu_item.dart';
import '../widgets/profile_statistics.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (ref.read(userProfileProvider) == null) {
        ref.read(profileStateProvider.notifier).state = 'loading';
        _loadProfile();
      }
    });
  }

  Future<void> _loadProfile() async {
    try {
      final repo = ref.read(profileRepositoryProvider);
      final result = await repo.getUserProfile();
      result.when(
        success: (profile) {
          ref.read(userProfileProvider.notifier).state = profile;
          ref.read(profileStateProvider.notifier).state = 'loaded';
        },
        failure: (msg, err) {
          ref.read(profileStateProvider.notifier).state = 'error';
        },
        loading: () {},
        empty: () {
          ref.read(profileStateProvider.notifier).state = 'empty';
        },
      );
    } catch (_) {
      ref.read(profileStateProvider.notifier).state = 'error';
    }
  }

  void _showEditBottomSheet(BuildContext context, UserProfileEntity profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileSheet(
        profile: profile,
        onSave: (name, email, phone) => _saveProfile(name, email, phone),
      ),
    );
  }

  Future<void> _saveProfile(String name, String email, String phone) async {
    LoadingDialog.show(context, message: 'Đang lưu thông tin...');
    try {
      final repo = ref.read(profileRepositoryProvider);
      final result = await repo.updateUserProfile(name, email, phone);
      if (mounted) {
        LoadingDialog.hide(context);
        result.when(
          success: (updated) {
            ref.read(userProfileProvider.notifier).state = updated;
            AppSnackbars.showSuccess(context, 'Cập nhật thông tin cá nhân thành công!');
          },
          failure: (msg, err) {
            AppSnackbars.showError(context, msg);
          },
          loading: () {},
          empty: () {},
        );
      }
    } catch (_) {
      if (mounted) {
        LoadingDialog.hide(context);
        AppSnackbars.showError(context, 'Không thể cập nhật thông tin. Vui lòng thử lại!');
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    AppDialogs.showConfirmation(
      context,
      title: AppStrings.logoutConfirmTitle,
      message: AppStrings.logoutConfirmMessage,
      confirmText: AppStrings.logout,
      cancelText: AppStrings.cancel,
      onConfirm: () async {
        final repo = ref.read(authRepositoryProvider);
        await repo.logout();
        ref.invalidate(dashboardDataProvider);
        ref.invalidate(userProfileProvider);
        ref.invalidate(profileStateProvider);
        if (context.mounted) context.go('/login');
      },
    );
  }

  void _showUnderDevelopmentMessage(String featureName) {
    AppSnackbars.showInfo(context, 'Tính năng "$featureName" đang được phát triển.');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileStateProvider);
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profileTitle),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildBodyByState(context, state, profile),
        ),
      ),
    );
  }

  Widget _buildBodyByState(BuildContext context, String state, UserProfileEntity? profile) {
    if (state == 'loading') {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(child: SkeletonLoading.avatar(size: 108)),
          AppSpacing.v24,
          SkeletonLoading.card(height: 120),
          AppSpacing.v16,
          SkeletonLoading.card(height: 200),
        ],
      );
    }

    if (state == 'error') {
      return Center(
        child: ErrorState(
          title: AppStrings.error,
          description: AppStrings.cannotLoadProfile,
          onRetry: _loadProfile,
        ),
      );
    }

    if (state == 'loaded' && profile != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            ProfileHeader(
              avatarUrl: profile.avatarUrl,
              fullName: profile.fullName,
              role: profile.role,
              workUnit: profile.workUnit,
              onAvatarEditTap: () => _showUnderDevelopmentMessage('Thay đổi ảnh đại diện'),
            ),
            AppSpacing.v24,
            ProfileStatistics(stats: profile.stats),
            AppSpacing.v20,
            ProfileInformationCard(
              profile: profile,
              onEditTap: () => _showEditBottomSheet(context, profile),
            ),
            AppSpacing.v16,
            if (profile.farmInfo != null)
              FarmInformationCard(farmInfo: profile.farmInfo!),
            AppSpacing.v20,
            // Functional list
            ProfileMenuItem(
              icon: Icons.person_outline,
              title: AppStrings.menuAccountInfo,
              onTap: () => _showUnderDevelopmentMessage(AppStrings.menuAccountInfo),
            ),
            ProfileMenuItem(
              icon: Icons.lock_outline,
              title: AppStrings.menuChangePassword,
              onTap: () => _showUnderDevelopmentMessage(AppStrings.menuChangePassword),
            ),
            ProfileMenuItem(
              icon: Icons.notifications_none,
              title: AppStrings.menuManageNotifications,
              onTap: () => _showUnderDevelopmentMessage(AppStrings.menuManageNotifications),
            ),
            ProfileMenuItem(
              icon: Icons.privacy_tip_outlined,
              title: AppStrings.menuPrivacyPolicy,
              onTap: () => _showUnderDevelopmentMessage(AppStrings.menuPrivacyPolicy),
            ),
            ProfileMenuItem(
              icon: Icons.description_outlined,
              title: AppStrings.menuTermsOfUse,
              onTap: () => _showUnderDevelopmentMessage(AppStrings.menuTermsOfUse),
            ),
            ProfileMenuItem(
              icon: Icons.help_outline,
              title: AppStrings.menuHelp,
              onTap: () => _showUnderDevelopmentMessage(AppStrings.menuHelp),
            ),
            ProfileMenuItem(
              icon: Icons.info_outline,
              title: AppStrings.menuAbout,
              onTap: () => _showUnderDevelopmentMessage(AppStrings.menuAbout),
            ),
            AppSpacing.v24,
            // Logout Button
            ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Icons.logout),
              label: const Text(AppStrings.logout),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            AppSpacing.v32,
          ],
        ),
      );
    }

    return const EmptyState(
      icon: Icons.person_off_outlined,
      title: AppStrings.noProfileData,
      description: 'Không thể tải thông tin hồ sơ. Vui lòng thử lại.',
    );
  }
}
