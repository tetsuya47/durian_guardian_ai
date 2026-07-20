import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/history_providers.dart';

class HistorySearchBar extends ConsumerWidget {
  const HistorySearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final query = ref.watch(historyQueryProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        onChanged: (val) {
          ref.read(historyQueryProvider.notifier).state = val;
        },
        decoration: InputDecoration(
          hintText: AppStrings.searchTreeHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    ref.read(historyQueryProvider.notifier).state = '';
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        ),
      ),
    );
  }
}
