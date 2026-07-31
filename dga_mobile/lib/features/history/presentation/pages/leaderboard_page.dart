import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../providers/history_providers.dart';

class LeaderboardPage extends ConsumerStatefulWidget {
  const LeaderboardPage({super.key});

  @override
  ConsumerState<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends ConsumerState<LeaderboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedZone = 'Khu A';

  // Dữ liệu mock phục vụ xếp hạng quản lý phân khu tốt
  final List<Map<String, dynamic>> _leaderboardData = [
    {
      'rank': 1,
      'zone': 'Khu A',
      'farm': 'Vườn Sầu Riêng Hapii 1',
      'score': 98.5,
      'variety': 'Sầu riêng Ri6',
      'manager': 'Trần Văn Bao',
      'phone': '0987.654.321',
      'healthy_rate': '97%',
      'inspect_count': 24,
    },
    {
      'rank': 2,
      'zone': 'Khu C',
      'farm': 'Vườn Sầu Riêng Hapii 1',
      'score': 92.0,
      'variety': 'Sầu riêng Monthong',
      'manager': 'Nguyễn Thị Hoa',
      'phone': '0912.345.678',
      'healthy_rate': '91%',
      'inspect_count': 20,
    },
    {
      'rank': 3,
      'zone': 'Khu B',
      'farm': 'Vườn Sầu Riêng Hapii 1',
      'score': 87.5,
      'variety': 'Sầu riêng Musang King',
      'manager': 'Lê Hoàng Nam',
      'phone': '0909.123.456',
      'healthy_rate': '86%',
      'inspect_count': 18,
    },
    {
      'rank': 4,
      'zone': 'Khu D',
      'farm': 'Vườn Sầu Riêng Hapii 2',
      'score': 82.0,
      'variety': 'Sầu riêng Ri6',
      'manager': 'Phạm Minh Đức',
      'phone': '0933.999.888',
      'healthy_rate': '80%',
      'inspect_count': 16,
    },
    {
      'rank': 5,
      'zone': 'Khu E',
      'farm': 'Vườn Sầu Riêng Hapii 2',
      'score': 74.5,
      'variety': 'Sầu riêng Monthong',
      'manager': 'Hoàng Văn Thái',
      'phone': '0944.555.666',
      'healthy_rate': '71%',
      'inspect_count': 14,
    },
  ];

  // Dữ liệu mock thống kê dịch bệnh theo phân khu
  final Map<String, List<Map<String, dynamic>>> _zoneDiseaseStats = {
    'Khu A': [
      {'disease': 'Khỏe mạnh', 'percentage': 75.0, 'count': 45, 'color': Colors.green},
      {'disease': 'Bệnh đốm lá', 'percentage': 15.0, 'count': 9, 'color': Colors.orange},
      {'disease': 'Sâu đục quả', 'percentage': 10.0, 'count': 6, 'color': Colors.red},
    ],
    'Khu B': [
      {'disease': 'Khỏe mạnh', 'percentage': 50.0, 'count': 30, 'color': Colors.green},
      {'disease': 'Bệnh thối rễ', 'percentage': 30.0, 'count': 18, 'color': Colors.red},
      {'disease': 'Bệnh xì mủ thân', 'percentage': 20.0, 'count': 12, 'color': Colors.orange},
    ],
    'Khu C': [
      {'disease': 'Khỏe mạnh', 'percentage': 90.0, 'count': 54, 'color': Colors.green},
      {'disease': 'Bệnh đốm lá', 'percentage': 10.0, 'count': 6, 'color': Colors.orange},
    ],
    'Khu D': [
      {'disease': 'Khỏe mạnh', 'percentage': 60.0, 'count': 36, 'color': Colors.green},
      {'disease': 'Sâu đục quả', 'percentage': 25.0, 'count': 15, 'color': Colors.red},
      {'disease': 'Bệnh phấn trắng', 'percentage': 15.0, 'count': 9, 'color': Colors.blue},
    ],
    'Khu E': [
      {'disease': 'Khỏe mạnh', 'percentage': 40.0, 'count': 24, 'color': Colors.green},
      {'disease': 'Bệnh xì mủ thân', 'percentage': 35.0, 'count': 21, 'color': Colors.red},
      {'disease': 'Bệnh thối rễ', 'percentage': 25.0, 'count': 15, 'color': Colors.orange},
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showContactDialog(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.contact_phone, color: Colors.green),
            AppSpacing.h8,
            const Text('Hỏi Kinh Nghiệm'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Người phụ trách: ${item['manager']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            AppSpacing.v8,
            Text('Khu vực: ${item['zone']} (${item['farm']})'),
            AppSpacing.v4,
            Text('Giống cây trồng: ${item['variety']}'),
            AppSpacing.v4,
            Text('Điểm chăm sóc: ${item['score']} / 100'),
            AppSpacing.v12,
            const Divider(),
            AppSpacing.v8,
            Row(
              children: [
                const Icon(Icons.phone, size: 20, color: Colors.green),
                AppSpacing.h8,
                Text(item['phone'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
            AppSpacing.v8,
            Row(
              children: [
                const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.blue),
                AppSpacing.h8,
                const Text('Gửi tin nhắn nội bộ', style: TextStyle(fontSize: 15, color: Colors.blue)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đang kết nối cuộc gọi tới ${item['manager']}...')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Gọi Điện'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống Kê & Thi Đua'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.emoji_events_outlined), text: 'Bảng Thi Đua'),
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Dịch Bệnh Khu Vực'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Leaderboard
          _buildLeaderboardTab(),
          // Tab 2: Disease Stats
          _buildDiseaseStatsTab(),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _leaderboardData.length,
      itemBuilder: (context, index) {
        final item = _leaderboardData[index];
        final rank = item['rank'] as int;

        // Custom styling for top 3
        Color rankColor = Colors.grey[400]!;
        if (rank == 1) rankColor = Colors.amber[700]!;
        if (rank == 2) rankColor = Colors.blueGrey[400]!;
        if (rank == 3) rankColor = Colors.brown[400]!;

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Rank badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: rankColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      rank.toString(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                AppSpacing.h16,

                // Zone & Manager details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item['zone'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          AppSpacing.h8,
                          Text(
                            '(${item['variety']})',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                      AppSpacing.v4,
                      Text('Quản lý: ${item['manager']}', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                      AppSpacing.v4,
                      Row(
                        children: [
                          Icon(Icons.health_and_safety_outlined, size: 16, color: Colors.green[700]),
                          AppSpacing.h4,
                          Text(
                            'Tỷ lệ khỏe mạnh: ${item['healthy_rate']}',
                            style: TextStyle(color: Colors.green[800], fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Care score & action button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item['score']} đ',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800], fontSize: 14),
                      ),
                    ),
                    AppSpacing.v8,
                    InkWell(
                      onTap: () => _showContactDialog(context, item),
                      child: Text(
                        'Hỏi kinh nghiệm',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiseaseStatsTab() {
    final theme = Theme.of(context);
    final stats = _zoneDiseaseStats[_selectedZone] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phân khu selector
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  const Icon(Icons.grid_view_outlined, color: Colors.green),
                  AppSpacing.h12,
                  const Text('Chọn phân khu:', style: TextStyle(fontWeight: FontWeight.bold)),
                  AppSpacing.h12,
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedZone,
                        items: _zoneDiseaseStats.keys.map((zone) {
                          return DropdownMenuItem<String>(
                            value: zone,
                            child: Text(zone),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedZone = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.v20,

          // Zone summary status card
          Card(
            color: Colors.green[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green[700], size: 28),
                  AppSpacing.h12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đánh giá chung $_selectedZone:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[900], fontSize: 15),
                        ),
                        AppSpacing.v4,
                        Text(
                          _getZoneSummaryText(),
                          style: TextStyle(color: Colors.green[900], height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.v24,

          // Disease distribution list
          const Text(
            'Phân Bố Tỷ Lệ Bệnh Hại:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          AppSpacing.v12,
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stats.length,
            itemBuilder: (context, index) {
              final item = stats[index];
              final disease = item['disease'] as String;
              final percentage = item['percentage'] as double;
              final count = item['count'] as int;
              final color = item['color'] as Color;

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          AppSpacing.h8,
                          Text(disease, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text('$count cây (${percentage.toStringAsFixed(0)}%)'),
                    ],
                  ),
                  AppSpacing.v8,
                  // Progress indicator representing percentage
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 10,
                    ),
                  ),
                  AppSpacing.v16,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _getZoneSummaryText() {
    if (_selectedZone == 'Khu A') {
      return 'Tình trạng chăm sóc Tốt. Giống sầu riêng trồng chủ yếu là Ri6. Cảnh báo dịch bệnh ở mức Thấp (dưới 25% cây nhiễm bệnh).';
    }
    if (_selectedZone == 'Khu B') {
      return 'Cần chú ý! Tỷ lệ nhiễm bệnh thối rễ và xì mủ thân đang có xu hướng tăng cao (40-50% cây bị ảnh hưởng). Cần bổ sung thoát nước và bón vôi.';
    }
    if (_selectedZone == 'Khu C') {
      return 'Xuất sắc! Hơn 90% số cây khỏe mạnh và không ghi nhận đợt bùng phát sâu bệnh hại nguy hiểm nào trong vòng 30 ngày qua.';
    }
    if (_selectedZone == 'Khu D') {
      return 'Tình trạng chăm sóc Trung bình. Phát hiện dịch Sâu đục quả cục bộ trên một số cây giống Ri6. Cần phun phòng trừ.';
    }
    return 'Cảnh báo nguy cơ cao! Tỷ lệ nhiễm bệnh xì mủ thân Phytophthora chiếm 35% tổng số cây trong khu vực. Cần tăng cường quét thuốc vào vết bệnh.';
  }
}
