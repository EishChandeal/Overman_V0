import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/habit_stats_calculator.dart';
import '../services/user_rank_service.dart';
import 'app_session_providers.dart';
import 'habit_providers.dart';
import 'repository_providers.dart';

export '../services/user_rank_service.dart';

/// Computes completion stats for all active habits since their creation.
final allHabitCompletionStatsProvider =
    FutureProvider<List<HabitCompletionStat>>((ref) async {
  final habits = await ref.watch(habitListProvider.future);
  final activeHabits = habits.where((h) => !h.isArchived).toList();
  if (activeHabits.isEmpty) return [];

  final entryRepo = await ref.watch(habitEntryRepositoryProvider.future);
  final scheduleRepo = await ref.watch(habitScheduleRepositoryProvider.future);
  final today = DateTime.now();

  final stats = <HabitCompletionStat>[];
  for (final habit in activeHabits) {
    final startUtc = DateTime.utc(
      habit.createdAt.year,
      habit.createdAt.month,
      habit.createdAt.day,
    );
    final todayUtc = DateTime.utc(
      today.year,
      today.month,
      today.day,
    );

    final entries = await entryRepo.getEntriesForHabit(
      habit.id,
      startUtc,
      todayUtc,
    );
    final schedule = await scheduleRepo.getActiveScheduleForHabit(habit.id);
    final scheduledWeekdays = schedule?.scheduledWeekdays
            ?.map((w) => w.name)
            .toList() ??
        [];

    final activeDays = HabitStatsCalculator.computeActiveDays(
      habit,
      scheduledWeekdays,
      today,
    );
    final completedDays = HabitStatsCalculator.computeCompletedDays(
      entries,
      habit,
    );

    stats.add(HabitCompletionStat(
      habitId: habit.id,
      completedDays: completedDays,
      activeDays: activeDays,
    ));
  }
  return stats;
});

/// Computes the current UserRank based on total days opened and habit stats.
final userRankProvider = FutureProvider<UserRank>((ref) async {
  final totalDays = await ref.watch(totalDaysOpenedProvider.future);
  final habitStats = await ref.watch(allHabitCompletionStatsProvider.future);
  return UserRankService.computeRank(
    totalDaysOpened: totalDays,
    habitStats: habitStats,
  );
});
