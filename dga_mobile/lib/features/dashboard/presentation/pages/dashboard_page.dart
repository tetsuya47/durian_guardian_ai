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
                  AppSpacing.v16,

                  // Quản Lý Vườn & IoT Banner Card
                  InkWell(
                    onTap: () => context.push('/farm-management-iot'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B4D3E), Color(0xFF2E7D32)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(12),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.sensors, color: Colors.amber, size: 26),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🌳 QUẢN LÝ VƯỜN & IOT',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Xem chỉ số cảm biến 30s + Khuyến nghị Model 3/4 AI',
                                  style: TextStyle(fontSize: 11, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),

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
