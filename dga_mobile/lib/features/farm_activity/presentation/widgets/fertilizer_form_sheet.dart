import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/farm_activity_log.dart';
import '../../data/models/pesticide_catalog.dart';

class FertilizerFormSheet extends StatefulWidget {
  final Function(FarmActivityLog log) onSubmit;

  const FertilizerFormSheet({
    super.key,
    required this.onSubmit,
  });

  @override
  State<FertilizerFormSheet> createState() => _FertilizerFormSheetState();
}

class _FertilizerFormSheetState extends State<FertilizerFormSheet> {
  late ProductMaterial _selectedMaterial;
  late TextEditingController _quantityController;
  late TextEditingController _treeCountController;
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
    _selectedMaterial = ProductMaterialCatalog.fertilizers.first;
    _quantityController = TextEditingController(text: '25 kg');
    _treeCountController = TextEditingController(text: '120');
    _notesController = TextEditingController(text: 'Bón gốc sau khi trời mưa nhẹ');
    _manufacturerController = TextEditingController(text: 'Công ty Phân Bón Bình Điền');
    _batchNumberController = TextEditingController(text: 'LOT-2026-NPK99');
    _performedByController = TextEditingController(text: 'Nguyễn Văn A');
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _treeCountController.dispose();
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
    final warnings = <String>[];

    // Rule 1: Frequency warning
    if (_selectedZone == 'Zone A') {
      warnings.add('⚠️ Khu vực $_selectedZone vừa bón phân đợt 2 trong tháng. AI khuyến nghị kiểm tra EC đất trước khi bón tiếp.');
    }

    final log = FarmActivityLog(
      id: 'ACT_${now.millisecondsSinceEpoch}',
      date: now,
      farmId: 'F001',
      zoneId: _selectedZone,
      activityType: 'FERTILIZER',
      activityName: 'Bón phân',
      productName: _selectedMaterial.name,
      activeIngredient: _selectedMaterial.activeIngredient,
      manufacturer: _manufacturerController.text.trim(),
      batchNumber: _batchNumberController.text.trim(),
      quantity: _quantityController.text.trim(),
      areaCoverage: '${_treeCountController.text.trim()} cây',
      performedBy: _performedByController.text.trim(),
      notes: _notesController.text.trim(),
      packageImageUrl: _packageImagePath,
      customWarnings: warnings,
      isCompleted: false,
    );

    widget.onSubmit(log);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.grass, color: Colors.green.shade700, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bón Phân - Chuẩn VietGAP',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Nhập thông tin phân bón, nhà sản xuất & số lô',
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
            const Divider(height: 20),

            // Select Fertilizer
            Text('Loại phân bón', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                  items: ProductMaterialCatalog.fertilizers.map((mat) {
                    return DropdownMenuItem<ProductMaterial>(
                      value: mat,
                      child: Text(
                        mat.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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

            // Manufacturer & Batch Row
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
                          hintText: 'Bình Điền / Đầu Trâu...',
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
                          hintText: 'LOT-2026-NPK99',
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

            // Quantity & Trees Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lượng bón', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _quantityController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: '25 kg',
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
                      Text('Số cây áp dụng', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _treeCountController,
                        style: const TextStyle(fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '120',
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
                      Text('Khu vực', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
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

            // Notes
            Text('Ghi chú thực hiện', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(
              controller: _notesController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Bón sau mưa, rải đều quanh tán rễ tơ',
                isDense: true,
                contentPadding: const EdgeInsets.all(10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),

            // Image Picker Button
            Text('Hóa đơn hoặc ảnh bao bì (Tùy chọn)', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            if (_packageImagePath == null)
              OutlinedButton.icon(
                onPressed: _pickPackageImage,
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: const Text('📷 Tải ảnh bao bì / Hóa đơn phân bón', style: TextStyle(fontSize: 12.5)),
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
                    child: Text('Đã đính kèm ảnh bao bì phân bón', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _packageImagePath = null),
                    icon: const Icon(Icons.cancel, color: Colors.red),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save_outlined),
                label: const Text('LƯU NHẬT KÝ BÓN PHÂN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
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
