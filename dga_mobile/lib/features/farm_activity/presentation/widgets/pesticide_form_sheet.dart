import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../data/models/farm_activity_log.dart';
import '../../data/models/pesticide_catalog.dart';

class PesticideFormSheet extends StatefulWidget {
  final Function(FarmActivityLog log) onSubmit;

  const PesticideFormSheet({
    super.key,
    required this.onSubmit,
  });

  @override
  State<PesticideFormSheet> createState() => _PesticideFormSheetState();
}

class _PesticideFormSheetState extends State<PesticideFormSheet> {
  late ProductMaterial _selectedMaterial;
  late TextEditingController _doseController;
  late TextEditingController _areaController;
  late TextEditingController _reasonController;
  late TextEditingController _notesController;
  late TextEditingController _manufacturerController;
  late TextEditingController _batchNumberController;
  late TextEditingController _performedByController;

  String _selectedZone = 'Zone A';
  String? _packageImagePath;

  final List<String> _zones = ['Zone A', 'Zone B', 'Zone C', 'Toàn trang trại'];

  @override
  void initState() {
    super.initState();
    _selectedMaterial = ProductMaterialCatalog.pesticides.first;
    _doseController = TextEditingController(text: '300 ml');
    _areaController = TextEditingController(text: '0.5 ha');
    _reasonController = TextEditingController(text: 'Phòng nấm lá & xì mủ gốc');
    _notesController = TextEditingController(text: 'Phun sáng sớm, trời lặng gió');
    _manufacturerController = TextEditingController(text: 'Tập đoàn Syngenta Việt Nam');
    _batchNumberController = TextEditingController(text: 'LOT-2026-88A');
    _performedByController = TextEditingController(text: 'Nguyễn Văn A');
  }

  @override
  void dispose() {
    _doseController.dispose();
    _areaController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    _manufacturerController.dispose();
    _batchNumberController.dispose();
    _performedByController.dispose();
    super.dispose();
  }

  Future<void> _pickPackageImage() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null) {
        setState(() {
          _packageImagePath = image.path;
        });
      }
    } catch (_) {}
  }

  void _submit() {
    final now = DateTime.now();
    final safeHarvestDate = now.add(Duration(days: _selectedMaterial.phiDays));

    final warnings = <String>[];

    // Auto Rule 1: Check dosage recommendation
    final doseText = _doseController.text.trim();
    if (doseText.contains('500') || doseText.contains('1000') || doseText.toLowerCase().contains('vượt')) {
      warnings.add('⚠️ Liều lượng ($doseText) vượt ngưỡng khuyến cáo 250ml/phuy của nhà sản xuất.');
    }

    // Auto Rule 2: Check batch number approval
    final batchText = _batchNumberController.text.trim();
    if (batchText.isEmpty) {
      warnings.add('⚠️ Chưa nhập Số lô (Batch/Lot). Cần đối chiếu với Danh mục vật tư VietGAP được phê duyệt.');
    }

    // Auto Rule 3: High frequency spray warning on zone
    if (_selectedZone == 'Zone A') {
      warnings.add('⚠️ Khu vực $_selectedZone đã phun thuốc bảo vệ thực vật đợt 2 trong tuần này.');
    }

    final log = FarmActivityLog(
      id: 'ACT_${now.millisecondsSinceEpoch}',
      date: now,
      farmId: 'F001',
      zoneId: _selectedZone,
      activityType: 'PESTICIDE',
      activityName: 'Phun thuốc BVTV',
      productName: _selectedMaterial.name,
      activeIngredient: _selectedMaterial.activeIngredient,
      manufacturer: _manufacturerController.text.trim(),
      batchNumber: batchText.isNotEmpty ? batchText : 'CHƯA_NHẬP_LÔ',
      quantity: doseText,
      areaCoverage: _areaController.text.trim(),
      phiDays: _selectedMaterial.phiDays,
      safeHarvestDate: safeHarvestDate,
      performedBy: _performedByController.text.trim(),
      notes: '${_reasonController.text.trim()}. ${_notesController.text.trim()}',
      packageImageUrl: _packageImagePath,
      customWarnings: warnings,
      isCompleted: false,
    );

    widget.onSubmit(log);
    Navigator.of(context).pop();

    // Show VietGAP Warning & Safe Harvest Modal
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 12),
            const Text(
              '✓ Đã ghi nhận vật tư.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),

            // Safe Harvest Date Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    'Thời gian cách ly PHI (${log.phiDays} ngày):',
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Không thu hoạch trước ngày',
                    style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.formattedSafeHarvestDate,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Automated VietGAP Violation Warnings Box (If any)
            if (log.computedVietgapWarnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'CẢNH BÁO VIETGAP TỰ ĐỘNG:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...log.computedVietgapWarnings.map((warn) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $warn',
                            style: TextStyle(fontSize: 11, color: Colors.brown.shade900),
                          ),
                        )),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('ĐỒNG Ý VÀ LƯU NHẬT KÝ', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final safeHarvestDate = now.add(Duration(days: _selectedMaterial.phiDays));
    final formattedSafeDate = DateFormat('dd/MM/yyyy').format(safeHarvestDate);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.sanitizer, color: Colors.red.shade700, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Phun Thuốc BVTV - Chuẩn VietGAP',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Nhập thông tin số lô, hoạt chất & truy xuất nguồn gốc',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 24),

            // Select Product (Tên thương mại)
            Text('Tên thương mại thuốc BVTV', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ProductMaterial>(
                  value: _selectedMaterial,
                  isExpanded: true,
                  items: ProductMaterialCatalog.pesticides.map((mat) {
                    return DropdownMenuItem<ProductMaterial>(
                      value: mat,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              mat.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'PHI ${mat.phiDays} ngày',
                              style: TextStyle(fontSize: 10.5, color: Colors.red.shade900, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedMaterial = val;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Active Ingredient (Hoạt chất)
            Text('Hoạt chất hóa học', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _selectedMaterial.activeIngredient ?? 'Metalaxyl-M',
                style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),

            // Manufacturer & Batch Number Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nhà sản xuất', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _manufacturerController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Syngenta / Bayer...',
                          isDense: true,
                          contentPadding: const EdgeInsets.all(10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Số lô (Batch/Lot)', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _batchNumberController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'LOT-2026-88A',
                          isDense: true,
                          contentPadding: const EdgeInsets.all(10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quantity & Area Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Liều lượng', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _doseController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: '300 ml',
                          isDense: true,
                          contentPadding: const EdgeInsets.all(10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Diện tích / Số lượng', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _areaController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: '0.5 ha',
                          isDense: true,
                          contentPadding: const EdgeInsets.all(10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Zone & PerformedBy Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Khu vực áp dụng', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedZone,
                            isExpanded: true,
                            items: _zones
                                .map((z) => DropdownMenuItem(value: z, child: Text(z, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedZone = v);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Người thực hiện', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _performedByController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Nguyễn Văn A',
                          isDense: true,
                          contentPadding: const EdgeInsets.all(10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Reason & Notes
            Text('Lý do phun & Ghi chú', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(
              controller: _notesController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Phun phòng nấm lá & xì mủ gốc. Phun sáng sớm',
                isDense: true,
                contentPadding: const EdgeInsets.all(10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),

            // Image Picker Button (Hóa đơn / Ảnh bao bì)
            Text('Hóa đơn hoặc ảnh bao bì (Tùy chọn)', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            if (_packageImagePath == null)
              OutlinedButton.icon(
                onPressed: _pickPackageImage,
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: const Text('📷 Tải ảnh bao bì / Hóa đơn vật tư', style: TextStyle(fontSize: 12.5)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )
            else
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_packageImagePath!),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Đã đính kèm ảnh bao bì vật tư', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _packageImagePath = null),
                    icon: const Icon(Icons.cancel, color: Colors.red),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // PHI Calculation Banner Preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thời gian cách ly (PHI): ${_selectedMaterial.phiDays} ngày',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.red.shade900),
                        ),
                        Text(
                          'Không thu hoạch trước: $formattedSafeDate',
                          style: TextStyle(fontSize: 11.5, color: Colors.red.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save_outlined),
                label: const Text('LƯU NHẬT KÝ PHUN THUỐC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
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
}
