import 'package:flutter/material.dart';
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
          // Header Row (Title + Outline Edit Button)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thông tin cá nhân',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              InkWell(
                onTap: onEditTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E8E4A), width: 1),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 15,
                        color: Color(0xFF1E8E4A),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Chỉnh sửa',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E8E4A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 7 Information Rows with dividers
          _buildInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Họ và tên',
            value: profile.fullName.isNotEmpty ? profile.fullName : 'hoàng văn hải',
          ),
          _buildDivider(),

          _buildInfoRow(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            value: profile.email.isNotEmpty ? profile.email : 'hai@gmail.com',
          ),
          _buildDivider(),

          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: 'Số điện thoại',
            value: profile.phoneNumber,
          ),
          _buildDivider(),

          _buildInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Địa chỉ',
            value: profile.address,
          ),
          _buildDivider(),

          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Ngày sinh',
            value: profile.dob,
          ),
          _buildDivider(),

          _buildInfoRow(
            icon: Icons.shield_outlined,
            label: 'Vai trò',
            value: profile.role.isNotEmpty ? profile.role : 'Kỹ thuật viên',
          ),
          _buildDivider(),

          _buildInfoRow(
            icon: Icons.access_time_rounded,
            label: 'Tham gia từ',
            value: '05/08/2026',
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: Color(0xFFF3F4F6)),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isUnupdated = value.isEmpty || value == 'Chưa cập nhật';
    final displayValue = isUnupdated ? 'Chưa cập nhật' : value;

    return Row(
      children: [
        // Left Icon Circle
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F5ED),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFF1E8E4A),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),

        // Field Name
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        // Value
        Expanded(
          child: Text(
            displayValue,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: isUnupdated ? const Color(0xFF9CA3AF) : const Color(0xFF1F2937),
              fontWeight: isUnupdated ? FontWeight.normal : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Chevron Right
        const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF9CA3AF),
          size: 18,
        ),
      ],
    );
  }
}
