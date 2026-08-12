class ProductMaterial {
  final String id;
  final String name;
  final String category; // 'fertilizer' or 'pesticide'
  final String? activeIngredient; // Hoạt chất (e.g. Metalaxyl-M)
  final int phiDays; // Pre-Harvest Interval days
  final String defaultUnit; // kg, ml, L...
  final String manufacturer;

  const ProductMaterial({
    required this.id,
    required this.name,
    required this.category,
    this.activeIngredient,
    this.phiDays = 0,
    required this.defaultUnit,
    this.manufacturer = 'Vie-farm Standard',
  });
}

class ProductMaterialCatalog {
  static const List<ProductMaterial> fertilizers = [
    ProductMaterial(
      id: 'npk_16_16_8',
      name: 'NPK 16-16-8',
      category: 'fertilizer',
      activeIngredient: 'Đạm - Lân - Kali (16-16-8)',
      phiDays: 0,
      defaultUnit: 'kg',
      manufacturer: 'Phân Bón Bình Điền',
    ),
    ProductMaterial(
      id: 'npk_20_20_15',
      name: 'NPK 20-20-15',
      category: 'fertilizer',
      activeIngredient: 'Đạm - Lân - Kali (20-20-15)',
      phiDays: 0,
      defaultUnit: 'kg',
      manufacturer: 'Phú Mỹ',
    ),
    ProductMaterial(
      id: 'organic_compost',
      name: 'Phân Hữu Cơ Vi Sinh',
      category: 'fertilizer',
      activeIngredient: 'Hữu cơ 15% + Vi sinh',
      phiDays: 0,
      defaultUnit: 'kg',
      manufacturer: 'Sông Gianh',
    ),
    ProductMaterial(
      id: 'lime_calcic',
      name: 'Vôi Nông Nghiệp (CaCO3)',
      category: 'fertilizer',
      activeIngredient: 'Canxi Carbonat 90%',
      phiDays: 0,
      defaultUnit: 'kg',
      manufacturer: 'Khôi Nguyên',
    ),
    ProductMaterial(
      id: 'potassium_sulfate',
      name: 'Kali Sunfat (K2SO4)',
      category: 'fertilizer',
      activeIngredient: 'Kali 50% + Lưu huỳnh',
      phiDays: 0,
      defaultUnit: 'kg',
      manufacturer: 'Haifa Israel',
    ),
  ];

  static const List<ProductMaterial> pesticides = [
    ProductMaterial(
      id: 'ridomil_gold',
      name: 'Ridomil Gold 68WG',
      category: 'pesticide',
      activeIngredient: 'Metalaxyl-M 4% + Mancozeb 64%',
      phiDays: 14,
      defaultUnit: 'ml',
      manufacturer: 'Syngenta Việt Nam',
    ),
    ProductMaterial(
      id: 'anvil_5sc',
      name: 'Anvil 5SC',
      category: 'pesticide',
      activeIngredient: 'Hexaconazole 50g/L',
      phiDays: 7,
      defaultUnit: 'ml',
      manufacturer: 'Syngenta Việt Nam',
    ),
    ProductMaterial(
      id: 'coc_85',
      name: 'Coc 85WP',
      category: 'pesticide',
      activeIngredient: 'Copper Oxychloride 85%',
      phiDays: 7,
      defaultUnit: 'g',
      manufacturer: 'Việt Thắng',
    ),
    ProductMaterial(
      id: 'aliette_800wg',
      name: 'Aliette 800WG',
      category: 'pesticide',
      activeIngredient: 'Fosetyl-Aluminium 800g/kg',
      phiDays: 14,
      defaultUnit: 'g',
      manufacturer: 'Bayer CropScience',
    ),
    ProductMaterial(
      id: 'confidor_100sl',
      name: 'Confidor 100SL',
      category: 'pesticide',
      activeIngredient: 'Imidacloprid 100g/L',
      phiDays: 14,
      defaultUnit: 'ml',
      manufacturer: 'Bayer CropScience',
    ),
    ProductMaterial(
      id: 'bio_tricho',
      name: 'Chế phẩm Trichoderma',
      category: 'pesticide',
      activeIngredient: 'Trichoderma spp. (Nấm đối kháng)',
      phiDays: 0,
      defaultUnit: 'g',
      manufacturer: 'Sinh Học Điền Điền',
    ),
  ];
}
