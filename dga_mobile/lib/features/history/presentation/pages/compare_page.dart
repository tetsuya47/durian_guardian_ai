import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/history_entities.dart';
import '../providers/history_providers.dart';

class ComparePage extends ConsumerStatefulWidget {
  final String? initialTreeName;
  const ComparePage({super.key, this.initialTreeName});

  @override
  ConsumerState<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends ConsumerState<ComparePage> {
  String? _selectedTreeName;
  HistoryLogEntity? _beforeLog;
  HistoryLogEntity? _afterLog;

  @override
  void initState() {
    super.initState();
    _selectedTreeName = widget.initialTreeName;
  }

  Widget _buildImage(String path) {
    if (path.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.image, size: 40),
      );
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, size: 40),
        ),
      );
    }
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, size: 40),
        ),
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, size: 40),
        ),
      );
    }
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.image_not_supported, size: 40),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logsAsync = ref.watch(historyRawLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('So Sánh Trước & Sau'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(child: Text('Không có lịch sử để so sánh'));
          }

          // Lấy danh sách tên cây độc nhất
          final treeNames = logs.map((l) => l.treeName).toSet().toList();
          treeNames.sort();

          if (_selectedTreeName == null && treeNames.isNotEmpty) {
            _selectedTreeName = treeNames.first;
          }

          // Lọc lịch sử của cây được chọn
          final treeLogs = logs.where((l) => l.treeName == _selectedTreeName).toList();
          treeLogs.sort((a, b) => b.id.compareTo(a.id)); // Sắp xếp giảm dần theo ID/thời gian

          // Thiết lập logs mặc định nếu chưa chọn
          if (treeLogs.isNotEmpty) {
            if (_beforeLog == null || _beforeLog!.treeName != _selectedTreeName) {
              _beforeLog = treeLogs.length > 1 ? treeLogs.last : treeLogs.first;
            }
            if (_afterLog == null || _afterLog!.treeName != _selectedTreeName) {
              _afterLog = treeLogs.first;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chọn cây
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        const Icon(Icons.park_outlined, color: Colors.green),
                        AppSpacing.h12,
                        const Text(
                          'Chọn cây:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        AppSpacing.h12,
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedTreeName,
                              isExpanded: true,
                              items: treeNames.map((name) {
                                return DropdownMenuItem<String>(
                                  value: name,
                                  child: Text(name),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedTreeName = val;
                                  _beforeLog = null;
                                  _afterLog = null;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AppSpacing.v16,

                // Chọn đợt chẩn đoán Trước & Sau
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Thời điểm TRƯỚC:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                          AppSpacing.v4,
                          DropdownButtonFormField<HistoryLogEntity>(
                            value: _beforeLog,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: treeLogs.map((log) {
                              return DropdownMenuItem<HistoryLogEntity>(
                                value: log,
                                child: Text('${log.date} ${log.time}'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _beforeLog = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.h12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Thời điểm SAU:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          AppSpacing.v4,
                          DropdownButtonFormField<HistoryLogEntity>(
                            value: _afterLog,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: treeLogs.map((log) {
                              return DropdownMenuItem<HistoryLogEntity>(
                                value: log,
                                child: Text('${log.date} ${log.time}'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _afterLog = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.v20,

                if (_beforeLog != null && _afterLog != null) ...[
                  // Visual Comparison
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Trước', style: TextStyle(fontWeight: FontWeight.bold)),
                            AppSpacing.v8,
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 1.0,
                                child: _buildImage(_beforeLog!.imageUrl),
                              ),
                            ),
                            AppSpacing.v8,
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _beforeLog!.diseaseName.contains('Khỏe mạnh') || _beforeLog!.diseaseName.contains('Không phát hiện')
                                    ? Colors.green.withAlpha(30)
                                    : Colors.red.withAlpha(30),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _beforeLog!.diseaseName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _beforeLog!.diseaseName.contains('Khỏe mạnh') || _beforeLog!.diseaseName.contains('Không phát hiện')
                                      ? Colors.green[800]
                                      : Colors.red[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.h16,
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Sau', style: TextStyle(fontWeight: FontWeight.bold)),
                            AppSpacing.v8,
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 1.0,
                                child: _buildImage(_afterLog!.imageUrl),
                              ),
                            ),
                            AppSpacing.v8,
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _afterLog!.diseaseName.contains('Khỏe mạnh') || _afterLog!.diseaseName.contains('Không phát hiện')
                                    ? Colors.green.withAlpha(30)
                                    : Colors.red.withAlpha(30),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _afterLog!.diseaseName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _afterLog!.diseaseName.contains('Khỏe mạnh') || _afterLog!.diseaseName.contains('Không phát hiện')
                                      ? Colors.green[800]
                                      : Colors.red[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.v24,

                  // Detailed Data Comparison Table
                  const Text('So Sánh Chi Tiết Chỉ Số:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  AppSpacing.v8,
                  Table(
                    border: TableBorder.all(color: Colors.grey[300]!, width: 1, borderRadius: BorderRadius.circular(8)),
                    columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      _buildTableRow('Thời gian', _beforeLog!.date, _afterLog!.date, isHeader: true),
                      _buildTableRow(
                        'Mức độ nặng',
                        _beforeLog!.severity,
                        _afterLog!.severity,
                        customColorB: _beforeLog!.severity == 'Nặng' ? Colors.red : Colors.grey[800],
                        customColorA: _afterLog!.severity == 'Nhẹ' ? Colors.green : Colors.grey[800],
                      ),
                      _buildTableRow(
                        'Độ tin cậy AI',
                        '${(_beforeLog!.confidence * 100).toStringAsFixed(1)}%',
                        '${(_afterLog!.confidence * 100).toStringAsFixed(1)}%',
                      ),
                      _buildTableRow(
                        'Điểm nguy cơ',
                        '${_beforeLog!.riskScore.toStringAsFixed(0)}%',
                        '${_afterLog!.riskScore.toStringAsFixed(0)}%',
                        customColorB: _beforeLog!.riskScore >= 70 ? Colors.red : Colors.grey[800],
                        customColorA: _afterLog!.riskScore < 40 ? Colors.green : Colors.grey[800],
                      ),
                      _buildTableRow(
                        'Nhiệt độ / Độ ẩm',
                        '${_beforeLog!.weather.temperature.toStringAsFixed(0)}°C / ${_beforeLog!.weather.humidity.toStringAsFixed(0)}%',
                        '${_afterLog!.weather.temperature.toStringAsFixed(0)}°C / ${_afterLog!.weather.humidity.toStringAsFixed(0)}%',
                      ),
                    ],
                  ),
                  AppSpacing.v24,

                  // Health Improvement Summary
                  Card(
                    color: Colors.green[50],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.stars, color: Colors.green[700]),
                              AppSpacing.h8,
                              Text(
                                'Đánh giá cải thiện sức khỏe:',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[900], fontSize: 15),
                              ),
                            ],
                          ),
                          AppSpacing.v8,
                          Text(
                            _getHealthSummary(),
                            style: TextStyle(color: Colors.green[900], height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi tải dữ liệu: $err')),
      ),
    );
  }

  TableRow _buildTableRow(String title, String valB, String valA,
      {bool isHeader = false, Color? customColorB, Color? customColorA}) {
    final styleTitle = TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.normal, fontSize: 14);
    final styleValB = TextStyle(
        fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        color: customColorB ?? (isHeader ? Colors.orange[800] : Colors.grey[800]),
        fontSize: 14);
    final styleValA = TextStyle(
        fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        color: customColorA ?? (isHeader ? Colors.green[800] : Colors.grey[800]),
        fontSize: 14);

    return TableRow(
      decoration: BoxDecoration(
        color: isHeader ? Colors.grey[100] : null,
      ),
      children: [
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(title, style: styleTitle),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(valB, style: styleValB),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(valA, style: styleValA),
          ),
        ),
      ],
    );
  }

  String _getHealthSummary() {
    if (_beforeLog == null || _afterLog == null) return '';
    final isBHealthy = _beforeLog!.diseaseName.contains('Khỏe mạnh') || _beforeLog!.diseaseName.contains('Không phát hiện');
    final isAHealthy = _afterLog!.diseaseName.contains('Khỏe mạnh') || _afterLog!.diseaseName.contains('Không phát hiện');

    if (isBHealthy && isAHealthy) {
      return 'Cây sầu riêng luôn duy trì trạng thái Khỏe mạnh qua cả 2 thời kỳ. Cần tiếp tục duy trì chế độ phân bón và tưới nước hiện tại.';
    }
    if (!isBHealthy && isAHealthy) {
      return 'Cải thiện xuất sắc! Cây từ trạng thái nhiễm bệnh (${_beforeLog!.diseaseName}) đã phục hồi hoàn toàn thành Khỏe mạnh nhờ chế độ chăm sóc hợp lý.';
    }
    if (!isBHealthy && !isAHealthy) {
      if (_afterLog!.riskScore < _beforeLog!.riskScore) {
        return 'Tình trạng nhiễm bệnh (${_afterLog!.diseaseName}) có dấu hiệu thuyên giảm. Chỉ số nguy cơ đã giảm từ ${_beforeLog!.riskScore.toStringAsFixed(0)}% xuống ${_afterLog!.riskScore.toStringAsFixed(0)}%. Tiếp tục duy trì phác đồ điều trị.';
      } else if (_afterLog!.riskScore > _beforeLog!.riskScore) {
        return 'Cảnh báo! Tình trạng bệnh của cây có chiều hướng nghiêm trọng hơn (nguy cơ tăng lên ${_afterLog!.riskScore.toStringAsFixed(0)}%). Cần kiểm tra lại nguồn nước, liều lượng thuốc bảo vệ thực vật và liên hệ chuyên gia nông nghiệp.';
      }
      return 'Tình trạng bệnh chưa có sự thay đổi rõ rệt. Cần tiếp tục theo dõi thêm từ 3 đến 5 ngày tới.';
    }
    return 'Cây có dấu hiệu nhiễm bệnh mới từ khi khỏe mạnh. Cần cách ly và xử lý thuốc bảo vệ thực vật ngay lập tức.';
  }
}
