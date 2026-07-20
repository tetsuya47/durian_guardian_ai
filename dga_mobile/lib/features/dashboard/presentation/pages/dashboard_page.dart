import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/skeleton_loading.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/ai_farm_status_card.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/quick_stats_grid.dart';
import '../widgets/recent_inspections_list.dart';
import '../widgets/dashboard_alerts_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      appBar: DashboardAppBar(
        userName: dashboardAsync.when(
          data: (data) => data.userName,
          loading: () => '',
          error: (_, __) => '',
        ),
        userAvatarUrl: '',
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardDataProvider);
            await ref.read(dashboardDataProvider.future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: dashboardAsync.when(
              data: (data) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data.alerts.isNotEmpty) ...[
                    DashboardAlertsCard(alerts: data.alerts),
                    AppSpacing.v20,
                  ],
                  AIFarmStatusCard(status: data.farmStatus),
                  AppSpacing.v20,
                  const SectionHeader(title: AppStrings.quickStats),
                  AppSpacing.v12,
                  QuickStatsGrid(statistics: data.statistics),
                  AppSpacing.v20,
                  const SectionHeader(title: AppStrings.quickActions),
                  AppSpacing.v12,
                  const QuickActionsGrid(),
                  AppSpacing.v20,
                  const SectionHeader(title: AppStrings.recentInspections),
                  AppSpacing.v12,
                  RecentInspectionsList(inspections: data.recentInspections),
                ],
              ),
              loading: () => Column(
                children: [
                  SkeletonLoading.card(height: 140),
                  AppSpacing.v20,
                  SkeletonLoading.card(height: 140),
                  AppSpacing.v20,
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: SkeletonLoading.card(height: 100)),
                          AppSpacing.h12,
                          Expanded(child: SkeletonLoading.card(height: 100)),
                        ],
                      ),
                      AppSpacing.v12,
                      Row(
                        children: [
                          Expanded(child: SkeletonLoading.card(height: 100)),
                          AppSpacing.h12,
                          Expanded(child: SkeletonLoading.card(height: 100)),
                        ],
                      ),
                    ],
                  ),
                  AppSpacing.v20,
                  Column(
                    children: List.generate(3, (index) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: SkeletonLoading.card(height: 80),
                    )),
                  ),
                ],
              ),
              error: (err, stack) => Center(
                child: ErrorState(
                  title: AppStrings.error,
                  description: AppStrings.cannotLoadDashboard,
                  onRetry: () => ref.invalidate(dashboardDataProvider),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
