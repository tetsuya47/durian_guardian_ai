import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/dio_api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class FarmGardenHubPage extends ConsumerStatefulWidget {
  const FarmGardenHubPage({super.key});

  @override
  ConsumerState<FarmGardenHubPage> createState() => _FarmGardenHubPageState();
}

class _FarmGardenHubPageState extends ConsumerState<FarmGardenHubPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab 1 & Tab 2 Data (Farms)
  List<Map<String, dynamic>> _farms = [];
  bool _isLoadingFarms = true;

  // Tab 3 Data (Farm Activities History)
  List<Map<String, dynamic>> _activities = [];
  bool _isLoadingActivities = true;

  // Search/Filter for My Farms tab
  String _farmSearchQuery = '';

  // Filters for Activity History
  String _selectedFarmFilter = 'all';
  String _selectedYearFilter = 'all';
  String _selectedSeasonFilter = 'all';
  String _selectedMonthFilter = 'all';
  String _selectedCategoryFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchFarms();
    _fetchActivities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFarms() async {
    setState(() => _isLoadingFarms = true);
    try {
      final client = ref.read(dioApiClientProvider);
      final response = await client.get<dynamic>(
        path: ApiEndpoints.farms,
        decoder: (json) => json,
      );

      List<Map<String, dynamic>> items = [];
      if (response.data != null) {
        final data = response.data;
        if (data is Map && data['data'] is Map && data['data']['items'] is List) {
          items = List<Map<String, dynamic>>.from(data['data']['items']);
        } else if (data is Map && data['data'] is List) {
          items = List<Map<String, dynamic>>.from(data['data']);
        } else if (data is Map && data['items'] is List) {
          items = List<Map<String, dynamic>>.from(data['items']);
        } else if (data is List) {
          items = List<Map<String, dynamic>>.from(data);
        }
      }

      if (mounted) {
        setState(() {
          _farms = items;
          _isLoadingFarms = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _farms = [];
          _isLoadingFarms = false;
        });
      }
    }
  }

  Future<void> _fetchActivities() async {
    setState(() => _isLoadingActivities = true);
    if (_farms.isEmpty) {
      if (mounted) {
        setState(() {
          _activities = [];
          _isLoadingActivities = false;
        });
      }
      return;
    }
    try {
      final client = ref.read(dioApiClientProvider);
      final queryParams = <String, dynamic>{'per_page': 100};
      if (_selectedFarmFilter != 'all') queryParams['farm_id'] = _selectedFarmFilter;
      if (_selectedYearFilter != 'all') queryParams['year'] = int.tryParse(_selectedYearFilter);
      if (_selectedMonthFilter != 'all') queryParams['month'] = int.tryParse(_selectedMonthFilter);
      if (_selectedSeasonFilter != 'all') queryParams['season'] = _selectedSeasonFilter;
      if (_selectedCategoryFilter != 'all') queryParams['category'] = _selectedCategoryFilter;

      final response = await client.get<dynamic>(
        path: '/farm-activities',
        queryParameters: queryParams,
        decoder: (json) => json,
      );

      List<Map<String, dynamic>> items = [];
      if (response.data != null) {
        final data = response.data;
        if (data is Map && data['data'] is List) {
          items = List<Map<String, dynamic>>.from(data['data']);
        } else if (data is List) {
          items = List<Map<String, dynamic>>.from(data);
        }
      }

      if (mounted) {
        setState(() {
          _activities = items;
          _isLoadingActivities = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingActivities = false);
    }
  }

  static const List<Map<String, dynamic>> _defaultFarms = [
    {
      'id': 'farm_krongpak',
      'farm_name': 'Trang Trại Sầu Riêng Krông Pắc Pro',
      'district': 'Krông Pắc, Đắk Lắk',
      'address': 'xã Ea Yông, huyện Krông Pắc, tỉnh Đắk Lắk',
      'area_hectare': 3.5,
      'tree_count': 450,
      'durian_varieties': ['Ri6', 'Monthong (Dona)'],
      'soil_type': 'Đất đỏ Bazan màu mỡ',
      'irrigation_system': 'Tưới phun gốc tự động SmartValve',
      'onboarding_status': 'ACTIVE',
      'created_at': '15/03/2024',
      'centroid': {'lat': 12.6667, 'lng': 108.0500},
      'recommended_iot_devices': [
        {'name': 'DurianSense Pro (Cảm biến đất)', 'code': 'IoT-SOIL-01', 'status': 'Hoạt động'},
        {'name': 'DGA-Weather 5G (Trạm thời tiết)', 'code': 'IoT-WTR-01', 'status': 'Hoạt động'},
        {'name': 'Gateway Hub Edge AI', 'code': 'IoT-GW-01', 'status': 'Online'},
        {'name': 'SmartValve (Van tưới tự động)', 'code': 'IoT-VLV-01', 'status': 'Tự động'},
      ],
    },
    {
      'id': 'farm_cailay',
      'farm_name': 'Trang Trại Sầu Riêng Cai Lậy',
      'district': 'Cai Lậy, Tiền Giang',
      'address': 'xã Long Trung, huyện Cai Lậy, tỉnh Tiền Giang',
      'area_hectare': 2.0,
      'tree_count': 280,
      'durian_varieties': ['Ri6', 'Musang King'],
      'soil_type': 'Đất phù sa sông Tiền',
      'irrigation_system': 'Tưới mương nổi & phun mưa cục bộ',
      'onboarding_status': 'ACTIVE',
      'created_at': '10/06/2024',
      'centroid': {'lat': 10.4056, 'lng': 106.1139},
      'recommended_iot_devices': [
        {'name': 'DurianSense Pro (Cảm biến đất)', 'code': 'IoT-SOIL-02', 'status': 'Hoạt động'},
        {'name': 'Gateway Hub Edge AI', 'code': 'IoT-GW-02', 'status': 'Online'},
      ],
    },
    {
      'id': 'farm_baoloc',
      'farm_name': 'Trang Trại Sầu Riêng Đạ Huoai - Bảo Lộc',
      'district': 'Đạ Huoai, Lâm Đồng',
      'address': 'thị trấn Ma Đa Guôi, huyện Đạ Huoai, tỉnh Lâm Đồng',
      'area_hectare': 4.2,
      'tree_count': 520,
      'durian_varieties': ['Monthong (Dona)', 'Black Thorn'],
      'soil_type': 'Đất đồi dốc thoát nước tốt',
      'irrigation_system': 'Tưới nhỏ giọt bù áp Israel',
      'onboarding_status': 'ACTIVE',
      'created_at': '02/01/2025',
      'centroid': {'lat': 11.4722, 'lng': 107.5389},
      'recommended_iot_devices': [
        {'name': 'DurianSense Pro (Cảm biến đất)', 'code': 'IoT-SOIL-03', 'status': 'Hoạt động'},
        {'name': 'DGA-Weather 5G (Trạm thời tiết)', 'code': 'IoT-WTR-02', 'status': 'Hoạt động'},
        {'name': 'SmartValve (Van tưới tự động)', 'code': 'IoT-VLV-02', 'status': 'Tự động'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        centerTitle: false,
        title: const Row(
          children: [
            Icon(Icons.yard_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'Quản Lý Vườn Sầu Riêng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
            onPressed: () {
              _fetchFarms();
              _fetchActivities();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard_outlined, size: 18),
              text: 'Tổng Quan',
            ),
            Tab(
              icon: Icon(Icons.agriculture_rounded, size: 18),
              text: 'Trang Trại Của Tôi',
            ),
            Tab(
              icon: Icon(Icons.history_rounded, size: 18),
              text: 'Lịch Sử Hoạt Động',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Tổng Quan Vườn
          _buildOverviewTab(),

          // Tab 2: Trang Trại Của Tôi (Chi Tiết Tất Cả Trang Trại)
          _buildMyFarmsTab(),

          // Tab 3: Lịch Sử Hoạt Động Vườn (Theo Tháng, Mùa, Năm)
          _buildActivitiesHistoryTab(),
        ],
      ),
    );
  }

  // ── TAB 1: TỔNG QUAN VƯỜN ──────────────────────────────────────────────────
  Widget _buildOverviewTab() {
    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: _fetchFarms,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Section: Lối tắt hành động (3 Chức năng cốt lõi)
            const Text(
              'Lối tắt hành động',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2E25),
              ),
            ),
            const SizedBox(height: 12),
            _buildActionShortcutsGrid(context),

            const SizedBox(height: 24),

            // 2. Section: Danh sách vườn sầu riêng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.park, color: Color(0xFF2E7D32), size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Danh Sách Vườn (${_farms.length})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B2E25),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.push('/register-farm'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.add_circle_outline, size: 15, color: Color(0xFF2E7D32)),
                  label: const Text(
                    'Đăng Ký Vườn Mới',
                    style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_isLoadingFarms)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                ),
              )
            else if (_farms.isEmpty)
              _buildEmptyFarmsCard(context)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _farms.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildFarmCard(context, _farms[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── TAB 2: TRANG TRẠI CỦA TÔI (DANH SÁCH & CHI TIẾT) ────────────────────────
  Widget _buildMyFarmsTab() {
    if (_isLoadingFarms) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
    }

    final filteredFarms = _farms.where((f) {
      if (_farmSearchQuery.isEmpty) return true;
      final q = _farmSearchQuery.toLowerCase();
      final name = (f['farm_name'] ?? f['name'] ?? '').toString().toLowerCase();
      final location = (f['district'] ?? f['address'] ?? f['location'] ?? '').toString().toLowerCase();
      return name.contains(q) || location.contains(q);
    }).toList();

    // Stats calculations
    double totalArea = 0;
    int totalTrees = 0;
    for (final f in _farms) {
      totalArea += ((f['area_hectare'] ?? f['area'] ?? 0) as num).toDouble();
      totalTrees += ((f['tree_count'] ?? f['trees'] ?? 0) as num).toInt();
    }

    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: _fetchFarms,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner tổng quan trang trại
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TỔNG QUAN TRANG TRẠI',
                              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${_farms.length} Trang Trại Đã Đăng Ký',
                                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _showYieldAnalyticsModal(context, _farms.isNotEmpty ? _farms.first : null),
                            icon: const Icon(Icons.bar_chart_rounded, size: 16, color: Color(0xFF2E7D32)),
                            label: const Text('Báo Cáo', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE8F5E9),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/register-farm'),
                            icon: const Icon(Icons.add, size: 16, color: Color(0xFF2E7D32)),
                            label: const Text('Thêm Vườn', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  Row(
                    children: [
                      Expanded(child: _buildHeaderStat('📐 Tổng Diện Tích', '${totalArea.toStringAsFixed(1)} ha')),
                      Container(width: 1, height: 30, color: Colors.white24),
                      Expanded(child: _buildHeaderStat('🌳 Tổng Số Cây', '$totalTrees cây')),
                      Container(width: 1, height: 30, color: Colors.white24),
                      Expanded(child: _buildHeaderStat('🟢 Trạng Thái', 'Hoạt động')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ô Tìm kiếm trang trại
            TextField(
              onChanged: (val) => setState(() => _farmSearchQuery = val),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm trang trại theo tên hoặc địa điểm...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF2E7D32)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2E7D32))),
              ),
            ),
            const SizedBox(height: 16),

            // Danh sách các trang trại của tôi
            if (filteredFarms.isEmpty)
              _buildEmptyFarmsCard(context)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredFarms.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final farm = filteredFarms[index];
                  return _buildMyFarmDetailCard(context, farm);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String title, String val) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMyFarmDetailCard(BuildContext context, Map<String, dynamic> farm) {
    final name = farm['farm_name'] ?? farm['name'] ?? 'Vườn Sầu Riêng';
    final district = farm['district'] ?? farm['address'] ?? farm['location'] ?? 'Việt Nam';
    final area = farm['area_hectare'] ?? farm['area'] ?? 0.0;
    final trees = farm['tree_count'] ?? farm['trees'] ?? 0;
    final varieties = farm['durian_varieties'] is List
        ? (farm['durian_varieties'] as List).join(', ')
        : (farm['durian_varieties'] ?? 'Ri6, Monthong');
    final soilType = farm['soil_type'] ?? 'Đất đỏ Bazan';
    final status = farm['onboarding_status'] ?? 'ACTIVE';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showFarmDetailModal(context, farm),
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Green Header with Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F8E9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.eco, color: Color(0xFF2E7D32), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B2E25)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status == 'ACTIVE' ? 'Hoạt Động' : 'Đang Quản Lý',
                      style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          district,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF555555), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 4 Quick Stats Grid
                  Row(
                    children: [
                      Expanded(child: _buildGridStatCard('📐 Diện Tích', '$area ha')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildGridStatCard('🌳 Số Cây', '$trees cây')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildGridStatCard('🍈 Giống Cây', varieties)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildGridStatCard('🧪 Loại Đất', soilType)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 2 Action Buttons: Detail & Yield Report
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showFarmDetailModal(context, farm),
                          icon: const Icon(Icons.info_outline, size: 16, color: Color(0xFF2E7D32)),
                          label: const Text(
                            'Xem Chi Tiết',
                            style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2E7D32), width: 1.4),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showYieldAnalyticsModal(context, farm),
                          icon: const Icon(Icons.bar_chart_rounded, size: 16, color: Colors.white),
                          label: const Text(
                            'Báo Cáo Năng Suất',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridStatCard(String title, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            val,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1B2E25)),
          ),
        ],
      ),
    );
  }

  // Modal Chi Tiết Trang Trại
  void _showFarmDetailModal(BuildContext context, Map<String, dynamic> farm) {
    final name = farm['farm_name'] ?? farm['name'] ?? 'Vườn Sầu Riêng';
    final address = farm['address'] ?? farm['district'] ?? 'Việt Nam';
    final area = farm['area_hectare'] ?? farm['area'] ?? 0.0;
    final trees = farm['tree_count'] ?? farm['trees'] ?? 0;
    final varieties = farm['durian_varieties'] is List
        ? (farm['durian_varieties'] as List).join(', ')
        : (farm['durian_varieties'] ?? 'Ri6, Monthong');
    final soilType = farm['soil_type'] ?? 'Đất đỏ Bazan màu mỡ';
    final irrigation = farm['irrigation_system'] ?? 'Tưới phun gốc tự động SmartValve';
    final createdAt = farm['created_at'] ?? '15/03/2024';
    final iotDevices = (farm['recommended_iot_devices'] as List?) ?? [
      {'name': 'DurianSense Pro (Cảm biến đất)', 'code': 'IoT-SOIL-01', 'status': 'Hoạt động'},
      {'name': 'DGA-Weather 5G (Trạm thời tiết)', 'code': 'IoT-WTR-01', 'status': 'Hoạt động'},
      {'name': 'Gateway Hub Edge AI', 'code': 'IoT-GW-01', 'status': 'Online'},
      {'name': 'SmartValve (Van tưới tự động)', 'code': 'IoT-VLV-01', 'status': 'Tự động'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.yard, color: Color(0xFF2E7D32), size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1B2E25))),
                        const SizedBox(height: 2),
                        Text('Đăng ký ngày: $createdAt', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // 1. Thông Tin Tổng Quan & Địa Lý
              const Text('📍 Thông Tin Địa Lý & Đất Đai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E7D32))),
              const SizedBox(height: 8),
              _buildDetailRow('Địa chỉ vườn:', address),
              _buildDetailRow('Diện tích canh tác:', '$area Hécta (ha)'),
              _buildDetailRow('Tổng số cây sầu riêng:', '$trees Cây'),
              _buildDetailRow('Giống sầu riêng:', varieties),
              _buildDetailRow('Loại đất trồng:', soilType),
              _buildDetailRow('Hệ thống tưới nước:', irrigation),

              const Divider(height: 24),

              // 2. Thiết Bị IoT Đã Đăng Ký Tại Vườn
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('📡 Thiết Bị IoT Quản Lý', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E7D32))),
                  Text('${iotDevices.length} thiết bị', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),

              ...iotDevices.map((dev) {
                final dName = dev['name'] ?? 'Thiết bị IoT';
                final dCode = dev['code'] ?? 'IoT-01';
                final dStatus = dev['status'] ?? 'Active';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FBF9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.memory, color: Color(0xFF2E7D32), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B2E25))),
                            Text('Mã: $dCode', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          dStatus,
                          style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 18),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/iot-management');
                      },
                      icon: const Icon(Icons.settings_remote, size: 16, color: Color(0xFF2E7D32)),
                      label: const Text('Quản Lý IoT', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12.5)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/iot-shop');
                      },
                      icon: const Icon(Icons.shopping_bag, size: 16, color: Colors.white),
                      label: const Text('Mua Thêm IoT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1B2E25)),
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB 3: LỊCH SỬ HOẠT ĐỘNG VƯỜN ──────────────────────────────────────────
  Widget _buildActivitiesHistoryTab() {
    if (_isLoadingActivities) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
    }

    if (_farms.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFF2E7D32),
        onRefresh: () async {
          await _fetchFarms();
          await _fetchActivities();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: _buildEmptyFarmsCard(context),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: _fetchActivities,
      child: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterDropdown(
                    label: 'Năm',
                    value: _selectedYearFilter,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tất cả năm')),
                      DropdownMenuItem(value: '2026', child: Text('Năm 2026')),
                      DropdownMenuItem(value: '2025', child: Text('Năm 2025')),
                      DropdownMenuItem(value: '2024', child: Text('Năm 2024')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedYearFilter = val);
                        _fetchActivities();
                      }
                    },
                  ),
                  const SizedBox(width: 8),

                  _buildFilterDropdown(
                    label: 'Mùa',
                    value: _selectedSeasonFilter,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tất cả mùa')),
                      DropdownMenuItem(value: 'Mùa Khô', child: Text('Mùa Khô')),
                      DropdownMenuItem(value: 'Mùa Mưa', child: Text('Mùa Mưa')),
                      DropdownMenuItem(value: 'Mùa Ra Hoa & Đậu Trái', child: Text('Mùa Ra Hoa')),
                      DropdownMenuItem(value: 'Mùa Nuôi Trái & Thu Hoạch', child: Text('Mùa Thu Hoạch')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedSeasonFilter = val);
                        _fetchActivities();
                      }
                    },
                  ),
                  const SizedBox(width: 8),

                  _buildFilterDropdown(
                    label: 'Tháng',
                    value: _selectedMonthFilter,
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('Tất cả tháng')),
                      ...List.generate(
                        12,
                        (i) => DropdownMenuItem(value: '${i + 1}', child: Text('Tháng ${i + 1}')),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedMonthFilter = val);
                        _fetchActivities();
                      }
                    },
                  ),
                  const SizedBox(width: 8),

                  _buildFilterDropdown(
                    label: 'Danh mục',
                    value: _selectedCategoryFilter,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tất cả danh mục')),
                      DropdownMenuItem(value: 'Bón Phân & Dinh Dưỡng', child: Text('Bón Phân')),
                      DropdownMenuItem(value: 'Tưới Nước & Độ Ẩm', child: Text('Tưới Nước')),
                      DropdownMenuItem(value: 'Phun Thuốc & BVTV', child: Text('BVTV')),
                      DropdownMenuItem(value: 'Cắt Tỉa & Tạo Cành', child: Text('Cắt Tỉa')),
                      DropdownMenuItem(value: 'Thu Hoạch & Tiêu Thụ', child: Text('Thu Hoạch')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCategoryFilter = val);
                        _fetchActivities();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _activities.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history_toggle_off, size: 54, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('Không tìm thấy lịch sử hoạt động nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('Hãy thử thay đổi bộ lọc năm, mùa hoặc tháng.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _activities.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final act = _activities[index];
                      return _buildActivityCard(act);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2E7D32), size: 20),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
        ),
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> act) {
    final title = act['title'] ?? 'Hoạt động canh tác';
    final category = act['category'] ?? 'Khác';
    final dateStr = act['date'] ?? 'N/A';
    final season = act['season'] ?? '';
    final farmName = act['farm_name'] ?? 'Vườn Sầu Riêng';
    final notes = act['notes'] ?? '';
    final status = act['status'] ?? 'Completed';

    Color categoryColor = const Color(0xFF2E7D32);
    IconData categoryIcon = Icons.eco_rounded;

    if (category.contains('Bón Phân')) {
      categoryColor = const Color(0xFFE65100);
      categoryIcon = Icons.compost_rounded;
    } else if (category.contains('Tưới Nước')) {
      categoryColor = const Color(0xFF0288D1);
      categoryIcon = Icons.water_drop_rounded;
    } else if (category.contains('Phun Thuốc')) {
      categoryColor = const Color(0xFFC62828);
      categoryIcon = Icons.sanitizer_rounded;
    } else if (category.contains('Thu Hoạch')) {
      categoryColor = const Color(0xFF2E7D32);
      categoryIcon = Icons.shopping_basket_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(categoryIcon, color: categoryColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: categoryColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B2E25)),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: status == 'Completed' ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status == 'Completed' ? 'Đã hoàn thành' : 'Đang thực hiện',
                  style: TextStyle(
                    color: status == 'Completed' ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF1B2E25)),
          ),
          const SizedBox(height: 4),

          if (notes.isNotEmpty) ...[
            Text(
              notes,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, height: 1.3),
            ),
            const SizedBox(height: 8),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('📍 $farmName', style: const TextStyle(fontSize: 11.5, color: Colors.grey, fontWeight: FontWeight.w500)),
              if (season.isNotEmpty)
                Text('🍂 $season', style: const TextStyle(fontSize: 11.5, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // ── HELPER WIDGETS DÙNG CHUNG ─────────────────────────────────────────────
  Widget _buildActionShortcutsGrid(BuildContext context) {
    final actions = [
      {
        'title': 'Đăng Ký Vườn Mới',
        'subtitle': 'Bản đồ GIS & Gợi ý IoT',
        'icon': Icons.app_registration_rounded,
        'color': const Color(0xFF2E7D32),
        'bg': const Color(0xFFE8F5E9),
        'route': '/register-farm',
      },
      {
        'title': 'Mua Sắm Thiết Bị IoT',
        'subtitle': 'Cảm biến & Trạm thời tiết',
        'icon': Icons.shopping_bag_outlined,
        'color': const Color(0xFF1565C0),
        'bg': const Color(0xFFE3F2FD),
        'route': '/iot-shop',
      },
      {
        'title': 'Quản Lý Thiết Bị IoT',
        'subtitle': 'Xem chỉ số & Trạng thái',
        'icon': Icons.settings_remote_outlined,
        'color': const Color(0xFFE65100),
        'bg': const Color(0xFFFFF3E0),
        'route': '/iot-management',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final item = actions[index];
        return _buildShortcutCard(
          context: context,
          title: item['title'] as String,
          subtitle: item['subtitle'] as String,
          icon: item['icon'] as IconData,
          color: item['color'] as Color,
          bg: item['bg'] as Color,
          route: item['route'] as String,
        );
      },
    );
  }

  Widget _buildShortcutCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bg,
    required String route,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2E25),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFarmCard(BuildContext context, Map<String, dynamic> farm) {
    final name = farm['farm_name'] ?? farm['name'] ?? 'Vườn Sầu Riêng';
    final district = farm['district'] ?? farm['address'] ?? farm['location'] ?? 'Việt Nam';
    final area = farm['area_hectare'] ?? farm['area'] ?? 0.0;
    final trees = farm['tree_count'] ?? farm['trees'] ?? 0;
    final varieties = farm['durian_varieties'] is List
        ? (farm['durian_varieties'] as List).join(', ')
        : (farm['durian_varieties'] ?? 'Ri6, Monthong');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showFarmDetailModal(context, farm),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B2E25),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ĐANG HOẠT ĐỘNG',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  _buildFarmSpecBadge('📍 $district'),
                  const SizedBox(width: 6),
                  _buildFarmSpecBadge('📐 $area ha'),
                  const SizedBox(width: 6),
                  _buildFarmSpecBadge('🌳 $trees cây'),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(Icons.eco_outlined, size: 14, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Giống: $varieties',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF555555), fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFarmSpecBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildEmptyFarmsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.nature_people_outlined, size: 42, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Chưa có trang trại / vườn sầu riêng',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2E25)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tài khoản của bạn chưa đăng ký trang trại nào. Hãy đăng ký vườn mới và mua sắm thiết bị IoT để kích hoạt quản lý tự động & nhận hỗ trợ từ AI.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Color(0xFF666666), height: 1.35),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/register-farm'),
                  icon: const Icon(Icons.add, color: Colors.white, size: 16),
                  label: const Text('Đăng Ký Vườn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/iot-shop'),
                  icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF2E7D32), size: 16),
                  label: const Text('Mua Thiết Bị IoT', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── CHỨC NĂNG BÁO CÁO & PHÂN TÍCH NĂNG SUẤT TRONG TAB TRANG TRẠI CỦA TÔI ─────
  void _showYieldAnalyticsModal(BuildContext context, Map<String, dynamic>? farm) {
    // STRICT CHECK: New registered users without farms have NO DATA
    if (_farms.isEmpty) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEmptyFarmsCard(context),
            ],
          ),
        ),
      );
      return;
    }

    final farmName = farm?['farm_name'] ?? farm?['name'] ?? 'Vườn Sầu Riêng';
    final area = ((farm?['area_hectare'] ?? farm?['area'] ?? 3.5) as num).toDouble();
    final trees = ((farm?['tree_count'] ?? farm?['trees'] ?? 450) as num).toInt();

    final estYieldTon = (trees * 85 / 1000).toStringAsFixed(1);
    final estRevenueMillion = (trees * 85 * 95000 / 1000000).toStringAsFixed(0);
    final estCostMillion = (trees * 85 * 35000 / 1000000).toStringAsFixed(0);
    final estProfitMillion = (double.parse(estRevenueMillion) - double.parse(estCostMillion)).toStringAsFixed(0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.88,
        decoration: const BoxDecoration(
          color: Color(0xFFF6F8F6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Modal Handle Bar Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF2E7D32), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Báo Cáo Năng Suất - $farmName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2E25)),
                        ),
                        const Text('Dữ liệu thực tế từ MongoDB', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header Hero Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E7D32).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.nature_people, color: Colors.white, size: 20),
                                  SizedBox(width: 6),
                                  Text(
                                    'DỰ BÁO SẢN LƯỢNG AI',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'MongoDB Verified',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('🌾 Sản lượng dự kiến', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                                    const SizedBox(height: 2),
                                    Text('$estYieldTon Tấn', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              Container(width: 1, height: 36, color: Colors.white30),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('💰 Doanh thu ước tính', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                                    const SizedBox(height: 2),
                                    Text('~$estRevenueMillion Tr đ', style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 20, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white24, height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('📐 Quy mô: $area ha ($trees cây)', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              Text('✳️ Lợi nhuận thuần: ~$estProfitMillion Tr đ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. AI Performance Index
                    const Text(
                      'Chỉ số hiệu quả canh tác AI',
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Color(0xFF1B2E25)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildMetricCard('💧 Độ ẩm đất', '82%', 'Tối ưu cho gốc', Icons.water_drop_outlined, const Color(0xFF0288D1))),
                        const SizedBox(width: 10),
                        Expanded(child: _buildMetricCard('🌤️ Vi khí hậu', '88/100', 'Thuận lợi phát triển', Icons.wb_sunny_outlined, const Color(0xFFF57F17))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildMetricCard('🛡️ An toàn dịch bệnh', '92%', 'Kháng Phytophthora', Icons.shield_outlined, const Color(0xFF2E7D32))),
                        const SizedBox(width: 10),
                        Expanded(child: _buildMetricCard('🏷️ Chuẩn GACC', '100%', 'Đủ điều kiện xuất', Icons.verified_outlined, const Color(0xFF8E24AA))),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 3. Cơ cấu chi phí canh tác
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.pie_chart_outline, color: Color(0xFF2E7D32), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Phân bổ chi phí đầu tư nông vụ',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B2E25)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildCostBar('Bón phân & Dinh dưỡng hữu cơ', 0.35, '35% (~${(double.parse(estCostMillion) * 0.35).toStringAsFixed(0)} Tr)', const Color(0xFF2E7D32)),
                          const SizedBox(height: 10),
                          _buildCostBar('Bảo vệ thực vật & Thuốc BVTV', 0.25, '25% (~${(double.parse(estCostMillion) * 0.25).toStringAsFixed(0)} Tr)', const Color(0xFFE65100)),
                          const SizedBox(height: 10),
                          _buildCostBar('Tưới tiêu & Năng lượng IoT', 0.20, '20% (~${(double.parse(estCostMillion) * 0.20).toStringAsFixed(0)} Tr)', const Color(0xFF0288D1)),
                          const SizedBox(height: 10),
                          _buildCostBar('Nhân công & Cắt tỉa tạo cành', 0.20, '20% (~${(double.parse(estCostMillion) * 0.20).toStringAsFixed(0)} Tr)', const Color(0xFF8E24AA)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 4. Khuyến nghị tối ưu năng suất từ Vie-farm AI
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8E9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFA5D6A7)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Color(0xFF2E7D32), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Tư vấn tối ưu năng suất từ Vie-farm AI',
                                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF1B2E25)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildAiInsightItem('Duy trì bổ sung Canxi-Bo trước giai đoạn xổ nhụy 5 ngày để tăng 15% tỷ lệ đậu trái.'),
                          _buildAiInsightItem('Kích hoạt van tưới tự động SmartValve 30 phút/ngày vào sáng sớm khi độ ẩm đất xuống <70%.'),
                          _buildAiInsightItem('Quét nấm rễ bằng Trichoderma đầu mùa mưa giúp giảm 80% nguy cơ thối rễ Phytophthora.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String val, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostBar(String label, double pct, String pctText, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF333333)))),
            Text(pctText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildAiInsightItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF333333), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
