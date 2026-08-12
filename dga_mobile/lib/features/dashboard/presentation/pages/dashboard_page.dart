import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeleton_loading.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/ai_farm_status_card.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/durian_market_price_card.dart';
import '../widgets/pesticide_lookup_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/recent_inspections_list.dart';
import '../../../farm_activity/presentation/widgets/today_activity_dashboard_banner.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
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
          color: const Color(0xFF2E7D32),
          onRefresh: () async {
            ref.invalidate(dashboardDataProvider);
            await ref.read(dashboardDataProvider.future);
          },
          child: dashboardAsync.when(
            data: (data) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Hero AI Card & Tình Trạng Vườn
                  AIFarmStatusCard(status: data.farmStatus),
                  const SizedBox(height: 16),

                  // 2. Banner Nhật Ký Canh Tác Hôm Nay (VietGAP Log)
                  const TodayActivityDashboardBanner(),
                  const SizedBox(height: 20),

                  // 3. Hành Động Hôm Nay (2x2 Grid)
                  const QuickActionsGrid(),
                  const SizedBox(height: 20),

                  // 3. Giá Sầu Riêng Hôm Nay (Horizontal Carousel)
                  const DurianMarketPriceCard(),
                  const SizedBox(height: 20),

                  // 4. Thuốc Bảo Vệ Thực Vật Đề Xuất (3 Product Cards)
                  const PesticideLookupCard(),
                  const SizedBox(height: 20),

                  // 5. Hoạt Động Gần Đây (Vertical Timeline)
                  RecentInspectionsList(inspections: data.recentInspections),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            loading: () => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SkeletonLoading.card(height: 220),
                  const SizedBox(height: 20),
                  SkeletonLoading.card(height: 140),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: SkeletonLoading.card(height: 120)),
                      const SizedBox(width: 16),
                      Expanded(child: SkeletonLoading.card(height: 120)),
                    ],
                  ),
                ],
              ),
            ),
            error: (err, stack) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
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
