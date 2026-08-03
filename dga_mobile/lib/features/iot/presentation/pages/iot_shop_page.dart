import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';

class IoTItem {
  final String id;
  final String title;
  final String subtitle;
  final int price;
  final String icon;
  final String description;

  const IoTItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.icon,
    required this.description,
  });
}

class IoTShopPage extends StatefulWidget {
  const IoTShopPage({super.key});

  @override
  State<IoTShopPage> createState() => _IoTShopPageState();
}

class _IoTShopPageState extends State<IoTShopPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<IoTItem> _products = [
    IoTItem(
      id: 'IOT-GW-01',
      title: 'Gateway AI LoRaWAN / 4G Trung Tâm',
      subtitle: 'Kết nối bán kính 3km, hỗ trợ 50 cảm biến',
      price: 2500000,
      icon: 'router',
      description: 'Thiết bị thu phát trung tâm tự động đồng bộ dữ liệu cảm biến đất và thời tiết về hệ thống AI.',
    ),
    IoTItem(
      id: 'IOT-SOIL-02',
      title: 'Cảm Biến Đất Đa Tầng (Độ Ẩm, pH, EC)',
      subtitle: 'Đo độ ẩm sâu 30cm-60cm, pin năng lượng mặt trời',
      price: 850000,
      icon: 'sensors',
      description: 'Giám sát liên tục độ ẩm đất, nồng độ dinh dưỡng EC và độ pH gốc cây sầu riêng.',
    ),
    IoTItem(
      id: 'IOT-[#WX]-03',
      title: 'Trạm Thời Tiết Vườn Realtime',
      subtitle: 'Đo lượng mưa, tốc độ gió, nhiệt độ & độ ẩm không khí',
      price: 1800000,
      icon: 'thunderstorm',
      description: 'Cảnh báo nguy cơ nấm bệnh chóp lá & xì mủ thân theo chỉ số thời tiết thực tế.',
    ),
    IoTItem(
      id: 'IOT-CAM-04',
      title: 'Camera AI 4K Giám Sát Cây Trồng',
      subtitle: 'Xử lý hình ảnh AI tại chỗ, phát hiện sâu bệnh tự động',
      price: 1200000,
      icon: 'videocam',
      description: 'Quét liên tục hình ảnh lá và trái sầu riêng, phát hiện bọ trĩ, thán thư tức thì.',
    ),
  ];

  final List<Map<String, dynamic>> _myOrders = [
    {
      'order_id': 'ORD-2026-8801',
      'item_title': 'Cảm Biến Đất Đa Tầng x2',
      'total': 1700000,
      'status': 'Đã Giao Hàng',
      'date': '01/08/2026',
    },
    {
      'order_id': 'ORD-2026-8805',
      'item_title': 'Gateway AI LoRaWAN / 4G x1',
      'total': 2500000,
      'status': 'Đang Vận Chuyển',
      'date': '02/08/2026',
    },
  ];

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

  void _showOrderDialog(IoTItem item) {
    int quantity = 1;
    final addressController = TextEditingController(text: 'Phong Điền, Cần Thơ');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Đặt Mua Thiết Bị IoT', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              AppSpacing.v12,
              Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${item.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} VNĐ',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
              AppSpacing.v16,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Số lượng:'),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: quantity > 1 ? () => setModalState(() => quantity--) : null,
                      ),
                      Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setModalState(() => quantity++),
                      ),
                    ],
                  ),
                ],
              ),
              AppSpacing.v12,
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ giao hàng',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              AppSpacing.v20,
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _myOrders.insert(0, {
                        'order_id': 'ORD-2026-${1000 + _myOrders.length}',
                        'item_title': '${item.title} x$quantity',
                        'total': item.price * quantity,
                        'status': 'Đã Xác Nhận Đơn',
                        'date': 'Vừa xong',
                      });
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đặt mua thành công! Đơn hàng đang được chuẩn bị.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _tabController.animateTo(1);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade800,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Xác Nhận Đặt Mua (${((item.price * quantity)).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'router':
        return Icons.router_outlined;
      case 'sensors':
        return Icons.sensors_outlined;
      case 'thunderstorm':
        return Icons.thunderstorm_outlined;
      case 'videocam':
        return Icons.videocam_outlined;
      default:
        return Icons.devices_other;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mua Sắm Thiết Bị Lẻ & Đơn Hàng IoT'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.storefront), text: 'Cửa Hàng IoT'),
            Tab(icon: Icon(Icons.shopping_bag_outlined), text: 'Đơn Hàng Của Tôi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: SHOP CATALOG
          ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                            child: Icon(_getIconData(product.icon), color: theme.colorScheme.primary, size: 26),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                AppSpacing.v4,
                                Text(product.subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.v12,
                      Text(product.description, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                      AppSpacing.v12,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${product.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.green),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showOrderDialog(product),
                            icon: const Icon(Icons.shopping_cart_checkout, size: 16),
                            label: const Text('Đặt Mua'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // TAB 2: MY ORDERS
          _myOrders.isEmpty
              ? const Center(child: Text('Chưa có đơn hàng IoT nào'))
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _myOrders.length,
                  itemBuilder: (context, index) {
                    final order = _myOrders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.local_shipping, color: Colors.white, size: 20),
                        ),
                        title: Text(order['item_title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Mã đơn: ${order['order_id']} · ${order['date']}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${(order['total'] as int).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            Text(order['status'] as String, style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
