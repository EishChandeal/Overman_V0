import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/dtos/dtos.dart';
import '../../domain/enums/enums.dart';
import 'habit_providers.dart';
import 'repository_providers.dart';

part 'dashboard_providers.g.dart';

@riverpod
Future<List<HabitDayStatus>> todayDashboard(TodayDashboardRef ref) async {
  final habits = await ref.watch(habitListProvider.future);
  final entryRepo = await ref.watch(habitEntryRepositoryProvider.future);
  final scheduleRepo = await ref.watch(habitScheduleRepositoryProvider.future);
  final limitRepo = await ref.watch(habitLimitRepositoryProvider.future);

  final localNow = DateTime.now();
  final todayUtc = DateTime.utc(localNow.year, localNow.month, localNow.day);

  final entries = await entryRepo.getEntriesForDate(todayUtc);
  final entryMap = {for (final e in entries) e.habitId: e};

  final List<HabitDayStatus> statusList = [];

  final todayCalendarDate = DateTime(localNow.year, localNow.month, localNow.day);

  for (final habit in habits) {
    if (habit.isArchived) continue;

    // Habits/tasks must not be seen on dates before they were created
    final createdLocal = habit.createdAt.toLocal();
    final createdCalendarDate = DateTime(createdLocal.year, createdLocal.month, createdLocal.day);
    if (todayCalendarDate.isBefore(createdCalendarDate)) {
      continue;
    }

    // One-time tasks disappear after the day they were completed
    if (habit.isOneTime && habit.completedAt != null) {
      final completedLocal = habit.completedAt!.toLocal();
      final completedCalendarDate = DateTime(completedLocal.year, completedLocal.month, completedLocal.day);
      if (todayCalendarDate.isAfter(completedCalendarDate)) {
        continue;
      }
    }

    final activeSchedule = await scheduleRepo.getActiveScheduleForHabit(
      habit.id,
    );
    final activeLimit = await limitRepo.getActiveLimitForHabit(habit.id);
    final entry = entryMap[habit.id];

    bool isScheduledToday = false;
    if (habit.isOneTime) {
      isScheduledToday = true;
    } else if (activeSchedule != null) {
      switch (activeSchedule.scheduleType) {
        case ScheduleType.daily:
        case ScheduleType.timesPerWeek:
        case ScheduleType.timesPerMonth:
          isScheduledToday = true;
          break;
        case ScheduleType.specificWeekdays:
          final scheduledDays = activeSchedule.scheduledWeekdays ?? [];
          final todayWeekday = Weekday.fromDateTimeWeekday(todayUtc.weekday);
          isScheduledToday = scheduledDays.contains(todayWeekday);
          break;
      }
    }

    DayStatus status;
    if (!isScheduledToday) {
      status = DayStatus.notScheduled;
    } else if (habit.isOneTime && habit.completedAt != null) {
      status = DayStatus.met;
    } else if (entry != null && entry.value > 0) {
      if (activeLimit?.minValue != null &&
          entry.value < activeLimit!.minValue!) {
        status = DayStatus.partiallyMet;
      } else {
        status = DayStatus.met;
      }
    } else {
      status = DayStatus.missed;
    }

    statusList.add(
      HabitDayStatus(
        habit: habit,
        entry: entry,
        isScheduledToday: isScheduledToday,
        status: status,
        activeSchedule: activeSchedule,
        activeLimit: activeLimit,
      ),
    );
  }

  statusList.sort((a, b) => a.habit.name.compareTo(b.habit.name));
  return statusList;
}
