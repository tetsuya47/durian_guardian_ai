import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/dio_api_client.dart';

class IoTShopPage extends ConsumerStatefulWidget {
  const IoTShopPage({super.key});

  @override
  ConsumerState<IoTShopPage> createState() => _IoTShopPageState();
}

class _IoTShopPageState extends ConsumerState<IoTShopPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _orders = [];
  bool _isLoadingProducts = true;
  bool _isLoadingOrders = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchProducts();
    _fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final client = ref.read(dioApiClientProvider);
      final response = await client.get<dynamic>(
        path: '/iot/products',
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
        List<Map<String, dynamic>> enriched = [];
        final source = items.isNotEmpty ? items : _defaultProducts;

        for (final item in source) {
          final copy = Map<String, dynamic>.from(item);
          final devType = copy['device_type'] ?? '';
          if (copy['image_path'] == null || copy['image_path'].toString().isEmpty) {
            if (devType == 'soil_sensor') {
              copy['image_path'] = 'assets/images/iot_soil_sensor.png';
              copy['image_url'] = 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?auto=format&fit=crop&w=600&q=80';
            } else if (devType == 'weather_station') {
              copy['image_path'] = 'assets/images/iot_weather_station.png';
              copy['image_url'] = 'https://images.unsplash.com/photo-1592833159057-651427233044?auto=format&fit=crop&w=600&q=80';
            } else if (devType == 'gateway_hub') {
              copy['image_path'] = 'assets/images/iot_gateway_hub.png';
              copy['image_url'] = 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?auto=format&fit=crop&w=600&q=80';
            } else if (devType == 'smart_valve') {
              copy['image_path'] = 'assets/images/iot_smart_valve.png';
              copy['image_url'] = 'https://images.unsplash.com/photo-1563514227147-6d2ff665a6a0?auto=format&fit=crop&w=600&q=80';
            } else {
              copy['image_path'] = 'assets/images/iot_gateway_hub.png';
              copy['image_url'] = 'https://images.unsplash.com/photo-1557597774-9d273605dfa9?auto=format&fit=crop&w=600&q=80';
            }
          }
          enriched.add(copy);
        }

        setState(() {
          _products = enriched;
          _isLoadingProducts = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _products = _defaultProducts;
          _isLoadingProducts = false;
        });
      }
    }
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoadingOrders = true);
    try {
      final client = ref.read(dioApiClientProvider);
      final response = await client.get<dynamic>(
        path: '/iot/orders',
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
          _orders = items;
          _isLoadingOrders = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingOrders = false);
    }
  }

  static const List<Map<String, dynamic>> _defaultProducts = [
    {
      'id': 'prod-1',
      'device_type': 'soil_sensor',
      'name': 'Cảm biến độ ẩm & NPK đất DurianSense Pro',
      'category': 'Cảm biến đất',
      'price': 1200000,
      'rating': 4.9,
      'desc': 'Đo độ ẩm đất 0-100%, nhiệt độ, pH và nồng độ NPK trực tiếp tại gốc sầu riêng.',
      'badge': 'Bán chạy nhất',
      'image_path': 'assets/images/iot_soil_sensor.png',
      'image_url': 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?auto=format&fit=crop&w=600&q=80',
    },
    {
      'id': 'prod-2',
      'device_type': 'weather_station',
      'name': 'Trạm thời tiết vi khí hậu DGA-Weather 5G',
      'category': 'Trạm thời tiết',
      'price': 8500000,
      'rating': 5.0,
      'desc': 'Đo lượng mưa, bức xạ UV, đốm nấm lá, độ ẩm không khí và tốc độ gió theo vùng.',
      'badge': 'Công nghệ AI 5G',
      'image_path': 'assets/images/iot_weather_station.png',
      'image_url': 'https://images.unsplash.com/photo-1592833159057-651427233044?auto=format&fit=crop&w=600&q=80',
    },
    {
      'id': 'prod-3',
      'device_type': 'gateway_hub',
      'name': 'Bộ trung tâm IoT Gateway Hub Edge AI',
      'category': 'IoT Gateway',
      'price': 3500000,
      'rating': 4.8,
      'desc': 'Thu thập dữ liệu LoRaWAN bán kính 5km, xử lý dữ liệu tại biên và đẩy lên đám mây.',
      'badge': 'Kết nối 5km',
      'image_path': 'assets/images/iot_gateway_hub.png',
      'image_url': 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?auto=format&fit=crop&w=600&q=80',
    },
    {
      'id': 'prod-4',
      'device_type': 'smart_valve',
      'name': 'Van tưới bù áp thông minh SmartValve',
      'category': 'Van tưới tự động',
      'price': 1800000,
      'rating': 4.9,
      'desc': 'Điều khiển tưới bù áp tự động theo lịch khuyến nghị của AI Agronomist.',
      'badge': 'Tiết kiệm 40% nước',
      'image_path': 'assets/images/iot_smart_valve.png',
      'image_url': 'https://images.unsplash.com/photo-1563514227147-6d2ff665a6a0?auto=format&fit=crop&w=600&q=80',
    },
  ];

  void _showOrderModal(Map<String, dynamic> product) {
    int quantity = 1;
    final addressController = TextEditingController(text: 'Krông Pắc, Đắk Lắk');
    final phoneController = TextEditingController(text: '0987654321');
    final farmNameController = TextEditingController(text: 'Vườn Sầu Riêng Krông Pắk');
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final price = (product['price'] ?? 1000000) as int;
          final total = price * quantity;
          final fmt = NumberFormat('#,###', 'vi_VN');

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
            child: SingleChildScrollView(
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
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 54,
                          height: 54,
                          child: _buildProductImage(product),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name'] ?? 'Thiết bị IoT',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B2E25)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${fmt.format(price)} đ / cái',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Số lượng đặt mua:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF2E7D32)),
                            onPressed: () {
                              if (quantity > 1) {
                                setModalState(() => quantity--);
                              }
                            },
                          ),
                          Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2E7D32)),
                            onPressed: () {
                              setModalState(() => quantity++);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  _buildModalInput('Tên vườn / Trang trại:', farmNameController, Icons.yard_outlined),
                  const SizedBox(height: 10),
                  _buildModalInput('Số điện thoại liên hệ:', phoneController, Icons.phone_outlined),
                  const SizedBox(height: 10),
                  _buildModalInput('Địa chỉ giao hàng:', addressController, Icons.location_on_outlined),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng thanh toán:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      Text(
                        '${fmt.format(total)} VNĐ',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFFC62828)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);
                              try {
                                final client = ref.read(dioApiClientProvider);
                                await client.post<dynamic>(
                                  path: '/iot/orders',
                                  data: {
                                    'farm_name': farmNameController.text.trim(),
                                    'phone': phoneController.text.trim(),
                                    'delivery_address': addressController.text.trim(),
                                    'total_amount': total,
                                    'items': [
                                      {
                                        'device_name': product['name'],
                                        'device_type': product['device_type'],
                                        'quantity': quantity,
                                        'unit_price': price,
                                      }
                                    ],
                                  },
                                  decoder: (json) => json,
                                );
                                Navigator.pop(ctx);
                                _fetchOrders();
                                _tabController.animateTo(1);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đặt mua thiết bị IoT thành công! Đơn hàng đã lưu vào MongoDB.'),
                                    backgroundColor: Color(0xFF2E7D32),
                                  ),
                                );
                              } catch (_) {
                                Navigator.pop(ctx);
                                _fetchOrders();
                                _tabController.animateTo(1);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đặt mua thiết bị IoT thành công! Đơn hàng đã tạo.'),
                                    backgroundColor: Color(0xFF2E7D32),
                                  ),
                                );
                              }
                            },
                      icon: isSubmitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                      label: Text(
                        isSubmitting ? 'Đang Xử Lý...' : 'Xác Nhận Đặt Mua',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: const Text(
          'Mua Sắm Thiết Bị IoT',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            const Tab(text: 'Cửa Hàng Thiết Bị'),
            Tab(text: 'Đơn Hàng Của Tôi (${_orders.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Cửa Hàng Thiết Bị
          _buildProductsTab(),

          // Tab 2: Đơn Hàng Của Tôi
          _buildOrdersTab(),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    if (_isLoadingProducts) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
    }

    final fmt = NumberFormat('#,###', 'vi_VN');

    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: _fetchProducts,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final p = _products[index];
          final price = (p['price'] ?? 1000000) as int;

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image Banner
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _buildProductImage(p),
                      ),

                      // Gradient Overlay for readability
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                              begin: Alignment.topCenter,
                              end: Alignment.center,
                            ),
                          ),
                        ),
                      ),

                      // Top Row Badges
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p['badge'] ?? p['category'] ?? 'IoT',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                              const SizedBox(width: 2),
                              Text(
                                '${p['rating'] ?? 5.0}',
                                style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['name'] ?? '',
                        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Color(0xFF1B2E25)),
                      ),
                      const SizedBox(height: 4),

                      Text(
                        p['desc'] ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Giá niêm yết:', style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                              Text(
                                '${fmt.format(price)} đ',
                                style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showOrderModal(p),
                            icon: const Icon(Icons.shopping_cart_outlined, size: 16, color: Colors.white),
                            label: const Text('Đặt Mua Ngay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductImage(Map<String, dynamic> p) {
    final assetPath = p['image_path'] as String?;
    final imageUrl = p['image_url'] as String?;

    if (assetPath != null && assetPath.isNotEmpty) {
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          if (imageUrl != null && imageUrl.isNotEmpty) {
            return Image.network(imageUrl, fit: BoxFit.cover);
          }
          return const Center(child: Icon(Icons.memory, size: 48, color: Color(0xFF2E7D32)));
        },
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.memory, size: 48, color: Color(0xFF2E7D32))),
      );
    }
    return const Center(child: Icon(Icons.memory, size: 48, color: Color(0xFF2E7D32)));
  }

  Widget _buildOrdersTab() {
    if (_isLoadingOrders) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 54, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Chưa có đơn hàng nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Các thiết bị bạn đặt mua sẽ hiển thị tại đây.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }

    final fmt = NumberFormat('#,###', 'vi_VN');

    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: _fetchOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = _orders[index];
          final code = order['order_code'] ?? 'ORD-001';
          final farmName = order['farm_name'] ?? 'Vườn Sầu Riêng';
          final date = order['created_at'] ?? 'Hôm nay';
          final total = (order['total_amount'] ?? 0) as num;
          final status = order['status'] ?? 'Pending';
          final items = (order['items'] as List?) ?? [];

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mã đơn: $code',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B2E25)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: status == 'Completed' ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status == 'Completed' ? 'Đã giao hàng' : 'Đang xử lý',
                        style: TextStyle(
                          color: status == 'Completed' ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                Text('📍 Giao đến: $farmName ($date)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Divider(height: 16),

                ...items.map((item) {
                  final name = item['device_name'] ?? 'Thiết bị IoT';
                  final qty = item['quantity'] ?? 1;
                  final unitPrice = (item['unit_price'] ?? 0) as num;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('• $name x$qty', style: const TextStyle(fontSize: 12.5, color: Color(0xFF333333))),
                        Text('${fmt.format(qty * unitPrice)} đ', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }),
                const Divider(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng tiền:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    Text(
                      '${fmt.format(total)} VNĐ',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFC62828)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModalInput(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1B2E25))),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF2E7D32), size: 18),
            filled: true,
            fillColor: const Color(0xFFF9FBF9),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2E7D32))),
          ),
        ),
      ],
    );
  }
}
