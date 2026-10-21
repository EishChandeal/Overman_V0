import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/enums/enums.dart';
import '../../domain/services/statistics_service.dart';
import '../../domain/services/streak_engine.dart';
import 'repository_providers.dart';

part 'streak_providers.g.dart';

@riverpod
Future<StreakResult> habitStreak(HabitStreakRef ref, String habitId) async {
  final entryRepo = await ref.watch(habitEntryRepositoryProvider.future);
  final scheduleRepo = await ref.watch(habitScheduleRepositoryProvider.future);

  final nowLocal = DateTime.now();
  final todayUtc = DateTime.utc(nowLocal.year, nowLocal.month, nowLocal.day);
  final from = todayUtc.subtract(const Duration(days: 365));

  final entries = await entryRepo.getEntriesForHabit(habitId, from, todayUtc);
  final scheduleHistory = await scheduleRepo.getScheduleHistoryForHabit(
    habitId,
  );

  return StreakEngine.calculate(
    entries: entries,
    scheduleHistory: scheduleHistory,
  );
}

@riverpod
Future<StatisticsResult> habitStatistics(
  HabitStatisticsRef ref,
  String habitId,
  DateRange range,
) async {
  final entryRepo = await ref.watch(habitEntryRepositoryProvider.future);
  final limitRepo = await ref.watch(habitLimitRepositoryProvider.future);

  final entries = await entryRepo.getEntriesForHabit(
    habitId,
    range.start,
    range.end,
  );
  final limit = await limitRepo.getActiveLimitForHabit(habitId);

  return StatisticsService.calculate(entries: entries, activeLimit: limit);
}
