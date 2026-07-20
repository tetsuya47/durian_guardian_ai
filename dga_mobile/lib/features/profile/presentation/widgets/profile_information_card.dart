import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/entities/profile_entities.dart';

class ProfileInformationCard extends StatelessWidget {
  final UserProfileEntity profile;
  final VoidCallback onEditTap;

  const ProfileInformationCard({
    super.key,
    required this.profile,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thông tin cá nhân',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: onEditTap,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text(AppStrings.editLabel),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          AppSpacing.v16,
          _buildInfoRow(context, label: 'Họ và tên', value: profile.fullName),
          const Divider(height: AppSpacing.lg),
          _buildInfoRow(context, label: AppStrings.email, value: profile.email),
          const Divider(height: AppSpacing.lg),
          _buildInfoRow(context, label: AppStrings.phoneLabel, value: profile.phoneNumber),
          const Divider(height: AppSpacing.lg),
          _buildInfoRow(context, label: AppStrings.addressLabel, value: profile.address),
          const Divider(height: AppSpacing.lg),
          _buildInfoRow(context, label: AppStrings.dobLabel, value: profile.dob),
          const Divider(height: AppSpacing.lg),
          _buildInfoRow(context, label: AppStrings.genderLabel, value: profile.gender),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, {required String label, required String value}) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(140),
          ),
        ),
        AppSpacing.h16,
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
