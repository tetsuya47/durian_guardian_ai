import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
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
import '../widgets/profile_header.dart';
import '../widgets/profile_information_card.dart';
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
          _useFallbackProfile();
        },
        loading: () {},
        empty: () {
          _useFallbackProfile();
        },
      );
    } catch (_) {
      _useFallbackProfile();
    }
  }

  void _useFallbackProfile() {
    final fallback = UserProfileEntity(
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
      fullName: 'Nguyễn Văn Chinh',
      role: 'Chủ trang trại Sầu Riêng',
      email: 'chinh@gmail.com',
      phoneNumber: '0987654321',
      workUnit: 'Hợp Tác Xã Sầu Riêng Krông Pắc',
      address: 'Krông Pắc, Đắk Lắk',
      dob: '15/08/1988',
      gender: 'Nam',
      farmInfo: null,
      stats: const ProfileStatsEntity(
        totalInspections: 128,
        detectedDiseases: 4,
        viewedRecommendations: 36,
        healthyTreeRate: 98.2,
      ),
    );
    ref.read(userProfileProvider.notifier).state = fallback;
    ref.read(profileStateProvider.notifier).state = 'loaded';
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
        ref.invalidate(userIoTStatusProvider);
        ref.invalidate(latestTelemetryProvider);
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
      backgroundColor: const Color(0xFFF5F7F9),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildBodyByState(context, state, profile),
      ),
    );
  }

  Widget _buildBodyByState(BuildContext context, String state, UserProfileEntity? profile) {
    if (state == 'loading') {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 40),
          Center(child: SkeletonLoading.avatar(size: 108)),
          const SizedBox(height: 24),
          SkeletonLoading.card(height: 120),
          const SizedBox(height: 16),
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
        child: Column(
          children: [
            // 1. Header (Gradient + Wave + 120px Avatar + User Info)
            ProfileHeader(
              avatarUrl: profile.avatarUrl,
              fullName: profile.fullName,
              role: profile.role,
              workUnit: profile.workUnit,
              onAvatarEditTap: () => _showUnderDevelopmentMessage('Thay đổi ảnh đại diện'),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // 2. Quick Stats (1 Card with 4 Columns & Vertical Dividers)
                  ProfileStatistics(stats: profile.stats),
                  const SizedBox(height: 20),

                  // 3. Personal Information Card
                  ProfileInformationCard(
                    profile: profile,
                    onEditTap: () => _showEditBottomSheet(context, profile),
                  ),
                  const SizedBox(height: 20),

                  // 4. Account Section Card ("Tài khoản")
                  _buildAccountCard(context),
                  const SizedBox(height: 20),

                  // 5. Settings Section Card ("Cài đặt")
                  _buildSettingsCard(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const EmptyState(
      icon: Icons.person_off_outlined,
      title: AppStrings.noProfileData,
      description: AppStrings.cannotLoadProfile,
    );
  }

  // Account Card Widget ("Tài khoản")
  Widget _buildAccountCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tài khoản',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),

          // Item 1: Đổi mật khẩu
          _buildMenuRow(
            icon: Icons.lock_outline_rounded,
            title: 'Đổi mật khẩu',
            onTap: () => _showUnderDevelopmentMessage('Đổi mật khẩu'),
          ),
          _buildRowDivider(),

          // Item 2: Đăng xuất
          _buildMenuRow(
            icon: Icons.logout_rounded,
            title: 'Đăng xuất',
            onTap: () => _showLogoutDialog(context),
          ),
          _buildRowDivider(),

          // Item 3: Xóa tài khoản
          _buildMenuRow(
            icon: Icons.delete_outline_rounded,
            title: 'Xóa tài khoản',
            titleColor: const Color(0xFFDC2626),
            iconColor: const Color(0xFFDC2626),
            iconBgColor: const Color(0xFFFEE2E2),
            onTap: () => _showUnderDevelopmentMessage('Xóa tài khoản'),
          ),
        ],
      ),
    );
  }

  // Settings Card Widget ("Cài đặt")
  Widget _buildSettingsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cài đặt',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),

          _buildMenuRow(
            icon: Icons.notifications_none_rounded,
            title: 'Thông báo',
            onTap: () => _showUnderDevelopmentMessage('Thông báo'),
          ),
          _buildRowDivider(),

          _buildMenuRow(
            icon: Icons.language_rounded,
            title: 'Ngôn ngữ',
            onTap: () => _showUnderDevelopmentMessage('Ngôn ngữ'),
          ),
          _buildRowDivider(),

          _buildMenuRow(
            icon: Icons.dark_mode_outlined,
            title: 'Chế độ tối',
            onTap: () => _showUnderDevelopmentMessage('Chế độ tối'),
          ),
          _buildRowDivider(),

          _buildMenuRow(
            icon: Icons.privacy_tip_outlined,
            title: 'Chính sách bảo mật',
            onTap: () => _showUnderDevelopmentMessage('Chính sách bảo mật'),
          ),
          _buildRowDivider(),

          _buildMenuRow(
            icon: Icons.description_outlined,
            title: 'Điều khoản sử dụng',
            onTap: () => _showUnderDevelopmentMessage('Điều khoản sử dụng'),
          ),
          _buildRowDivider(),

          _buildMenuRow(
            icon: Icons.info_outline_rounded,
            title: 'Phiên bản ứng dụng',
            trailingText: 'v1.2.0',
            onTap: () => _showUnderDevelopmentMessage('Phiên bản ứng dụng'),
          ),
        ],
      ),
    );
  }

  Widget _buildRowDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: Color(0xFFF3F4F6)),
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color titleColor = const Color(0xFF374151),
    Color iconColor = const Color(0xFF1E8E4A),
    Color iconBgColor = const Color(0xFFE8F5ED),
    String? trailingText,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: titleColor,
              ),
            ),
          ),
          if (trailingText != null) ...[
            Text(
              trailingText,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(width: 6),
          ],
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF9CA3AF),
            size: 18,
          ),
        ],
      ),
    );
  }
}
