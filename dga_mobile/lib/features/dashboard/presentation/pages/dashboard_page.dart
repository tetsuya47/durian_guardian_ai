import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/skeleton_loading.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/agricultural_features_grid.dart';
import '../widgets/ai_farm_status_card.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/durian_market_price_card.dart';
import '../widgets/pesticide_lookup_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/recent_inspections_list.dart';

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
          child: dashboardAsync.when(
            data: (data) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AIFarmStatusCard(status: data.farmStatus),
                  AppSpacing.v20,
                  const AgriculturalFeaturesGrid(),
                  AppSpacing.v20,
                  const DurianMarketPriceCard(),
                  AppSpacing.v20,
                  const PesticideLookupCard(),
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
            ),
            loading: () => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
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
            ),
            error: (err, stack) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(AppSpacing.xl),
                height: MediaQuery.of(context).size.height * 0.7,
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
