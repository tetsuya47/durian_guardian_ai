import 'package:intl/intl.dart';

class FarmActivityLog {
  final String id;
  final DateTime date;
  final String farmId;
  final String zoneId;
  final List<String> treeIds;
  final String activityType; // e.g., 'FERTILIZER', 'PESTICIDE', 'WATERING'
  final String activityName; // e.g., 'Bón phân', 'Phun thuốc BVTV'
  final String? productName; // e.g., 'Ridomil Gold 68WG'
  final String? activeIngredient; // e.g., 'Metalaxyl-M 4% + Mancozeb 64%'
  final String? manufacturer; // e.g., 'Syngenta Việt Nam', 'Bayer CropScience'
  final String? batchNumber; // e.g., 'LOT-2026-88A'
  final String? quantity; // e.g., '25 kg', '300 ml'
  final String? areaCoverage; // e.g., '0.5 ha', '120 cây'
  final int phiDays; // Pre-Harvest Interval days
  final DateTime? safeHarvestDate;
  final String performedBy;
  final String? notes;
  final String? packageImageUrl; // Ảnh bao bì / Hóa đơn vật tư
  final List<String> customWarnings; // Cảnh báo vi phạm VietGAP phát sinh
  final bool isCompleted;
  final bool isSyncedLocally; // For offline first tracking

  FarmActivityLog({
    required this.id,
    required this.date,
    required this.farmId,
    required this.zoneId,
    this.treeIds = const [],
    required this.activityType,
    required this.activityName,
    this.productName,
    this.activeIngredient,
    this.manufacturer,
    this.batchNumber,
    this.quantity,
    this.areaCoverage,
    this.phiDays = 0,
    this.safeHarvestDate,
    required this.performedBy,
    this.notes,
    this.packageImageUrl,
    this.customWarnings = const [],
    this.isCompleted = true,
    this.isSyncedLocally = true,
  });

  bool get isPesticide => activityType == 'PESTICIDE' || phiDays > 0;

  bool get hasActivePhiRestriction {
    if (safeHarvestDate == null) return false;
    final today = DateTime.now();
    return today.isBefore(safeHarvestDate!);
  }

  int get remainingPhiDays {
    if (safeHarvestDate == null) return 0;
    final today = DateTime.now();
    final difference = safeHarvestDate!.difference(today).inDays;
    return difference < 0 ? 0 : difference + 1;
  }

  /// Tự động tính toán các cảnh báo vi phạm chuẩn VietGAP / GlobalG.A.P
  List<String> get computedVietgapWarnings {
    final list = <String>[...customWarnings];

    // Cảnh báo 1: Chưa hết thời gian cách ly PHI nhưng đã lên lịch thu hoạch
    if (hasActivePhiRestriction && activityType == 'HARVESTING') {
      list.add('⛔ Vi phạm PHI: Vườn chưa hết thời gian cách ly thuốc ($remainingPhiDays ngày) nhưng đã thu hoạch!');
    }

    // Cảnh báo 2: Liều lượng vượt mức khuyến cáo
    if (quantity != null && (quantity!.contains('500') || quantity!.contains('1000') || quantity!.toLowerCase().contains('vượt'))) {
      list.add('⚠️ Liều lượng ($quantity) có nguy cơ vượt ngưỡng khuyến cáo 250ml/phuy của nhà sản xuất.');
    }

    // Cảnh báo 3: Kiểm tra vật tư chưa phê duyệt trong danh mục trang trại
    if (productName != null && batchNumber == null) {
      list.add('⚠️ Vật tư $productName chưa có Số lô (Batch/Lot). Cần đối chiếu với Danh mục VietGAP phê duyệt.');
    }

    return list;
  }

  String get formattedDate => DateFormat('dd/MM/yyyy').format(date);
  String get formattedSafeHarvestDate =>
      safeHarvestDate != null ? DateFormat('dd/MM/yyyy').format(safeHarvestDate!) : '';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'farmId': farmId,
      'zoneId': zoneId,
      'treeIds': treeIds,
      'activityType': activityType,
      'activityName': activityName,
      'productName': productName,
      'activeIngredient': activeIngredient,
      'manufacturer': manufacturer,
      'batchNumber': batchNumber,
      'quantity': quantity,
      'areaCoverage': areaCoverage,
      'phiDays': phiDays,
      'safeHarvestDate': safeHarvestDate?.toIso8601String(),
      'performedBy': performedBy,
      'notes': notes,
      'packageImageUrl': packageImageUrl,
      'customWarnings': customWarnings,
      'isCompleted': isCompleted,
      'isSyncedLocally': isSyncedLocally,
    };
  }

  factory FarmActivityLog.fromJson(Map<String, dynamic> json) {
    return FarmActivityLog(
      id: json['id'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      farmId: json['farmId'] ?? 'F001',
      zoneId: json['zoneId'] ?? 'Zone A',
      treeIds: (json['treeIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      activityType: json['activityType'] ?? 'OTHER',
      activityName: json['activityName'] ?? 'Công việc',
      productName: json['productName'],
      activeIngredient: json['activeIngredient'],
      manufacturer: json['manufacturer'],
      batchNumber: json['batchNumber'],
      quantity: json['quantity'],
      areaCoverage: json['areaCoverage'],
      phiDays: json['phiDays'] ?? 0,
      safeHarvestDate:
          json['safeHarvestDate'] != null ? DateTime.parse(json['safeHarvestDate']) : null,
      performedBy: json['performedBy'] ?? 'Nông dân',
      notes: json['notes'],
      packageImageUrl: json['packageImageUrl'],
      customWarnings: (json['customWarnings'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isCompleted: json['isCompleted'] ?? true,
      isSyncedLocally: json['isSyncedLocally'] ?? true,
    );
  }

  FarmActivityLog copyWith({
    String? id,
    DateTime? date,
    String? farmId,
    String? zoneId,
    List<String>? treeIds,
    String? activityType,
    String? activityName,
    String? productName,
    String? activeIngredient,
    String? manufacturer,
    String? batchNumber,
    String? quantity,
    String? areaCoverage,
    int? phiDays,
    DateTime? safeHarvestDate,
    String? performedBy,
    String? notes,
    String? packageImageUrl,
    List<String>? customWarnings,
    bool? isCompleted,
    bool? isSyncedLocally,
  }) {
    return FarmActivityLog(
      id: id ?? this.id,
      date: date ?? this.date,
      farmId: farmId ?? this.farmId,
      zoneId: zoneId ?? this.zoneId,
      treeIds: treeIds ?? this.treeIds,
      activityType: activityType ?? this.activityType,
      activityName: activityName ?? this.activityName,
      productName: productName ?? this.productName,
      activeIngredient: activeIngredient ?? this.activeIngredient,
      manufacturer: manufacturer ?? this.manufacturer,
      batchNumber: batchNumber ?? this.batchNumber,
      quantity: quantity ?? this.quantity,
      areaCoverage: areaCoverage ?? this.areaCoverage,
      phiDays: phiDays ?? this.phiDays,
      safeHarvestDate: safeHarvestDate ?? this.safeHarvestDate,
      performedBy: performedBy ?? this.performedBy,
      notes: notes ?? this.notes,
      packageImageUrl: packageImageUrl ?? this.packageImageUrl,
      customWarnings: customWarnings ?? this.customWarnings,
      isCompleted: isCompleted ?? this.isCompleted,
      isSyncedLocally: isSyncedLocally ?? this.isSyncedLocally,
    );
  }
}
