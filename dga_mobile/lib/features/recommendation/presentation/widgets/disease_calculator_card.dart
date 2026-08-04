import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';

class DiseaseCalculatorCard extends StatefulWidget {
  const DiseaseCalculatorCard({super.key});

  @override
  State<DiseaseCalculatorCard> createState() => _DiseaseCalculatorCardState();
}

class _DiseaseCalculatorCardState extends State<DiseaseCalculatorCard> {
  String _selectedDisease = 'Phytophthora (Thối gốc xì mủ)';
  String _selectedAge = '4 - 7 năm (Cây kinh doanh)';
  double _treeCount = 10;
  String _tankType = 'Phuy 200L';

  final List<String> _diseases = [
    'Phytophthora (Thối gốc xì mủ)',
    'Anthracnose (Thối đốm mắt cua)',
    'Algal Leaf Spot (Đốm nấm lá)',
    'Phòng bệnh tổng hợp mùa mưa',
  ];

  final List<String> _ages = [
    '1 - 3 năm (Cây kiến thiết)',
    '4 - 7 năm (Cây kinh doanh)',
    'Trên 8 năm (Vườn cổ thụ)',
  ];

  final List<String> _tanks = [
    'Bình xách tay 16L',
    'Phuy 200L',
  ];

  Map<String, dynamic> _calculateDosage() {
    double dosagePerLiter = 2.0; // grams or ml per Liter
    double litersPerTree = 5.0; // Liters per tree
    String chemicalName = 'Mancozeb 80WP + Metalaxyl 25WP';
    String instructions = 'Phun phủ 2 mặt lá và tưới đẫm vùng quanh gốc bán kính 1.5m.';

    if (_selectedDisease.contains('Phytophthora')) {
      chemicalName = 'Metalaxyl 25WP + Fosetyl-Al';
      dosagePerLiter = 2.5;
      instructions = 'Quét trực tiếp vết xì mủ thân và tưới đẫm vùng rễ 200L/bồn.';
    } else if (_selectedDisease.contains('Anthracnose')) {
      chemicalName = 'Azoxystrobin + Difenoconazole';
      dosagePerLiter = 1.5;
      instructions = 'Phun ướt đều tán lá và chùm quả khi phát hiện vệt đốm nâu.';
    } else if (_selectedDisease.contains('Algal')) {
      chemicalName = 'Copper Hydroxide (Thuốc gốc Đồng)';
      dosagePerLiter = 2.0;
      instructions = 'Phun vào sáng sớm khi chưa có nắng gắt.';
    }

    if (_selectedAge.contains('1 - 3')) {
      litersPerTree = 2.5;
    } else if (_selectedAge.contains('Trên 8')) {
      litersPerTree = 10.0;
    }

    final totalLiters = _treeCount * litersPerTree;
    final tankVolume = _tankType.contains('16L') ? 16.0 : 200.0;
    final totalTanks = (totalLiters / tankVolume).ceil();
    final dosagePerTank = dosagePerLiter * tankVolume;
    final totalChemicalGrams = dosagePerLiter * totalLiters;

    return {
      'chemicalName': chemicalName,
      'dosagePerTank': dosagePerTank.toStringAsFixed(0),
      'totalChemicalGrams': (totalChemicalGrams / 1000).toStringAsFixed(2),
      'totalLiters': totalLiters.toStringAsFixed(0),
      'totalTanks': totalTanks,
      'instructions': instructions,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calculation = _calculateDosage();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calculate_outlined, color: AppColors.primary, size: 22),
              ),
              AppSpacing.h8,
              Expanded(
                child: Text(
                  'Tra cứu Quy trình & Máy tính Liều thuốc AI',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.v16,
          Text('Loại bệnh cần điều trị / phòng ngừa:', style: theme.textTheme.labelMedium),
          AppSpacing.v4,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline.withAlpha(60)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDisease,
                isExpanded: true,
                items: _diseases.map((d) => DropdownMenuItem(value: d, child: Text(d, style: theme.textTheme.bodyMedium))).toList(),
                onChanged: (val) => setState(() => _selectedDisease = val!),
              ),
            ),
          ),
          AppSpacing.v12,
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Độ tuổi cây:', style: theme.textTheme.labelMedium),
                    AppSpacing.v4,
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline.withAlpha(60)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedAge,
                          isExpanded: true,
                          items: _ages.map((a) => DropdownMenuItem(value: a, child: Text(a, style: theme.textTheme.bodySmall))).toList(),
                          onChanged: (val) => setState(() => _selectedAge = val!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dung tích pha:', style: theme.textTheme.labelMedium),
                    AppSpacing.v4,
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline.withAlpha(60)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _tankType,
                          isExpanded: true,
                          items: _tanks.map((t) => DropdownMenuItem(value: t, child: Text(t, style: theme.textTheme.bodySmall))).toList(),
                          onChanged: (val) => setState(() => _tankType = val!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.v12,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Số lượng cây cần phun:', style: theme.textTheme.labelMedium),
              Text(
                '${_treeCount.toInt()} cây',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: _treeCount,
            min: 1,
            max: 200,
            divisions: 199,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _treeCount = val),
          ),
          AppSpacing.v8,
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.primary.withAlpha(40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.medication_liquid_outlined, color: AppColors.primary, size: 20),
                    AppSpacing.h8,
                    Expanded(
                      child: Text(
                        calculation['chemicalName'],
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.v8,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Liều pha 1 ${_tankType.contains("16L") ? "bình" : "phuy"}:', style: theme.textTheme.bodySmall),
                    Text(
                      '${calculation["dosagePerTank"]}g thuốc',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                AppSpacing.v4,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tổng lượng thuốc (${_treeCount.toInt()} cây):', style: theme.textTheme.bodySmall),
                    Text(
                      '${calculation["totalChemicalGrams"]} kg',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                AppSpacing.v4,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tổng dung dịch nước:', style: theme.textTheme.bodySmall),
                    Text(
                      '${calculation["totalLiters"]} Lít (${calculation["totalTanks"]} ${_tankType.contains("16L") ? "bình" : "phuy"})',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                AppSpacing.v8,
                const Divider(height: 1),
                AppSpacing.v8,
                Text(
                  '📌 Hướng dẫn: ${calculation["instructions"]}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withAlpha(180),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
