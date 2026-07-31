import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.historyTitle),
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'So sánh Trước & Sau',
            icon: const Icon(Icons.compare_arrows_outlined),
            onPressed: () => context.push('/history/compare'),
          ),
          IconButton(
            tooltip: 'Thi đua & Thống kê',
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () => context.push('/history/leaderboard'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(historyRawLogsProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(historyRawLogsProvider);
            await ref.read(historyRawLogsProvider.future);
          },
          child: Column(
            children: [
              // Search & Filter header (Cố định ở trên)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Column(
                  children: [
                    HistorySearchBar(),
                    AppSpacing.v8,
                    HistoryFilterBar(),
                  ],
                ),
              ),
              // Dynamic Body
              Expanded(
                child: rawLogsAsync.when(
                  data: (rawLogs) {
                    if (rawLogs.isEmpty) {
                      return const EmptyHistoryWidget();
                    }
                    if (filteredLogs.isEmpty) {
                      return const EmptyHistoryWidget();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      itemCount: filteredLogs.length + 1, // Bản ghi + Stats Card
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: HistoryStatisticsCard(logs: filteredLogs),
                          );
                        }

                        final log = filteredLogs[index - 1];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: HistoryCard(
                            log: log,
                            onTap: () => _showDetailBottomSheet(context, log),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: 5,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: SkeletonLoading.card(height: 100),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
