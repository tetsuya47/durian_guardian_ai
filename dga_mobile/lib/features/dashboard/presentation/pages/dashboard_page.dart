import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/dashboard_providers.dart';
import '../widgets/vietplant_home_header.dart';
import '../widgets/vietplant_quick_menu_grid.dart';
import '../widgets/vietplant_smart_garden_card.dart';
import '../widgets/vietplant_market_prices.dart';
import '../widgets/vietplant_weather_card.dart';
import '../widgets/vietplant_news_section.dart';
import '../widgets/vietplant_pesticide_lookup.dart';
import '../widgets/vietplant_ai_scanner_card.dart';
import '../widgets/vietplant_ai_floating_banner.dart';
import '../../../recommendation/presentation/widgets/durian_variety_selector_dialog.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final userIoTStatusAsync = ref.watch(userIoTStatusProvider);
    final telemetryAsync = ref.watch(latestTelemetryProvider);
    final marketPricesAsync = ref.watch(marketPricesProvider);
    final weatherAsync = ref.watch(weatherCurrentProvider);
    final newsArticlesAsync = ref.watch(newsArticlesProvider);
    final videosAsync = ref.watch(videosListProvider);
    final scanHistoryAsync = ref.watch(scanHistoryProvider);

    final userName = dashboardAsync.when(
      data: (data) => data.userName,
      loading: () => '',
      error: (_, __) => '',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      body: RefreshIndicator(
        color: const Color(0xFF4CAF50),
        onRefresh: () async {
          ref.invalidate(dashboardDataProvider);
          ref.invalidate(userIoTStatusProvider);
          ref.invalidate(latestTelemetryProvider);
          ref.invalidate(marketPricesProvider);
          ref.invalidate(weatherCurrentProvider);
          ref.invalidate(newsArticlesProvider);
          ref.invalidate(videosListProvider);
          ref.invalidate(scanHistoryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Bar (Green Leaf Gradient, Logo, Notification Bell, Search Bar)
              VietplantHomeHeader(
                userName: userName,
                onNotificationTap: () => context.push('/notifications'),
                onMenuTap: () => Scaffold.of(context).openDrawer(),
              ),
              const SizedBox(height: 8),

              // 2. Quick Actions 6-Icon Grid
              VietplantQuickMenuGrid(
                onFarmingTechniquesTap: () => _showVarietySelector(context, '/farming-techniques'),
                onPestsDiseasesTap: () => _showVarietySelector(context, '/pests-and-diseases'),
                onWeatherTap: () => context.push('/weather'),
                onTasksTap: () => context.push('/subscription-packages'),
                onCommunityTap: () => context.push('/durian-news'),
                onBiocontrolTap: () => _showVarietySelector(context, '/biocontrol-measures'),
              ),
              const SizedBox(height: 14),

              // 3. Smart Orchard Management (IoT & AI Sensor Card)
              userIoTStatusAsync.when(
                data: (hasIoT) => telemetryAsync.when(
                  data: (telemetry) => VietplantSmartGardenCard(
                    hasIoTDevices: hasIoT,
                    telemetryData: telemetry,
                    onTap: () => context.push('/smart-garden-management'),
                    onBuyIoT: () => context.push('/iot-shop'),
                    onUpgradePackage: () => context.push('/subscription-packages'),
                  ),
                  loading: () => VietplantSmartGardenCard(
                    hasIoTDevices: hasIoT,
                    onTap: () => context.push('/smart-garden-management'),
                    onBuyIoT: () => context.push('/iot-shop'),
                    onUpgradePackage: () => context.push('/subscription-packages'),
                  ),
                  error: (_, __) => VietplantSmartGardenCard(
                    hasIoTDevices: hasIoT,
                    onTap: () => context.push('/smart-garden-management'),
                    onBuyIoT: () => context.push('/iot-shop'),
                    onUpgradePackage: () => context.push('/subscription-packages'),
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50))),
                ),
                error: (_, __) => VietplantSmartGardenCard(
                  hasIoTDevices: false,
                  onTap: () => context.push('/smart-garden-management'),
                  onBuyIoT: () => context.push('/iot-shop'),
                  onUpgradePackage: () => context.push('/subscription-packages'),
                ),
              ),
              const SizedBox(height: 18),

              // 4. Market Prices Section ("Giá cả thị trường")
              marketPricesAsync.when(
                data: (prices) => VietplantMarketPrices(
                  prices: prices,
                  onViewAll: () {},
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50))),
                ),
                error: (_, __) => VietplantMarketPrices(prices: const [], onViewAll: () {}),
              ),
              const SizedBox(height: 20),

              // 4. Floating AI Assistant Banner ("Xem gì hôm nay?")
              userIoTStatusAsync.when(
                data: (hasIoT) => VietplantAIFloatingBanner(
                  hasIoTDevices: hasIoT,
                  onAiChatTap: () => context.push('/daily-ai-notifications', extra: {'hasIoTDevices': hasIoT}),
                ),
                loading: () => VietplantAIFloatingBanner(
                  hasIoTDevices: false,
                  onAiChatTap: () => context.push('/daily-ai-notifications', extra: {'hasIoTDevices': false}),
                ),
                error: (_, __) => VietplantAIFloatingBanner(
                  hasIoTDevices: false,
                  onAiChatTap: () => context.push('/daily-ai-notifications', extra: {'hasIoTDevices': false}),
                ),
              ),
              const SizedBox(height: 24),

              // 5. Weather Card Section ("Tin thời tiết")
              weatherAsync.when(
                data: (weather) => VietplantWeatherCard(
                  weatherData: weather,
                  onViewDetails: () => context.push('/weather'),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50))),
                ),
                error: (_, __) => const VietplantWeatherCard(),
              ),
              const SizedBox(height: 24),

              // 6. News Articles Section ("Điểm tin")
              newsArticlesAsync.when(
                data: (articles) => VietplantNewsSection(
                  articles: articles,
                  onViewAll: () => context.push('/durian-news'),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50))),
                ),
                error: (_, __) => VietplantNewsSection(articles: const [], onViewAll: () {}),
              ),
              const SizedBox(height: 24),

              // 7. Pesticide Lookup ("Tra cứu thuốc")
              const VietplantPesticideLookup(),
              const SizedBox(height: 24),

              // 9. AI Plant Scanner Card ("Chụp ảnh để nhận diện cây trồng") & Lịch sử nhận diện
              scanHistoryAsync.when(
                data: (history) => VietplantAIScannerCard(
                  onCameraTap: () => context.push('/detection'),
                  scanHistory: history,
                ),
                loading: () => VietplantAIScannerCard(
                  onCameraTap: () => context.push('/detection'),
                  scanHistory: const [],
                ),
                error: (_, __) => VietplantAIScannerCard(
                  onCameraTap: () => context.push('/detection'),
                  scanHistory: const [],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showVarietySelector(BuildContext context, String targetRoute) {
    showDialog(
      context: context,
      builder: (ctx) => DurianVarietySelectorDialog(
        onVarietySelected: (varietyId) {
          context.push(targetRoute, extra: {'varietyId': varietyId});
        },
      ),
    );
  }
}
