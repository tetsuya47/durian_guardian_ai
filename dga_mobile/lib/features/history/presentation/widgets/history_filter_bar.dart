import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/history_providers.dart';

class HistoryFilterBar extends ConsumerWidget {
  const HistoryFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeFilter = ref.watch(historyFilterProvider);
    final activeTimeFilter = ref.watch(historyTimeFilterProvider);
    final activeSort = ref.watch(historySortProvider);

    final statusFilters = [
      AppStrings.filterAll,
      AppStrings.filterHealthy,
      AppStrings.filterDiseased,
      AppStrings.filterHighRisk
    ];

    final timeFilters = [
      AppStrings.filterAll,
      AppStrings.filterToday,
      AppStrings.filter7Days,
      AppStrings.filter30Days
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: statusFilters.map((filter) {
              final isSelected = activeFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s),
                child: FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (val) {
                    ref.read(historyFilterProvider.notifier).state = filter;
                  },
                  selectedColor: theme.colorScheme.primary.withAlpha(40),
                  checkmarkColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        AppSpacing.v8,
        Row(
          children: [
            // 2. Time Filter Popup Button
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.onSurface.withAlpha(30)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: activeTimeFilter,
                    icon: const Icon(Icons.arrow_drop_down),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(historyTimeFilterProvider.notifier).state = val;
                      }
                    },
                    items: timeFilters.map((time) {
                      return DropdownMenuItem<String>(
                        value: time,
                        child: Text('Thời gian: $time', style: theme.textTheme.bodyMedium),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            AppSpacing.h12,
            // 3. Sort Popup Button
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.onSurface.withAlpha(30)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: activeSort,
                    icon: const Icon(Icons.sort),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(historySortProvider.notifier).state = val;
                      }
                    },
                    items: [
                      AppStrings.sortLatest,
                      AppStrings.sortOldest,
                      AppStrings.sortConfidence,
                      AppStrings.sortTreeName,
                    ].map((sort) {
                      return DropdownMenuItem<String>(
                        value: sort,
                        child: Text('Sắp xếp: $sort', style: theme.textTheme.bodyMedium),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
