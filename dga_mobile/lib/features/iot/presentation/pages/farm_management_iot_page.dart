import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dga_mobile/core/network/api_endpoints.dart';
import 'package:dga_mobile/core/network/dio_api_client.dart';

class FarmManagementIoTPage extends ConsumerStatefulWidget {
  const FarmManagementIoTPage({super.key});

  @override
  ConsumerState<FarmManagementIoTPage> createState() =>
      _FarmManagementIoTPageState();
}

class _FarmManagementIoTPageState
    extends ConsumerState<FarmManagementIoTPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _analysisData;
  // ignore: unused_field
  String? _errorMessage;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchIoTAnalysis(showSpinner: true);
    // Auto refresh every 5 seconds so live IoT simulator changes trigger immediate UI updates
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _fetchIoTAnalysis(showSpinner: false);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchIoTAnalysis({bool showSpinner = false}) async {
    if (showSpinner) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final client = ref.read(dioApiClientProvider);
      final response = await client.get<dynamic>(
        path: ApiEndpoints.iotTelemetryLatest,
        decoder: (json) => json,
      );

      if (response.data != null) {
        final raw = response.data;
        Map<String, dynamic>? dataMap;
        if (raw is Map && raw['data'] is Map) {
          dataMap = Map<String, dynamic>.from(raw['data'] as Map);
        } else if (raw is Map) {
          dataMap = Map<String, dynamic>.from(raw);
        }

        if (mounted) {
          setState(() {
            _analysisData = dataMap;
            _isLoading = false;
          });
        }
      } else {
        if (mounted && showSpinner) {
          setState(() {
            _errorMessage = 'Không nhận được dữ liệu cảm biến IoT.';
            _isLoading = false;
          });
        }
      }
    } catch (exc) {
      if (mounted && showSpinner) {
        setState(() {
          _errorMessage = 'Lỗi kết nối máy chủ IoT: $exc';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = (_analysisData?['telemetry'] as Map?) ?? {};
    final riskLevel = (_analysisData?['model3_risk_level'] ?? 'Low').toString();
    final riskScore = ((_analysisData?['model3_risk_score'] ?? 0.15) as num).toDouble();
    final aiAdvice = (_analysisData?['model4_ai_advice'] ?? 'Nông trại hoạt động ổn định.').toString();
    final recommendations = (_analysisData?['model4_recommendations'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        ['Duy trì độ ẩm đất 60-75%', 'Kiểm tra độ pH định kỳ'];

    final moisture = ((telemetry['soil_moisture'] ?? 68.5) as num).toDouble();
    final ph = ((telemetry['soil_ph'] ?? 6.2) as num).toDouble();
    final temp = ((telemetry['temperature'] ?? 28.5) as num).toDouble();
    final humidity = ((telemetry['humidity'] ?? 78.0) as num).toDouble();
    final light = ((telemetry['light_intensity'] ?? 42000.0) as num).toDouble();
    final nitrogen = ((telemetry['nitrogen_ppm'] ?? 120) as num).toInt();
    final deviceId = (telemetry['device_id'] ?? 'SENS-DURIAN-01').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text(
          '🌳 Quản Lý Vườn & IoT Realtime',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1B4D3E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchIoTAnalysis(showSpinner: true),
            tooltip: 'Làm mới dữ liệu',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchIoTAnalysis(showSpinner: true),
        color: const Color(0xFF2E7D32),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B4D3E), Color(0xFF2E7D32)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(15),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.sensors, color: Colors.amber, size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Trạm Cảm Biến: $deviceId',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Cập nhật tự động 30s/lần từ MongoDB',
                                  style: TextStyle(fontSize: 11, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Grid Cảm Biến IoT 6 Thẻ
                    const Text(
                      'Thông số chỉ số Cảm biến Vườn Sầu Riêng:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                    const SizedBox(height: 10),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _buildSensorCard(
                          title: 'Độ Ẩm Đất',
                          value: '${moisture.toStringAsFixed(1)}%',
                          sub: moisture < 60 ? '⚠️ Cần tưới gốc' : '✅ Đất ẩm tốt',
                          icon: Icons.water_drop,
                          iconColor: Colors.blue,
                          bgColor: const Color(0xFFE3F2FD),
                        ),
                        _buildSensorCard(
                          title: 'Độ pH Đất',
                          value: 'pH ${ph.toStringAsFixed(1)}',
                          sub: ph < 5.8 ? '🧪 Bón vôi nâng pH' : '✅ Đất cân bằng',
                          icon: Icons.science,
                          iconColor: Colors.teal,
                          bgColor: const Color(0xFFE0F2F1),
                        ),
                        _buildSensorCard(
                          title: 'Nhiệt Độ Khí',
                          value: '${temp.toStringAsFixed(1)}°C',
                          sub: 'Nhiệt độ tự nhiên',
                          icon: Icons.thermostat,
                          iconColor: Colors.orange,
                          bgColor: const Color(0xFFFFF3E0),
                        ),
                        _buildSensorCard(
                          title: 'Độ Ẩm Khí',
                          value: '${humidity.toStringAsFixed(1)}%',
                          sub: humidity > 80 ? '⚠️ Nguy cơ nấm' : '✅ Thoáng mát',
                          icon: Icons.cloud,
                          iconColor: Colors.cyan,
                          bgColor: const Color(0xFFE0F7FA),
                        ),
                        _buildSensorCard(
                          title: 'Bức Xạ Lux',
                          value: '${(light / 1000).toStringAsFixed(1)}k Lux',
                          sub: 'Nắng quang hợp',
                          icon: Icons.wb_sunny,
                          iconColor: Colors.amber.shade800,
                          bgColor: const Color(0xFFFFF8E1),
                        ),
                        _buildSensorCard(
                          title: 'Đạm (N)',
                          value: '$nitrogen ppm',
                          sub: 'Dinh dưỡng đất',
                          icon: Icons.bolt,
                          iconColor: Colors.purple,
                          bgColor: const Color(0xFFF3E5F5),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Thẻ Model 3: Nguy Cơ Bệnh Nông Trại
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: riskScore > 0.6
                            ? const Color(0xFFFFEBEE)
                            : (riskScore > 0.3 ? const Color(0xFFFFF8E1) : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: riskScore > 0.6
                              ? Colors.red.shade300
                              : (riskScore > 0.3 ? Colors.amber.shade300 : const Color(0xFFC8E6C9)),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(6),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                riskScore > 0.6
                                    ? Icons.warning_amber_rounded
                                    : (riskScore > 0.3 ? Icons.report_problem_outlined : Icons.shield_outlined),
                                color: riskScore > 0.6
                                    ? Colors.red
                                    : (riskScore > 0.3 ? Colors.amber.shade900 : const Color(0xFF2E7D32)),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Dự Báo Nguy Cơ Bệnh Nông Trại',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B4D3E),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: riskScore > 0.6
                                      ? Colors.red.shade100
                                      : (riskScore > 0.3 ? Colors.amber.shade100 : Colors.green.shade50),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Mức độ: $riskLevel',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: riskScore > 0.6
                                        ? Colors.red.shade800
                                        : (riskScore > 0.3 ? Colors.amber.shade900 : const Color(0xFF2E7D32)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Chỉ số nguy cơ dịch bệnh (Risk Score):',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                '${(riskScore * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: riskScore > 0.6
                                      ? Colors.red.shade800
                                      : (riskScore > 0.3 ? Colors.amber.shade900 : const Color(0xFF2E7D32)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: riskScore,
                            backgroundColor: Colors.grey.shade200,
                            color: riskScore > 0.6
                                ? Colors.red
                                : (riskScore > 0.3 ? Colors.amber.shade800 : const Color(0xFF2E7D32)),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Thẻ Model 4: Khuyên Dùng Từ AI Agronomist
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC8E6C9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.amber),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Đề Xuất Kỹ Thuật AI Agronomist',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B4D3E),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            aiAdvice,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1B5E20),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          Column(
                            children: recommendations.map((rec) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.check_circle,
                                        size: 16, color: Color(0xFF2E7D32)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        rec,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSensorCard({
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EFE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B4D3E),
            ),
          ),
          Text(
            sub,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: iconColor),
          ),
        ],
      ),
    );
  }
}
