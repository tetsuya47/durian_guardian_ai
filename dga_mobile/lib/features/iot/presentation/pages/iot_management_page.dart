import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';

class IoTManagementPage extends StatefulWidget {
  const IoTManagementPage({super.key});

  @override
  State<IoTManagementPage> createState() => _IoTManagementPageState();
}

class _IoTManagementPageState extends State<IoTManagementPage> {
  final List<Map<String, dynamic>> _devices = [
    {
      'code': 'SEN-SOIL-01',
      'name': 'Cảm Biến Đất - Khu Vực 1 (Gốc Ri6)',
      'status': 'Active',
      'battery': 95,
      'signal': 'Mạnh (4/5)',
      'moisture': '78%',
      'last_sync': 'Vừa xong',
    },
    {
      'code': 'SEN-WX-02',
      'name': 'Trạm Thời Tiết - Khu Vực 2',
      'status': 'Active',
      'battery': 88,
      'signal': 'Rất Mạnh (5/5)',
      'moisture': 'Temp: 29.5°C',
      'last_sync': '2 phút trước',
    },
    {
      'code': 'GW-MAIN-01',
      'name': 'Gateway AI Trung Tâm LoRaWAN',
      'status': 'Active',
      'battery': 100,
      'signal': 'Trực tiếp 4G',
      'moisture': '50 thiết bị',
      'last_sync': '24/7 Online',
    },
    {
      'code': 'SEN-SOIL-03',
      'name': 'Cảm Biến Đất - Kho Thiết Bị',
      'status': 'In_Stock',
      'battery': 100,
      'signal': 'Chưa kích hoạt',
      'moisture': '--',
      'last_sync': 'Sẵn sàng',
    },
  ];

  void _showAddDeviceModal() {
    final codeController = TextEditingController();
    final nameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kết Nối Thiết Bị IoT Mới', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            AppSpacing.v12,
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Mã QR / Serial Number thiết bị',
                hintText: 'Ví dụ: SEN-SOIL-2026-X9',
                prefixIcon: Icon(Icons.qr_code),
                border: OutlineInputBorder(),
              ),
            ),
            AppSpacing.v12,
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên gợi nhớ thiết bị',
                hintText: 'Ví dụ: Cảm biến đất Gốc Cây SR-M05',
                prefixIcon: Icon(Icons.label_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            AppSpacing.v20,
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (codeController.text.isNotEmpty) {
                    setState(() {
                      _devices.insert(0, {
                        'code': codeController.text.toUpperCase(),
                        'name': nameController.text.isNotEmpty ? nameController.text : 'Cảm Biến IoT Mới',
                        'status': 'Active',
                        'battery': 100,
                        'signal': 'Mạnh (5/5)',
                        'moisture': 'Khởi tạo...',
                        'last_sync': 'Vừa xong',
                      });
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kết nối cảm biến IoT thành công!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('Xác Nhận Kích Hoạt Thiết Bị'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade800,
                  foregroundColor: Colors.white,
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
    final activeCount = _devices.where((d) => d['status'] == 'Active').length;
    final stockCount = _devices.where((d) => d['status'] == 'In_Stock').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Thiết Bị IoT'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status overview summary card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.memory, color: Colors.blue, size: 24),
                        const SizedBox(width: 8),
                        Text('Tổng Quan Hệ Thống Cảm Biến', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    AppSpacing.v12,
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                            child: Column(
                              children: [
                                Text('$activeCount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green.shade800)),
                                const Text('Đang hoạt động', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                            child: Column(
                              children: [
                                Text('$stockCount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange.shade800)),
                                const Text('Sẵn sàng trong kho', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.v16,

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Danh Sách Thiết Bị (${_devices.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _showAddDeviceModal,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Thêm IoT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
            AppSpacing.v12,

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                final isActive = device['status'] == 'Active';

                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(device['code'] as String, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.green.shade100 : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isActive ? 'ONLINE' : 'IN STOCK',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? Colors.green.shade900 : Colors.orange.shade900),
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.v4,
                        Text(device['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        AppSpacing.v8,
                        const Divider(height: 1),
                        AppSpacing.v8,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.battery_charging_full, size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                Text('Pin: ${device['battery']}%', style: const TextStyle(fontSize: 11)),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.wifi, size: 14, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text('Tín hiệu: ${device['signal']}', style: const TextStyle(fontSize: 11)),
                              ],
                            ),
                            Text('Cập nhật: ${device['last_sync']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
