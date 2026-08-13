import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_api_client.dart';

class IoTManagementPage extends ConsumerStatefulWidget {
  const IoTManagementPage({super.key});

  @override
  ConsumerState<IoTManagementPage> createState() => _IoTManagementPageState();
}

class _IoTManagementPageState extends ConsumerState<IoTManagementPage> {
  List<Map<String, dynamic>> _devices = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFarm = 'all';

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    setState(() => _isLoading = true);
    try {
      final client = ref.read(dioApiClientProvider);
      final response = await client.get<dynamic>(
        path: '/iot/my-devices',
        decoder: (json) => json,
      );

      List<Map<String, dynamic>> items = [];
      if (response.data != null) {
        final data = response.data;
        if (data is Map && data['data'] is Map && data['data']['items'] is List) {
          items = List<Map<String, dynamic>>.from(data['data']['items']);
        } else if (data is Map && data['data'] is List) {
          items = List<Map<String, dynamic>>.from(data['data']);
        }
      }

      if (mounted) {
        setState(() {
          _devices = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showReportModal(Map<String, dynamic> device) {
    final titleController = TextEditingController(text: 'Cảm biến mất kết nối định kỳ');
    final descController = TextEditingController();
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  'Báo Cáo Sự Cố: ${device['device_code'] ?? ""}',
                  style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Color(0xFF1B2E25)),
                ),
                const SizedBox(height: 4),
                Text(
                  device['device_name'] ?? 'Thiết bị IoT',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 14),

                const Text('Tiêu đề sự cố:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Nhập lỗi gặp phải...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),

                const Text('Mô tả chi tiết:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: Thiết bị pin yếu sau mưa, tín hiệu 4G chập chờn...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: isSending
                        ? null
                        : () async {
                            setModalState(() => isSending = true);
                            try {
                              final client = ref.read(dioApiClientProvider);
                              await client.post<dynamic>(
                                path: '/iot/fault-report',
                                data: {
                                  'device_code': device['device_code'],
                                  'device_name': device['device_name'],
                                  'farm_name': device['farm_name'],
                                  'issue_title': titleController.text.trim(),
                                  'description': descController.text.trim(),
                                },
                                decoder: (json) => json,
                              );
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã gửi báo cáo sự cố thành công! Kỹ thuật viên sẽ hỗ trợ sớm.'),
                                    backgroundColor: Color(0xFF2E7D32),
                                  ),
                                );
                              }
                            } catch (_) {
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã ghi nhận yêu cầu bảo trì thiết bị.'),
                                    backgroundColor: Color(0xFF2E7D32),
                                  ),
                                );
                              }
                            }
                          },
                    icon: isSending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: Colors.white),
                    label: Text(
                      isSending ? 'Đang Gửi...' : 'Gửi Yêu Cầu Hỗ Trợ',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final farms = _distinctFarms(_devices);

    final filtered = _devices.where((d) {
      final code = (d['device_code'] ?? '').toString().toLowerCase();
      final name = (d['device_name'] ?? '').toString().toLowerCase();
      final farm = (d['farm_name'] ?? '').toString();
      final q = _searchQuery.toLowerCase();

      final matchQuery = q.isEmpty || code.contains(q) || name.contains(q) || farm.toLowerCase().contains(q);
      final matchFarm = _selectedFarm == 'all' || farm == _selectedFarm;

      return matchQuery && matchFarm;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: Text(
          'Quản Lý Thiết Bị IoT (${_devices.length})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchDevices,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo mã IOT-SOIL, tên thiết bị...',
                    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF2E7D32)),
                    filled: true,
                    fillColor: const Color(0xFFF0FDF4),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFC8E6C9)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFC8E6C9)),
                    ),
                  ),
                ),
                if (farms.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFarmChip('all', 'Tất cả vườn'),
                        ...farms.map((f) => Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: _buildFarmChip(f, f),
                            )),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Devices List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
                : filtered.isEmpty
                    ? const Center(child: Text('Không tìm thấy thiết bị IoT nào.'))
                    : RefreshIndicator(
                        color: const Color(0xFF2E7D32),
                        onRefresh: _fetchDevices,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final d = filtered[index];
                            return _buildDeviceCard(d);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  List<String> _distinctFarms(List<Map<String, dynamic>> list) {
    final Set<String> set = {};
    for (final item in list) {
      final name = item['farm_name']?.toString();
      if (name != null && name.isNotEmpty) set.add(name);
    }
    return set.toList();
  }

  Widget _buildFarmChip(String id, String label) {
    final isSelected = _selectedFarm == id;
    return InkWell(
      onTap: () => setState(() => _selectedFarm = id),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFF1F8E9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFC8E6C9)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : const Color(0xFF2E7D32),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceCard(Map<String, dynamic> d) {
    final status = (d['status'] ?? 'Active').toString();
    final isActive = status == 'Active';
    final battery = d['battery_level'] ?? 95;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.memory_rounded, color: Color(0xFF2E7D32), size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        d['device_code'] ?? 'IOT-000',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B2E25)),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fiber_manual_record, size: 8, color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFE65100)),
                    const SizedBox(width: 4),
                    Text(
                      isActive ? 'Hoạt động' : 'Kho thiết bị',
                      style: TextStyle(
                        color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            d['device_name'] ?? 'Thiết bị cảm biến',
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Color(0xFF222222)),
          ),
          const SizedBox(height: 4),

          Text(
            'Vườn: ${d['farm_name'] ?? "Trang trại sầu riêng"}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 10),

          // Battery & Signal row + Report Fault Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.battery_charging_full, size: 15, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 2),
                  Text('$battery% Pin', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 10),
                  const Icon(Icons.wifi, size: 15, color: Color(0xFF1565C0)),
                  const SizedBox(width: 2),
                  const Text('4G LTE', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                ],
              ),
              InkWell(
                onTap: () => _showReportModal(d),
                child: const Row(
                  children: [
                    Icon(Icons.build_circle_outlined, size: 14, color: Color(0xFFE65100)),
                    SizedBox(width: 3),
                    Text(
                      'Báo hỏng',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFFE65100), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
