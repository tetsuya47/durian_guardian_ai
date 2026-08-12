import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeleton_loading.dart';
import '../../domain/entities/history_entities.dart';
import '../providers/history_providers.dart';
import '../widgets/empty_history_widget.dart';
import '../widgets/history_card.dart';
import '../widgets/history_detail_sheet.dart';
import '../widgets/history_filter_bar.dart';
import '../widgets/history_search_bar.dart';
import '../widgets/history_statistics_card.dart';
import '../widgets/quick_access_row.dart';
import '../widgets/summary_card.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  void _showDetailBottomSheet(BuildContext context, HistoryLogEntity log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HistoryDetailSheet(log: log),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawLogsAsync = ref.watch(historyRawLogsProvider);
    final filteredLogs = ref.watch(filteredHistoryLogsProvider);

    final healthyCount = filteredLogs.where((l) => l.diseaseName.contains('Không phát hiện') || l.diseaseName.toLowerCase().contains('khỏe mạnh')).length;
    final diseasedCount = filteredLogs.length > healthyCount ? (filteredLogs.length - healthyCount) : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF1E8E4A),
          onRefresh: () async {
            ref.invalidate(historyRawLogsProvider);
            await ref.read(historyRawLogsProvider.future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Section (Title + Notification Icon with Badge)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nhật ký chăm sóc',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Quản lý và theo dõi sức khỏe vườn sầu riêng',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: Color(0xFF111827),
                            size: 24,
                          ),
                        ),
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: const Text(
                              '3',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Summary Card
                SummaryCard(
                  todayScanned: filteredLogs.length,
                  healthyCount: healthyCount,
                  diseasedCount: diseasedCount,
                ),
                const SizedBox(height: 16),

                // 3. Search Bar (ONLY ONE search bar)
                const HistorySearchBar(),
                const SizedBox(height: 14),

                // 4. Filter Chips
                const HistoryFilterBar(),
                const SizedBox(height: 22),

                // 5. Quick Access (Khám phá nhanh)
                const QuickAccessRow(),
                const SizedBox(height: 22),

                // 6. History Statistics Card
                HistoryStatisticsCard(logs: filteredLogs),
                const SizedBox(height: 22),

                // 7. Recent History Section (Lịch sử chẩn đoán gần đây)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Lịch sử chẩn đoán gần đây',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ref.read(historyFilterProvider.notifier).state = 'Tất cả';
                        ref.read(historyQueryProvider.notifier).state = '';
                        ref.read(historyTimeFilterProvider.notifier).state = 'Tất cả';
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã hiển thị toàn bộ lịch sử chẩn đoán'),
                            duration: Duration(seconds: 2),
                            backgroundColor: Color(0xFF1E8E4A),
                          ),
                        );
                      },
                      child: const Row(
                        children: [
                          Text(
                            'Xem tất cả',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E8E4A),
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: Color(0xFF1E8E4A),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Dynamic History Cards List
                rawLogsAsync.when(
                  data: (rawLogs) {
                    if (rawLogs.isEmpty || filteredLogs.isEmpty) {
                      return const EmptyHistoryWidget();
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        final log = filteredLogs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: HistoryCard(
                            log: log,
                            onTap: () => _showDetailBottomSheet(context, log),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 3,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SkeletonLoading.card(height: 95),
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: ErrorState(
                      title: AppStrings.error,
                      description: AppStrings.cannotLoadHistory,
                      onRetry: () => ref.invalidate(historyRawLogsProvider),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
