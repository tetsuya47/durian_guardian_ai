import 'package:flutter/material.dart';

class VietplantQuickMenuGrid extends StatelessWidget {
  final VoidCallback? onFarmingTechniquesTap;
  final VoidCallback? onPestsDiseasesTap;
  final VoidCallback? onWeatherTap;
  final VoidCallback? onTasksTap;
  final VoidCallback? onCommunityTap;
  final VoidCallback? onBiocontrolTap;

  const VietplantQuickMenuGrid({
    super.key,
    this.onFarmingTechniquesTap,
    this.onPestsDiseasesTap,
    this.onWeatherTap,
    this.onTasksTap,
    this.onCommunityTap,
    this.onBiocontrolTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuItemData(
        title: 'Kỹ thuật canh tác',
        icon: Icons.water_drop_outlined,
        color: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF2E7D32),
        onTap: onFarmingTechniquesTap,
      ),
      _MenuItemData(
        title: 'Sâu bệnh hại',
        icon: Icons.bug_report_outlined,
        color: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFE65100),
        onTap: onPestsDiseasesTap,
      ),
      _MenuItemData(
        title: 'Thời tiết nông vụ',
        icon: Icons.wb_sunny_outlined,
        color: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF0288D1),
        onTap: onWeatherTap,
      ),
      _MenuItemData(
        title: 'Ưu đãi gói cước',
        icon: Icons.cell_tower,
        color: const Color(0xFFF3E5F5),
        iconColor: const Color(0xFF7B1FA2),
        onTap: onTasksTap,
      ),
      _MenuItemData(
        title: 'Tin tức',
        icon: Icons.newspaper_outlined,
        color: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF2E7D32),
        onTap: onCommunityTap,
      ),
      _MenuItemData(
        title: 'Phòng trừ sinh học',
        icon: Icons.eco_outlined,
        color: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF2E7D32),
        onTap: onBiocontrolTap,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(item.icon, color: item.iconColor, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                  height: 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MenuItemData {
  final String title;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback? onTap;

  _MenuItemData({
    required this.title,
    required this.icon,
    required this.color,
    required this.iconColor,
    this.onTap,
  });
}
