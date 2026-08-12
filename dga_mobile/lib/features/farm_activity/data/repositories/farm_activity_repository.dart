import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/farm_activity_log.dart';

class FarmActivityRepository {
  static const String _storageKey = 'farm_activity_logs_v2';

  /// Fetch all stored activity logs
  Future<List<FarmActivityLog>> getActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final String? rawData = prefs.getString(_storageKey);

    if (rawData == null || rawData.isEmpty) {
      final initialData = _generateInitialDemoData();
      await saveActivities(initialData);
      return initialData;
    }

    try {
      final List<dynamic> jsonList = jsonDecode(rawData);
      return jsonList.map((json) => FarmActivityLog.fromJson(json)).toList();
    } catch (e) {
      final initialData = _generateInitialDemoData();
      await saveActivities(initialData);
      return initialData;
    }
  }

  /// Save activities list to local storage
  Future<void> saveActivities(List<FarmActivityLog> activities) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(activities.map((a) => a.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  /// Add a new activity log
  Future<FarmActivityLog> addActivity(FarmActivityLog newLog) async {
    final activities = await getActivities();
    // Add at top of list
    activities.insert(0, newLog);
    await saveActivities(activities);
    return newLog;
  }

  /// Toggle completion state of a simple checklist item
  Future<List<FarmActivityLog>> toggleActivityCompletion(String activityId) async {
    final activities = await getActivities();
    final index = activities.indexWhere((a) => a.id == activityId);
    if (index != -1) {
      final current = activities[index];
      activities[index] = current.copyWith(isCompleted: !current.isCompleted);
      await saveActivities(activities);
    }
    return activities;
  }

  /// Calculate active PHI restrictions across all recent pesticide activities
  Future<FarmActivityLog?> getLatestActivePhiRestriction() async {
    final activities = await getActivities();
    final today = DateTime.now();

    for (final act in activities) {
      if (act.safeHarvestDate != null && act.safeHarvestDate!.isAfter(today)) {
        return act;
      }
    }
    return null;
  }

  /// Initial demo data to showcase standard VietGAP daily log on first launch
  List<FarmActivityLog> _generateInitialDemoData() {
    final now = DateTime.now();
    return [
      FarmActivityLog(
        id: 'ACT_${now.millisecondsSinceEpoch}_1',
        date: now,
        farmId: 'F001',
        zoneId: 'Zone A',
        activityType: 'WATERING',
        activityName: 'Tưới nước',
        quantity: '30 phút',
        performedBy: 'Nguyễn Văn A',
        isCompleted: true,
      ),
      FarmActivityLog(
        id: 'ACT_${now.millisecondsSinceEpoch}_2',
        date: now,
        farmId: 'F001',
        zoneId: 'Zone A',
        activityType: 'FERTILIZER',
        activityName: 'Bón phân',
        productName: 'NPK 16-16-8',
        activeIngredient: 'Đạm 16%, Lân 16%, Kali 8%',
        manufacturer: 'Công ty Phân Bón Bình Điền',
        batchNumber: 'LOT-2026-NPK99',
        quantity: '25 kg',
        areaCoverage: '120 cây',
        performedBy: 'Nguyễn Văn A',
        notes: 'Bón gốc sau khi trời mưa nhẹ',
        customWarnings: const ['⚠️ Khu vực Zone A vừa bón phân NPK đợt 2. AI khuyến nghị ngưng bón trong 14 ngày tới tránh cháy rễ.'],
        isCompleted: true,
      ),
      FarmActivityLog(
        id: 'ACT_${now.millisecondsSinceEpoch}_3',
        date: now,
        farmId: 'F001',
        zoneId: 'Zone A',
        activityType: 'PESTICIDE',
        activityName: 'Phun thuốc BVTV',
        productName: 'Ridomil Gold 68WG',
        activeIngredient: 'Metalaxyl-M 4% + Mancozeb 64%',
        manufacturer: 'Tập đoàn Syngenta Việt Nam',
        batchNumber: 'LOT-2026-88A',
        quantity: '300 ml',
        areaCoverage: '0.5 ha',
        phiDays: 14,
        safeHarvestDate: now.add(const Duration(days: 14)),
        performedBy: 'Nguyễn Văn A',
        notes: 'Phun phòng nấm lá & xì mủ gốc. Phun sáng sớm, trời lặng gió',
        customWarnings: const ['⛔ Cảnh báo PHI: Cách ly 14 ngày. Tuyệt đối không thu hoạch trái trước thời hạn!'],
        isCompleted: true,
      ),
      FarmActivityLog(
        id: 'ACT_${now.millisecondsSinceEpoch}_4',
        date: now,
        farmId: 'F001',
        zoneId: 'Zone B',
        activityType: 'WEEDING',
        activityName: 'Làm cỏ / Diệt cỏ',
        performedBy: 'Trần Văn B',
        isCompleted: false,
      ),
      FarmActivityLog(
        id: 'ACT_${now.millisecondsSinceEpoch}_5',
        date: now,
        farmId: 'F001',
        zoneId: 'Zone B',
        activityType: 'PRUNING',
        activityName: 'Tỉa cành',
        performedBy: 'Trần Văn B',
        isCompleted: false,
      ),
    ];
  }
}
