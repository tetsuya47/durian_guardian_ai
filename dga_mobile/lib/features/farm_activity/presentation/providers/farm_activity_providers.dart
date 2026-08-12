import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/farm_activity_log.dart';
import '../../data/repositories/farm_activity_repository.dart';

final farmActivityRepositoryProvider = Provider<FarmActivityRepository>((ref) {
  return FarmActivityRepository();
});

class FarmActivityNotifier extends StateNotifier<AsyncValue<List<FarmActivityLog>>> {
  final FarmActivityRepository _repository;

  FarmActivityNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadActivities();
  }

  Future<void> loadActivities() async {
    state = const AsyncValue.loading();
    try {
      final activities = await _repository.getActivities();
      state = AsyncValue.data(activities);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<FarmActivityLog?> addActivity(FarmActivityLog newLog) async {
    try {
      final created = await _repository.addActivity(newLog);
      final currentList = state.value ?? [];
      state = AsyncValue.data([created, ...currentList]);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> toggleCompletion(String activityId) async {
    final currentList = state.value ?? [];
    final updatedList = currentList.map((act) {
      if (act.id == activityId) {
        return act.copyWith(isCompleted: !act.isCompleted);
      }
      return act;
    }).toList();

    state = AsyncValue.data(updatedList);
    await _repository.toggleActivityCompletion(activityId);
  }
}

final farmActivityNotifierProvider =
    StateNotifierProvider<FarmActivityNotifier, AsyncValue<List<FarmActivityLog>>>((ref) {
  final repository = ref.watch(farmActivityRepositoryProvider);
  return FarmActivityNotifier(repository);
});

// Selected Zone Filter
final selectedZoneProvider = StateProvider<String>((ref) => 'All');

// Active PHI Banner Provider
final activePhiRestrictionProvider = Provider<FarmActivityLog?>((ref) {
  final activitiesState = ref.watch(farmActivityNotifierProvider);
  return activitiesState.when(
    data: (activities) {
      final today = DateTime.now();
      for (final act in activities) {
        if (act.safeHarvestDate != null && act.safeHarvestDate!.isAfter(today)) {
          return act;
        }
      }
      return null;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// Completed vs Total stats provider
final todayCompletedStatsProvider = Provider<({int completed, int total})>((ref) {
  final activitiesState = ref.watch(farmActivityNotifierProvider);
  return activitiesState.when(
    data: (activities) {
      final total = activities.length;
      final completed = activities.where((a) => a.isCompleted).length;
      return (completed: completed, total: total);
    },
    loading: () => (completed: 0, total: 0),
    error: (_, __) => (completed: 0, total: 0),
  );
});
