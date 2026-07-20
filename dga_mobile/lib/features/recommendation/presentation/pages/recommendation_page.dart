import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/ui_helpers.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../domain/entities/recommendation_entities.dart';
import '../providers/recommendation_providers.dart';
import '../widgets/ai_notes_card.dart';
import '../widgets/care_recommendations_list.dart';
import '../widgets/care_timeline.dart';
import '../widgets/health_summary_card.dart';
import '../widgets/recommendation_action_buttons.dart';
import '../widgets/recommendation_loading_widget.dart';
import '../widgets/suggested_materials_table.dart';
import '../widgets/weather_conditions_card.dart';

class RecommendationPage extends ConsumerStatefulWidget {
  const RecommendationPage({super.key});

  @override
  ConsumerState<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends ConsumerState<RecommendationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentState = ref.read(recommendationStateProvider);
      if (currentState == 'idle') {
        _generateRecommendations();
      }
    });
  }

  void _generateRecommendations() async {
    ref.read(recommendationStateProvider.notifier).state = 'loading';

    try {
      final repo = ref.read(recommendationRepositoryProvider);
      final result = await repo.getRecommendations();
      if (!mounted) return;
      result.when(
        success: (data) {
          ref.read(recommendationResultProvider.notifier).state = data;
          ref.read(recommendationStateProvider.notifier).state = 'success';
        },
        failure: (msg, err) {
          ref.read(recommendationStateProvider.notifier).state = 'error';
        },
        loading: () {},
        empty: () {},
      );
    } catch (_) {
      ref.read(recommendationStateProvider.notifier).state = 'error';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recommendationStateProvider);
    final result = ref.watch(recommendationResultProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.recommendation),
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
        actions: [
          if (state == 'success')
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Làm mới',
              onPressed: () => _generateRecommendations(),
            ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildBodyByState(context, state, result),
        ),
      ),
    );
  }

  Widget _buildBodyByState(
    BuildContext context,
    String state,
    RecommendationResultEntity? result,
  ) {
    final theme = Theme.of(context);

    if (state == 'loading') {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: RecommendationLoadingWidget(),
      );
    }

    if (state == 'error') {
      return Center(
        child: ErrorState(
          title: AppStrings.error,
          description: AppStrings.cannotGenerateRecommendation,
          onRetry: () => _generateRecommendations(),
        ),
      );
    }

    if (state == 'success' && result != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HealthSummaryCard(riskLevel: result.riskLevel),
            AppSpacing.v16,
            WeatherConditionsCard(weather: result.weather),
            AppSpacing.v16,
            CareRecommendationsList(recommendations: result.careRecommendations),
            AppSpacing.v16,
            CareTimeline(schedules: result.careSchedules),
            AppSpacing.v16,
            SuggestedMaterialsTable(materials: result.materialDetails),
            AppSpacing.v16,
            AINotesCard(notes: result.aiNotes),
            AppSpacing.v24,
            RecommendationActionButtons(
              onSave: () {
                AppSnackbars.showSuccess(context, 'Đã lưu khuyến nghị chăm sóc thành công!');
              },
              onShare: () {
                AppSnackbars.showInfo(context, 'Chức năng chia sẻ khuyến nghị.');
              },
              onPrint: () {
                AppSnackbars.showInfo(context, 'Chức năng in báo cáo khuyến nghị.');
              },
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assistant_outlined,
              size: 80,
              color: theme.colorScheme.primary.withAlpha(50),
            ),
            AppSpacing.v20,
            Text(
              AppStrings.noRecommendationData,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.v32,
            ElevatedButton.icon(
              onPressed: () => _generateRecommendations(),
              icon: const Icon(Icons.rocket_launch_outlined),
              label: const Text('Tạo khuyến nghị ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
