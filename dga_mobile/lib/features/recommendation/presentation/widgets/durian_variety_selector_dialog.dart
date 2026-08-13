import 'package:flutter/material.dart';

class DurianVariety {
  final String id;
  final String name;
  final String description;
  final String badgeText;
  final Color badgeColor;
  final IconData icon;

  const DurianVariety({
    required this.id,
    required this.name,
    required this.description,
    required this.badgeText,
    required this.badgeColor,
    required this.icon,
  });
}

class DurianVarietySelectorDialog extends StatelessWidget {
  final ValueChanged<DurianVariety> onVarietySelected;

  const DurianVarietySelectorDialog({
    super.key,
    required this.onVarietySelected,
  });

  static const List<DurianVariety> varieties = [
    DurianVariety(
      id: 'ri6',
      name: 'Sầu riêng Ri6',
      description: 'Cơm vàng hạt lép, vị ngọt đậm béo ngậy. Thích hợp khí hậu ĐBSCL & Đông Nam Bộ.',
      badgeText: 'Phổ biến nhất',
      badgeColor: Color(0xFF4CAF50),
      icon: Icons.park_outlined,
    ),
    DurianVariety(
      id: 'monthong',
      name: 'Sầu riêng Monthong (Thái A)',
      description: 'Trái to, cơm dày màu vàng nhạt, hạt lép. Tiêu chuẩn xuất khẩu hàng đầu.',
      badgeText: 'Xuất khẩu A',
      badgeColor: Color(0xFF29B6F6),
      icon: Icons.eco_outlined,
    ),
    DurianVariety(
      id: 'musang_king',
      name: 'Sầu riêng Musang King',
      description: 'Cơm màu vàng như nghệ, mịn không dính tay, vị ngọt béo hạt lép.',
      badgeText: 'Giá trị cao',
      badgeColor: Color(0xFFFFA726),
      icon: Icons.workspace_premium_outlined,
    ),
    DurianVariety(
      id: 'chuong_bo',
      name: 'Sầu riêng Chuồng Bò',
      description: 'Giống truyền thống, cơm nhão ngọt thanh béo ngậy đặc trưng.',
      badgeText: 'Đặc sản',
      badgeColor: Color(0xFFAB47BC),
      icon: Icons.nature_outlined,
    ),
    DurianVariety(
      id: 'sau_huu',
      name: 'Sầu riêng Sáu Hữu',
      description: 'Trái dẻo, vị đậm đà, chịu nhiệt tốt và ít bị xì mủ.',
      badgeText: 'ĐBSCL',
      badgeColor: Color(0xFF26A69A),
      icon: Icons.yard_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title & Subtitle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.psychology_outlined, color: Color(0xFF2E7D32), size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chọn giống sầu riêng',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Chọn giống cây bạn đang trồng để xem quy trình kỹ thuật chuẩn',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Varieties List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: varieties.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = varieties[index];
                return InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    onVarietySelected(item);
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFE8F5E9),
                          child: Icon(item.icon, color: const Color(0xFF2E7D32), size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      item.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF222222),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: item.badgeColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.badgeText,
                                      style: TextStyle(
                                        color: item.badgeColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
