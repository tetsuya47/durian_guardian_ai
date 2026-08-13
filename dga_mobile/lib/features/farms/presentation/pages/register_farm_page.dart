import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/dio_api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../widgets/farm_gis_map_picker.dart';

class IoTItemEstimate {
  final String deviceType;
  final String deviceName;
  int quantity;
  final int unitPrice;
  final String description;
  final IconData icon;

  IoTItemEstimate({
    required this.deviceType,
    required this.deviceName,
    required this.quantity,
    required this.unitPrice,
    required this.description,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
        'device_type': deviceType,
        'device_name': deviceName,
        'quantity': quantity,
        'unit_price': unitPrice,
        'description': description,
      };
}

class RegisterFarmPage extends ConsumerStatefulWidget {
  const RegisterFarmPage({super.key});

  @override
  ConsumerState<RegisterFarmPage> createState() => _RegisterFarmPageState();
}

class _RegisterFarmPageState extends ConsumerState<RegisterFarmPage> {
  int _currentStep = 1; // 1: Thông tin, 2: Bản đồ GIS, 3: Thiết bị IoT, 4: Xác nhận

  final _formKey = GlobalKey<FormState>();

  // Step 1: General Info
  final _nameController = TextEditingController(text: 'Trang trại Sầu Riêng Bến Tre - Vườn Số 1');
  final _districtController = TextEditingController(text: 'Krông Pắc, Đắk Lắk');
  final _areaController = TextEditingController(text: '3.5');
  final _treeCountController = TextEditingController(text: '600');

  final List<String> _allVarieties = ['Ri6', 'Monthong (Dona)', 'Musang King', 'Black Thorn (Gai Đen)'];
  final Set<String> _selectedVarieties = {'Ri6', 'Monthong (Dona)'};

  // Step 2: GIS Location & Polygon Boundary State
  double _gpsLat = 12.6851;
  double _gpsLng = 108.0387;
  double _gisAreaHa = 3.48;
  int _gisPerimeterMeters = 815;
  List<Map<String, double>> _boundaryPoints = [
    {'lat': 12.6851, 'lng': 108.0387},
    {'lat': 12.6858, 'lng': 108.0392},
    {'lat': 12.6845, 'lng': 108.0398},
    {'lat': 12.6840, 'lng': 108.0382},
  ];

  // Step 3: IoT Recommendations
  late List<IoTItemEstimate> _iotItems;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _initDefaultRecommendations();
  }

  void _initDefaultRecommendations() {
    _iotItems = [
      IoTItemEstimate(
        deviceType: 'soil_sensor',
        deviceName: 'Cảm biến đất & NPK',
        quantity: 6,
        unitPrice: 1200000,
        description: 'DurianSense Pro - Đo độ ẩm, pH, nhiệt độ và dinh dưỡng NPK đất',
        icon: Icons.eco_rounded,
      ),
      IoTItemEstimate(
        deviceType: 'weather_station',
        deviceName: 'Trạm thời tiết 5G',
        quantity: 1,
        unitPrice: 8500000,
        description: 'DGA-Weather 5G - Giám sát lượng mưa, bức xạ UV, hướng gió và đốm nấm',
        icon: Icons.wb_sunny_rounded,
      ),
      IoTItemEstimate(
        deviceType: 'gateway_hub',
        deviceName: 'Gateway Hub',
        quantity: 2,
        unitPrice: 7000000,
        description: 'Edge AI LoRaWAN - Kết nối không dây LoRaWAN / 4G thu thập dữ liệu và xử lý tại biên',
        icon: Icons.router_rounded,
      ),
      IoTItemEstimate(
        deviceType: 'smart_valve',
        deviceName: 'Van tưới thông minh',
        quantity: 2,
        unitPrice: 3600000,
        description: 'SmartValve - Điều khiển tưới bù áp tự động theo lịch khuyến nghị AI Agronomist',
        icon: Icons.water_drop_rounded,
      ),
    ];
  }

  void _autoCalculateIoT() {
    final area = double.tryParse(_areaController.text) ?? 3.5;
    final trees = int.tryParse(_treeCountController.text) ?? 600;

    final recommendedSoil = (area / 0.5).ceil().clamp(4, 30);
    final recommendedWeather = (area / 5.0).ceil().clamp(1, 5);
    final recommendedGateway = (trees / 300).ceil().clamp(1, 10);
    final recommendedValve = (area / 2.0).ceil().clamp(2, 20);

    setState(() {
      _iotItems[0].quantity = recommendedSoil;
      _iotItems[1].quantity = recommendedWeather;
      _iotItems[2].quantity = recommendedGateway;
      _iotItems[3].quantity = recommendedValve;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã tự động tính toán thiết bị IoT theo quy mô diện tích & số cây!'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }

  int get _totalDeviceCount => _iotItems.fold(0, (sum, item) => sum + item.quantity);
  int get _totalAmount => _iotItems.fold(0, (sum, item) => sum + (item.quantity * item.unitPrice));

  @override
  void dispose() {
    _nameController.dispose();
    _districtController.dispose();
    _areaController.dispose();
    _treeCountController.dispose();
    super.dispose();
  }

  Future<void> _submitFarmRegistration() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên trang trại của bạn.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final apiClient = ref.read(dioApiClientProvider);
      final area = double.tryParse(_areaController.text.trim()) ?? 3.5;
      final treeCount = int.tryParse(_treeCountController.text.trim()) ?? 600;

      final payload = {
        'farm_name': _nameController.text.trim(),
        'area_hectare': area,
        'district': _districtController.text.trim(),
        'location': _districtController.text.trim(),
        'gps_lat': _gpsLat,
        'gps_lng': _gpsLng,
        'tree_count': treeCount,
        'durian_varieties': _selectedVarieties.toList(),
        'boundary_points': _boundaryPoints,
        'iot_items': _iotItems.map((e) => e.toJson()).toList(),
        'onboarding_status': 'PENDING_IOT',
      };

      await apiClient.request<dynamic>(
        path: '/farms/register-with-iot',
        method: 'POST',
        data: payload,
        decoder: (json) => json,
      );

      if (mounted) {
        ref.invalidate(dashboardDataProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký trang trại GIS & gửi đơn mua thiết bị IoT thành công!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        context.pop();
      }
    } catch (_) {
      // Fallback submit to standard farms endpoint if register-with-iot fails
      try {
        final apiClient = ref.read(dioApiClientProvider);
        final payload = {
          'farm_name': _nameController.text.trim(),
          'district': _districtController.text.trim(),
          'location': _districtController.text.trim(),
          'area_hectare': double.tryParse(_areaController.text.trim()) ?? 3.5,
          'tree_count': int.tryParse(_treeCountController.text.trim()) ?? 600,
          'durian_varieties': _selectedVarieties.toList(),
          'onboarding_status': 'ACTIVE',
        };

        await apiClient.request<dynamic>(
          path: ApiEndpoints.farms,
          method: 'POST',
          data: payload,
          decoder: (json) => json,
        );

        if (mounted) {
          ref.invalidate(dashboardDataProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký trang trại mới thành công! Dữ liệu đã được lưu vào MongoDB.'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi kết nối: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: const Text(
          'Đăng ký trang trại mới',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // 1. Header Stepper Wizard Bar (4 Steps matching web UI)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStepPill(1, 'Thông tin', 'Trang trại'),
                  _buildStepDivider(),
                  _buildStepPill(2, 'Bản đồ', 'GIS & Vị trí'),
                  _buildStepDivider(),
                  _buildStepPill(3, 'Thiết bị IoT', 'Đề xuất'),
                  _buildStepDivider(),
                  _buildStepPill(4, 'Xác nhận', 'Hoàn tất'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // 2. Step Content Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_currentStep == 1) _buildStep1Info(),
                    if (_currentStep == 2) _buildStep2GISMap(),
                    if (_currentStep == 3) _buildStep3IoTRecommendations(),
                    if (_currentStep == 4) _buildStep4ReviewSummary(),
                  ],
                ),
              ),
            ),
          ),

          // 3. Bottom Action Navigation Bar (Quay lại / Tiếp tục)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 1)
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _currentStep--),
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32), size: 18),
                      label: const Text('Quay lại', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                if (_currentStep > 1) const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _submitting
                        ? null
                        : () {
                            if (_currentStep < 4) {
                              if (_currentStep == 1 && !_formKey.currentState!.validate()) return;
                              setState(() => _currentStep++);
                            } else {
                              _submitFarmRegistration();
                            }
                          },
                    icon: _submitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Icon(_currentStep == 4 ? Icons.check_circle : Icons.arrow_forward, color: Colors.white, size: 18),
                    label: Text(
                      _submitting
                          ? 'Đang Xử Lý...'
                          : _currentStep == 4
                              ? 'Xác nhận & Hoàn tất'
                              : 'Tiếp tục (Bước ${_currentStep + 1})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── STEPPER PILL WIDGET ──────────────────────────────────────────────────
  Widget _buildStepPill(int stepNumber, String title, String subtitle) {
    final isActive = _currentStep == stepNumber;
    final isDone = _currentStep > stepNumber;

    return InkWell(
      onTap: () => setState(() => _currentStep = stepNumber),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isDone
                  ? const Color(0xFF2E7D32)
                  : isActive
                      ? const Color(0xFF2E7D32)
                      : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      '$stepNumber',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? const Color(0xFF2E7D32) : Colors.grey.shade600,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? const Color(0xFF1B2E25) : Colors.grey.shade500,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider() {
    return Container(
      width: 16,
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Colors.grey.shade300,
    );
  }

  // ── STEP 1: THÔNG TIN TRANG TRẠI ──────────────────────────────────────────
  Widget _buildStep1Info() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.eco_rounded, color: Color(0xFF2E7D32), size: 22),
              SizedBox(width: 8),
              Text(
                'Thông tin trang trại',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2E25)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tên trang trại
          _buildLabel('Tên trang trại / Vườn sầu riêng *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            decoration: _inputDecoration(
              hintText: 'VD: Trang trại Sầu Riêng Bến Tre - Vườn Số 1',
              icon: Icons.storefront_rounded,
            ),
            validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tên trang trại' : null,
          ),
          const SizedBox(height: 14),

          // Tỉnh thành / Huyện / Địa chỉ
          _buildLabel('Tỉnh thành / Huyện / Địa chỉ *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _districtController,
            decoration: _inputDecoration(
              hintText: 'Krông Pắc, Đắk Lắk',
              icon: Icons.location_on_outlined,
            ),
            validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập địa chỉ' : null,
          ),
          const SizedBox(height: 14),

          // Area & Tree Count Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Diện tích dự kiến (hecta) *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _areaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration(hintText: '3.5', icon: Icons.straighten_rounded, suffix: 'ha'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Bắt buộc' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Tổng số cây sầu riêng *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _treeCountController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(hintText: '600', icon: Icons.park_outlined, suffix: 'cây'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Bắt buộc' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Giống sầu riêng canh tác
          _buildLabel('Giống sầu riêng canh tác trong vườn *'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allVarieties.map((variety) {
              final isSelected = _selectedVarieties.contains(variety);
              return FilterChip(
                label: Text(variety),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedVarieties.add(variety);
                    } else if (_selectedVarieties.length > 1) {
                      _selectedVarieties.remove(variety);
                    }
                  });
                },
                selectedColor: const Color(0xFF2E7D32),
                backgroundColor: const Color(0xFFF1F8E9),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF2E7D32),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFC8E6C9),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── STEP 2: BẢN ĐỒ GIS & VỊ TRÍ ─────────────────────────────────────────
  Widget _buildStep2GISMap() {
    return Column(
      children: [
        FarmGISMapPicker(
          initialLat: _gpsLat,
          initialLng: _gpsLng,
          initialPolygon: _boundaryPoints,
          onCenterChanged: (lat, lng) {
            setState(() {
              _gpsLat = lat;
              _gpsLng = lng;
            });
          },
          onPolygonChanged: (boundaryPoints, areaHa, perimeterMeters) {
            setState(() {
              _boundaryPoints = boundaryPoints;
              _gisAreaHa = areaHa;
              _gisPerimeterMeters = perimeterMeters;
              if (areaHa > 0) {
                _areaController.text = areaHa.toString();
              }
            });
          },
        ),
      ],
    );
  }


  // ── STEP 3: THIẾT BỊ IOT ĐỀ XUẤT ──────────────────────────────────────────
  Widget _buildStep3IoTRecommendations() {
    final fmt = NumberFormat('#,###', 'vi_VN');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thiết bị IoT đề xuất',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2E25)),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Hệ thống gợi ý thiết bị phù hợp với quy mô & nhu cầu trang trại',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _autoCalculateIoT,
                    icon: const Icon(Icons.calculate_outlined, size: 14, color: Color(0xFF2E7D32)),
                    label: const Text('Tự động tính toán IoT', style: TextStyle(fontSize: 10.5, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8F5E9),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4 IoT Recommended Equipment Cards
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _iotItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _iotItems[index];
                  final subtotal = item.quantity * item.unitPrice;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FBF9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(item.icon, color: const Color(0xFF2E7D32), size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.deviceName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B2E25)),
                                  ),
                                  Text(
                                    item.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${fmt.format(item.unitPrice)} đ / cái',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                            ),

                            // Quantity Stepper
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF2E7D32), size: 20),
                                  onPressed: () {
                                    if (item.quantity > 0) {
                                      setState(() => item.quantity--);
                                    }
                                  },
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2E7D32), size: 20),
                                  onPressed: () {
                                    setState(() => item.quantity++);
                                  },
                                ),
                              ],
                            ),

                            Text(
                              '${fmt.format(subtotal)} đ',
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFFC62828)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Total Cost Summary Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B2E25), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tổng chi phí thiết bị IoT ước tính:',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${fmt.format(_totalAmount)} VNĐ',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Bao gồm $_totalDeviceCount thiết bị',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── STEP 4: XÁC NHẬN & HOÀN TẤT ─────────────────────────────────────────
  Widget _buildStep4ReviewSummary() {
    final fmt = NumberFormat('#,###', 'vi_VN');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Color(0xFF2E7D32), size: 22),
              SizedBox(width: 8),
              Text(
                'Xác nhận thông tin đăng ký',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2E25)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildSummaryRow('Tên trang trại:', _nameController.text),
          _buildSummaryRow('Địa chỉ / Vị trí:', _districtController.text),
          _buildSummaryRow('Diện tích:', '${_areaController.text} ha (GIS: ${_gisAreaHa} ha)'),
          _buildSummaryRow('Tổng số cây:', '${_treeCountController.text} cây sầu riêng'),
          _buildSummaryRow('Giống sầu riêng:', _selectedVarieties.join(', ')),
          _buildSummaryRow('Tọa độ GIS:', '$_gpsLat, $_gpsLng (${_gisPerimeterMeters}m chu vi)'),
          const Divider(height: 20),

          const Text('Danh sách thiết bị IoT đã chọn:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B2E25))),
          const SizedBox(height: 8),
          ..._iotItems.where((i) => i.quantity > 0).map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('• ${item.deviceName} (x${item.quantity})', style: const TextStyle(fontSize: 12.5, color: Color(0xFF333333))),
                  Text('${fmt.format(item.quantity * item.unitPrice)} đ', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                ],
              ),
            );
          }),
          const Divider(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng chi phí IoT:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text('${fmt.format(_totalAmount)} VNĐ', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFFC62828))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 12.5, color: Colors.grey, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1B2E25))),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B2E25)),
    );
  }

  InputDecoration _inputDecoration({required String hintText, required IconData icon, String? suffix}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
      prefixIcon: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
      suffixText: suffix,
      suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
      filled: true,
      fillColor: const Color(0xFFF9FBF9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
      ),
    );
  }
}
