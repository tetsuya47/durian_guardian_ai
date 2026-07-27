import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/avatar.dart';
import '../../../../core/theme/app_spacing.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String? userAvatarUrl;
  final VoidCallback? onNotificationPressed;

  const DashboardAppBar({
    super.key,
    required this.userName,
    this.userAvatarUrl,
    this.onNotificationPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = userName.isNotEmpty ? userName : 'DGA User';

    return AppBar(
      titleSpacing: AppSpacing.lg,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          CustomAvatar(
            imageUrl: userAvatarUrl,
            name: displayName,
            radius: 20,
            onTap: () => context.go('/profile'),
          ),
          AppSpacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.welcome,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withAlpha(200),
                  ),
                ),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Thông báo',
          onPressed: onNotificationPressed ?? () {},
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: AppStrings.settings,
          onPressed: () => context.push('/settings'),
        ),
        AppSpacing.h8,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
