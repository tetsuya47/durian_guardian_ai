import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RecentInspectionsList extends StatelessWidget {
  final List<dynamic>? inspections;

  const RecentInspectionsList({
    super.key,
    this.inspections,
  });

  void _showActivityDetailSheet(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item['iconBg'] as Color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item['icon'] as IconData, color: item['iconColor'] as Color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Thời gian: ${item['time']} - Ngày ${item['date']}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text(
              'Chi tiết hoạt động:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                item['subtitle'] as String,
                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), height: 1.4),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/history');
                },
                icon: const Icon(Icons.history_rounded),
                label: const Text('Xem Nhật Ký Đầy Đủ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const timelineData = [
      {
        'time': '09:15',
        'date': '04/08',
        'icon': Icons.camera_alt_outlined,
        'iconColor': Color(0xFF16A34A),
        'iconBg': Color(0xFFDCFCE7),
        'title': 'Đã quét lá - Zone B',
        'subtitle': 'AI phát hiện: Thán thư (mức độ trung bình). Khuyên dùng phun Ridomil Gold 68WG.',
      },
      {
        'time': '08:30',
        'date': '04/08',
        'icon': Icons.assignment_outlined,
        'iconColor': Color(0xFF2563EB),
        'iconBg': Color(0xFFDBEAFE),
        'title': 'Ghi nhật ký - Bón phân',
        'subtitle': 'Đã bón NPK 16-16-8 cho 120 cây khu vực Ri6 5 năm tuổi.',
      },
      {
        'time': '07:45',
        'date': '04/08',
        'icon': Icons.sensors_outlined,
        'iconColor': Color(0xFF9333EA),
        'iconBg': Color(0xFFF3E8FF),
        'title': 'Cảm biến IoT',
        'subtitle': 'Độ ẩm đất 68% - Nhiệt độ 27°C - pH đất 6.2 (Tốt).',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Interactive "Xem tất cả"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Text('🕒', style: TextStyle(fontSize: 18)),
                SizedBox(width: 6),
                Text(
                  'Hoạt động gần đây',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    fontFamily: 'Be Vietnam Pro',
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => context.go('/history'),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'Xem tất cả',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Be Vietnam Pro',
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: Color(0xFF16A34A)),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Timeline Container Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.06),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: timelineData.length,
            separatorBuilder: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            itemBuilder: (context, index) {
              final item = timelineData[index];
              return GestureDetector(
                onTap: () => _showActivityDetailSheet(context, item),
                child: _buildTimelineItem(item),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> item) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          // Time & Date Column
          SizedBox(
            width: 46,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['time'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    fontFamily: 'Be Vietnam Pro',
                  ),
                ),
                Text(
                  item['date'] as String,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                    fontFamily: 'Be Vietnam Pro',
                  ),
                ),
              ],
            ),
          ),

          // Icon Circle Node
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item['iconBg'] as Color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item['icon'] as IconData,
              color: item['iconColor'] as Color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Content Middle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item['title'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    fontFamily: 'Be Vietnam Pro',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['subtitle'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontFamily: 'Be Vietnam Pro',
                  ),
                ),
              ],
            ),
          ),

          // Chevron Right Icon
          const Icon(Icons.chevron_right, size: 20, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }
}
