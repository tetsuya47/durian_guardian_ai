import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_spacing.dart';

class ProfileHeader extends StatelessWidget {
  final String avatarUrl;
  final String fullName;
  final String role;
  final String workUnit;
  final VoidCallback? onAvatarEditTap;

  const ProfileHeader({
    super.key,
    required this.avatarUrl,
    required this.fullName,
    required this.role,
    required this.workUnit,
    this.onAvatarEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Avatar stack with edit button
        Stack(
          children: [
            CircleAvatar(
              radius: 54,
              backgroundColor: theme.colorScheme.primary.withAlpha(40),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: avatarUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Icon(
                    Icons.person,
                    size: 50,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: onAvatarEditTap,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        AppSpacing.v16,
        Text(
          fullName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        AppSpacing.v4,
        Text(
          role,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        AppSpacing.v4,
        Text(
          workUnit,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(140),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
