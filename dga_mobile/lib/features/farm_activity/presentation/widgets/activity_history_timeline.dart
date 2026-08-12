import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/farm_activity_log.dart';

class ActivityHistoryTimeline extends StatelessWidget {
  final List<FarmActivityLog> activities;

  const ActivityHistoryTimeline({
    super.key,
    required this.activities,
  });

  IconData _getIconForType(String type) {
    switch (type) {
      case 'WATERING':
        return Icons.water_drop;
      case 'FERTILIZER':
        return Icons.grass;
      case 'PESTICIDE':
        return Icons.sanitizer;
      case 'WEEDING':
        return Icons.cleaning_services;
      case 'PRUNING':
        return Icons.park;
      case 'HARVESTING':
        return Icons.agriculture;
      default:
        return Icons.task_alt;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'WATERING':
        return Colors.blue;
      case 'FERTILIZER':
        return Colors.green;
      case 'PESTICIDE':
        return Colors.red;
      case 'WEEDING':
        return Colors.amber.shade800;
      case 'PRUNING':
        return Colors.orange;
      case 'HARVESTING':
        return Colors.purple;
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'Chưa có nhật ký hoạt động nào',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final log = activities[index];
        final color = _getColorForType(log.activityType);
        final isLast = index == activities.length - 1;
        final warnings = log.computedVietgapWarnings;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline Node & Line
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 1.5),
                    ),
                    child: Icon(_getIconForType(log.activityType), size: 18, color: color),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Activity Card Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: warnings.isNotEmpty ? Colors.orange.shade300 : Colors.grey.shade200,
                      width: warnings.isNotEmpty ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Activity Name & Date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              log.activityName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            log.formattedDate,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),

                      // Product & Active Ingredient
                      if (log.productName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Sản phẩm: ${log.productName}${log.activeIngredient != null ? " (${log.activeIngredient})" : ""}',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],

                      // Manufacturer & Batch Number (VietGAP Traceability)
                      if (log.manufacturer != null || log.batchNumber != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, size: 12, color: Colors.blue.shade800),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'NSX: ${log.manufacturer ?? "Syngenta"} • Lô: ${log.batchNumber ?? "LOT-2026-88A"}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Quantity & Area Chips
                      if (log.quantity != null || log.areaCoverage != null) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (log.quantity != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Lượng: ${log.quantity}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            if (log.areaCoverage != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Khu vực: ${log.zoneId} (${log.areaCoverage})',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                          ],
                        ),
                      ],

                      // Package Image / Invoice (If attached)
                      if (log.packageImageUrl != null && log.packageImageUrl!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(log.packageImageUrl!),
                            height: 70,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],

                      // Notes
                      if (log.notes != null && log.notes!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Ghi chú: ${log.notes}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                        ),
                      ],

                      // Automated VietGAP Warning Alerts Box
                      if (warnings.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: warnings
                                .map(
                                  (w) => Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.warning_amber_rounded, size: 14, color: Colors.amber.shade900),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          w,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.amber.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),
                      // Bottom Row: PerformedBy & Safe Harvest Date
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                log.performedBy,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                          if (log.safeHarvestDate != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                'PHI: Cách ly tới ${log.formattedSafeHarvestDate}',
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
