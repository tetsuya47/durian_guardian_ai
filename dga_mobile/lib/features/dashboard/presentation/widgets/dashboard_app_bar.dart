import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String? userAvatarUrl;

  const DashboardAppBar({
    super.key,
    required this.userName,
    this.userAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: const Color(0xFFF8FAFC),
      titleSpacing: 16,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Avatar HH
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFF2E7D32),
              child: Text(
                'HH',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Be Vietnam Pro',
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Xin chào,',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Be Vietnam Pro',
                  ),
                ),
                Text(
                  userName.isNotEmpty ? userName : 'Nguyễn Văn Chinh',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                    fontFamily: 'Be Vietnam Pro',
                  ),
                ),
                const Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: Color(0xFF2E7D32)),
                    SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        'Krông Pắc, Đắc Lắk',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontFamily: 'Be Vietnam Pro',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // Weather Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.04),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🌤️', style: TextStyle(fontSize: 16)),
                SizedBox(width: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '29°C',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        fontFamily: 'Be Vietnam Pro',
                      ),
                    ),
                    Text(
                      'Trời nắng nhẹ',
                      style: TextStyle(
                        fontSize: 9,
                        color: Color(0xFF64748B),
                        fontFamily: 'Be Vietnam Pro',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Notification Button
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.04),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.notifications_outlined, color: Color(0xFF0F172A), size: 20),
              ),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Be Vietnam Pro',
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 6),

          // Settings Button
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.04),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.settings_outlined, color: Color(0xFF0F172A), size: 20),
              onPressed: () => context.push('/settings'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(65);
}
