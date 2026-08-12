import 'package:flutter/material.dart';

enum ActivityGroup {
  care('Chăm sóc', Icons.water_drop_outlined, Color(0xFF2E7D32)),
  diseaseControl('Phòng trừ sâu bệnh', Icons.science_outlined, Color(0xFFC62828)),
  treeMaintenance('Chăm sóc cây', Icons.content_cut_outlined, Color(0xFFEF6C00)),
  harvest('Thu hoạch', Icons.inventory_2_outlined, Color(0xFFF57F17)),
  inspection('Kiểm tra', Icons.fact_check_outlined, Color(0xFF1565C0));

  final String title;
  final IconData icon;
  final Color color;

  const ActivityGroup(this.title, this.icon, this.color);
}

class ActivityCategory {
  final String id;
  final String name;
  final ActivityGroup group;
  final IconData icon;
  final bool requiresForm; // If true, opens detailed form (e.g. Fertilizer, Pesticide)

  const ActivityCategory({
    required this.id,
    required this.name,
    required this.group,
    required this.icon,
    this.requiresForm = false,
  });

  static const List<ActivityCategory> defaultCategories = [
    // ─── 1. CHĂM SÓC ────────────────────────────────────────────────────────
    ActivityCategory(
      id: 'water',
      name: 'Tưới nước',
      group: ActivityGroup.care,
      icon: Icons.water_drop,
    ),
    ActivityCategory(
      id: 'irrigation_check',
      name: 'Kiểm tra hệ thống tưới',
      group: ActivityGroup.care,
      icon: Icons.plumbing,
    ),
    ActivityCategory(
      id: 'fertilizer',
      name: 'Bón phân NPK',
      group: ActivityGroup.care,
      icon: Icons.grass,
      requiresForm: true,
    ),
    ActivityCategory(
      id: 'organic_fertilizer',
      name: 'Bón phân hữu cơ',
      group: ActivityGroup.care,
      icon: Icons.compost,
      requiresForm: true,
    ),
    ActivityCategory(
      id: 'bio_fertilizer',
      name: 'Bón phân vi sinh',
      group: ActivityGroup.care,
      icon: Icons.eco,
      requiresForm: true,
    ),
    ActivityCategory(
      id: 'lime_fertilizer',
      name: 'Bón vôi',
      group: ActivityGroup.care,
      icon: Icons.grain,
      requiresForm: true,
    ),
    ActivityCategory(
      id: 'potassium_fertilizer',
      name: 'Bón kali',
      group: ActivityGroup.care,
      icon: Icons.filter_hdr,
      requiresForm: true,
    ),

    // ─── 2. PHÒNG TRỪ SÂU BỆNH ──────────────────────────────────────────────
    ActivityCategory(
      id: 'pesticide',
      name: 'Phun thuốc BVTV',
      group: ActivityGroup.diseaseControl,
      icon: Icons.sanitizer,
      requiresForm: true,
    ),
    ActivityCategory(
      id: 'bio_pesticide',
      name: 'Phun thuốc sinh học',
      group: ActivityGroup.diseaseControl,
      icon: Icons.medical_services_outlined,
      requiresForm: true,
    ),
    ActivityCategory(
      id: 'fungicide',
      name: 'Phun thuốc nấm',
      group: ActivityGroup.diseaseControl,
      icon: Icons.coronavirus_outlined,
      requiresForm: true,
    ),
    ActivityCategory(
      id: 'weeding',
      name: 'Diệt cỏ / Làm cỏ',
      group: ActivityGroup.diseaseControl,
      icon: Icons.cleaning_services,
    ),
    ActivityCategory(
      id: 'collect_diseased_leaves',
      name: 'Thu gom lá bệnh',
      group: ActivityGroup.diseaseControl,
      icon: Icons.delete_outline,
    ),
    ActivityCategory(
      id: 'prune_diseased_branches',
      name: 'Cắt cành bệnh',
      group: ActivityGroup.diseaseControl,
      icon: Icons.content_cut,
    ),
    ActivityCategory(
      id: 'destroy_infected_tree',
      name: 'Tiêu hủy cây bệnh',
      group: ActivityGroup.diseaseControl,
      icon: Icons.local_fire_department_outlined,
    ),

    // ─── 3. CHĂM SÓC CÂY ──────────────────────────────────────────────────
    ActivityCategory(
      id: 'pruning',
      name: 'Tỉa cành',
      group: ActivityGroup.treeMaintenance,
      icon: Icons.park,
    ),
    ActivityCategory(
      id: 'fruit_bagging',
      name: 'Bao trái',
      group: ActivityGroup.treeMaintenance,
      icon: Icons.shopping_bag_outlined,
    ),
    ActivityCategory(
      id: 'fruit_thinning',
      name: 'Tỉa trái',
      group: ActivityGroup.treeMaintenance,
      icon: Icons.nature,
    ),
    ActivityCategory(
      id: 'branch_fixing',
      name: 'Cố định cành',
      group: ActivityGroup.treeMaintenance,
      icon: Icons.healing,
    ),
    ActivityCategory(
      id: 'flower_check',
      name: 'Kiểm tra hoa',
      group: ActivityGroup.treeMaintenance,
      icon: Icons.local_florist,
    ),
    ActivityCategory(
      id: 'fruit_check',
      name: 'Kiểm tra trái',
      group: ActivityGroup.treeMaintenance,
      icon: Icons.sports_baseball,
    ),

    // ─── 4. THU HOẠCH ───────────────────────────────────────────────────────
    ActivityCategory(
      id: 'harvesting',
      name: 'Thu hoạch',
      group: ActivityGroup.harvest,
      icon: Icons.agriculture,
      requiresForm: true,
    ),
    ActivityCategory(
      id: 'sorting',
      name: 'Phân loại sầu riêng',
      group: ActivityGroup.harvest,
      icon: Icons.sort,
    ),
    ActivityCategory(
      id: 'packaging',
      name: 'Đóng gói',
      group: ActivityGroup.harvest,
      icon: Icons.inventory_2,
    ),
    ActivityCategory(
      id: 'transport',
      name: 'Vận chuyển',
      group: ActivityGroup.harvest,
      icon: Icons.local_shipping,
    ),

    // ─── 5. KIỂM TRA ────────────────────────────────────────────────────────
    ActivityCategory(
      id: 'ai_check',
      name: 'Kiểm tra AI',
      group: ActivityGroup.inspection,
      icon: Icons.document_scanner,
    ),
    ActivityCategory(
      id: 'iot_check',
      name: 'Kiểm tra IoT',
      group: ActivityGroup.inspection,
      icon: Icons.sensors,
    ),
    ActivityCategory(
      id: 'ph_check',
      name: 'Đo pH đất',
      group: ActivityGroup.inspection,
      icon: Icons.thermostat,
    ),
    ActivityCategory(
      id: 'ec_check',
      name: 'Đo EC (Dinh dưỡng)',
      group: ActivityGroup.inspection,
      icon: Icons.electric_bolt,
    ),
    ActivityCategory(
      id: 'moisture_check',
      name: 'Đo độ ẩm đất',
      group: ActivityGroup.inspection,
      icon: Icons.water,
    ),
    ActivityCategory(
      id: 'disease_check',
      name: 'Kiểm tra sâu bệnh',
      group: ActivityGroup.inspection,
      icon: Icons.search_sharp,
    ),
  ];
}
