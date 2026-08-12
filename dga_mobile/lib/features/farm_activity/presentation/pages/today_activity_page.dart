import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/farm_activity_providers.dart';
import '../../data/models/activity_category.dart';
import '../../data/models/farm_activity_log.dart';
import '../widgets/category_selection_sheet.dart';
import '../widgets/fertilizer_form_sheet.dart';
import '../widgets/pesticide_form_sheet.dart';
import '../widgets/phi_warning_banner.dart';
import '../widgets/activity_history_timeline.dart';

class TodayActivityPage extends ConsumerStatefulWidget {
  const TodayActivityPage({super.key});

  @override
  ConsumerState<TodayActivityPage> createState() => _TodayActivityPageState();
}

class _TodayActivityPageState extends ConsumerState<TodayActivityPage> {
  void _openFertilizerForm() {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FertilizerFormSheet(
          onSubmit: (log) async {
            final created = await ref.read(farmActivityNotifierProvider.notifier).addActivity(log);
            if (created != null && mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('✓ Đã thêm công việc: ${created.activityName} (${created.productName}) vào danh sách hôm nay'),
                  backgroundColor: Colors.green.shade700,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        );
      },
    );
  }

  void _openPesticideForm() {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PesticideFormSheet(
          onSubmit: (log) async {
            final created = await ref.read(farmActivityNotifierProvider.notifier).addActivity(log);
            if (created != null && mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('✓ Đã thêm công việc: ${created.activityName} (${created.productName}) vào danh sách hôm nay'),
                  backgroundColor: Colors.red.shade700,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        );
      },
    );
  }

  void _openCategorySelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CategorySelectionSheet(
          onCategorySelected: (cat) {
            _handleCategorySelection(cat);
          },
        );
      },
    );
  }

  void _handleCategorySelection(ActivityCategory cat) {
    if (cat.id == 'fertilizer' ||
        cat.id == 'organic_fertilizer' ||
        cat.id == 'lime_fertilizer') {
      _openFertilizerForm();
    } else if (cat.id == 'pesticide' || cat.id == 'bio_pesticide') {
      _openPesticideForm();
    } else {
      final now = DateTime.now();
      final simpleLog = FarmActivityLog(
        id: 'ACT_${now.millisecondsSinceEpoch}',
        date: now,
        farmId: 'F001',
        zoneId: 'Zone A',
        activityType: cat.group.name.toUpperCase(),
        activityName: cat.name,
        performedBy: 'Nguyễn Văn A',
        isCompleted: false, // New task is pending for today
      );

      ref.read(farmActivityNotifierProvider.notifier).addActivity(simpleLog);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Đã thêm công việc: ${cat.name} vào Bảng công việc hôm nay'),
          backgroundColor: Colors.teal.shade700,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activitiesState = ref.watch(farmActivityNotifierProvider);
    final stats = ref.watch(todayCompletedStatsProvider);
    final activePhi = ref.watch(activePhiRestrictionProvider);

    final now = DateTime.now();
    final weekdayNames = ['Chủ Nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'];
    final vietnameseDate = '${weekdayNames[now.weekday % 7]}, ${DateFormat("dd/MM/yyyy").format(now)}';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Nhật Ký Canh Tác Trang Trại',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(farmActivityNotifierProvider.notifier).loadActivities();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date & Progress Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          vietnameseDate,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          'Chuẩn VietGAP',
                          style: TextStyle(
                            color: Colors.green.shade900,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '☀ TIẾN ĐỘ CANH TÁC HÔM NAY',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Progress Bar & Counter
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: stats.total > 0 ? stats.completed / stats.total : 0.0,
                            minHeight: 10,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${stats.completed}/${stats.total} hoàn thành',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Active PHI Banner (If any)
            if (activePhi != null) PhiWarningBanner(phiLog: activePhi),

            const SizedBox(height: 16),

            // 📋 SECTION 1: CÔNG VIỆC TRONG NGÀY HÔM NAY (PENDING CHECKLIST BOARD)
            activitiesState.when(
              data: (activities) {
                final pendingTasks = activities.where((a) => !a.isCompleted).toList();
                final completedTasks = activities.where((a) => a.isCompleted).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.playlist_add_check, color: Colors.orange.shade800, size: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'CÔNG VIỆC TRONG NGÀY',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade900,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: pendingTasks.isNotEmpty ? Colors.orange.shade100 : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${pendingTasks.length} việc cần làm',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: pendingTasks.isNotEmpty ? Colors.orange.shade900 : Colors.green.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Pending Tasks List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: pendingTasks.isEmpty
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '🎉 Đã hoàn thành tất cả công việc!',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade900,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Bấm nút "+ Thêm công việc" bên dưới nếu có việc mới phát sinh.',
                                          style: TextStyle(color: Colors.green.shade800, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: pendingTasks.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final task = pendingTasks[index];

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.orange.shade200),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // Unchecked Checkbox Icon
                                      IconButton(
                                        onPressed: () {
                                          ref.read(farmActivityNotifierProvider.notifier).toggleCompletion(task.id);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('✓ Đã hoàn thành "${task.activityName}" và chuyển vào Nhật ký lịch sử!'),
                                              backgroundColor: Colors.green.shade700,
                                              duration: const Duration(seconds: 2),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                        icon: Icon(
                                          Icons.check_box_outline_blank,
                                          color: Colors.grey.shade600,
                                          size: 26,
                                        ),
                                      ),
                                      const SizedBox(width: 4),

                                      // Task details column
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              task.activityName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.5,
                                                color: Color(0xFF111827),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: [
                                                if (task.productName != null)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade100,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      'Vật tư: ${task.productName}',
                                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                                                    ),
                                                  ),
                                                if (task.quantity != null)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade100,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      'Lượng: ${task.quantity}',
                                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                                                    ),
                                                  ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    'Khu vực: ${task.zoneId}',
                                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Complete Button
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          ref.read(farmActivityNotifierProvider.notifier).toggleCompletion(task.id);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('✓ Đã hoàn thành "${task.activityName}" và chuyển vào Nhật ký lịch sử!'),
                                              backgroundColor: Colors.green.shade700,
                                              duration: const Duration(seconds: 2),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.check, size: 14),
                                        label: const Text('HOÀN THÀNH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green.shade700,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          elevation: 0,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 24),

                    // 📖 SECTION 2: LỊCH SỬ NHẬT KÝ CANH TÁC (COMPLETED TIMELINE)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.history_edu, color: Colors.green.shade800, size: 20),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'LỊCH SỬ NHẬT KÝ CANH TÁC',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade900,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${completedTasks.length} nhật ký đã lưu',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Completed Timeline List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ActivityHistoryTimeline(activities: completedTasks),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Center(
                child: Text('Đã có lỗi xảy ra: $err'),
              ),
            ),

            const SizedBox(height: 80), // Padding bottom for FloatingActionButton
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCategorySelectionSheet,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text(
          'Thêm công việc',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}
