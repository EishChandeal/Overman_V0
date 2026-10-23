import 'dart:math';
import '../../data/models/dtos/dtos.dart';
import '../../domain/enums/enums.dart';

/// Service for calculating streak statistics: current streak, all-time best,
/// and top longest streaks in a year.
class StreakCalculator {
  StreakCalculator._();

  static bool _isCompleted(
      HabitEntryDto? entry, HabitType type, double? target) {
    if (entry == null) return false;
    if (type == HabitType.boolean) {
      return entry.value >= 1.0;
    } else {
      final effectiveTarget = (target != null && target > 0) ? target : 1.0;
      return entry.value >= effectiveTarget;
    }
  }

  static bool _isDayScheduled(DateTime date, HabitScheduleDto? schedule) {
    if (schedule == null) return true;
    if (schedule.scheduleType == ScheduleType.daily) return true;
    if (schedule.scheduleType == ScheduleType.specificWeekdays) {
      if (schedule.scheduledWeekdays == null ||
          schedule.scheduledWeekdays!.isEmpty) {
        return true;
      }
      final weekdayEnum = Weekday.values.firstWhere(
        (w) => w.index + 1 == date.weekday,
        orElse: () => Weekday.monday,
      );
      return schedule.scheduledWeekdays!.contains(weekdayEnum);
    }
    return true;
  }

  /// Computes the current streak (consecutive completed days ending on or before [today]).
  static int currentStreak(
    List<HabitEntryDto> entries, {
    DateTime? today,
    HabitType habitType = HabitType.boolean,
    double? target,
    HabitScheduleDto? schedule,
  }) {
    if (entries.isEmpty) return 0;

    final effectiveToday = today ?? DateTime.now();
    final todayMidnight = DateTime.utc(
      effectiveToday.year,
      effectiveToday.month,
      effectiveToday.day,
    );

    final entryMap = <DateTime, HabitEntryDto>{};
    for (final e in entries) {
      final dt = DateTime.utc(e.date.year, e.date.month, e.date.day);
      entryMap[dt] = e;
    }

    // Earliest entry date
    DateTime? earliestDate;
    for (final e in entries) {
      final dt = DateTime.utc(e.date.year, e.date.month, e.date.day);
      if (earliestDate == null || dt.isBefore(earliestDate)) {
        earliestDate = dt;
      }
    }

    int streak = 0;
    DateTime checkDay = todayMidnight;

    // 1. Check if today was completed
    if (_isDayScheduled(checkDay, schedule)) {
      if (_isCompleted(entryMap[checkDay], habitType, target)) {
        streak++;
        checkDay = checkDay.subtract(const Duration(days: 1));
      } else {
        // Today is scheduled but not completed yet: check backwards from yesterday
        checkDay = checkDay.subtract(const Duration(days: 1));
      }
    } else {
      // Today is unscheduled: check backwards from yesterday
      checkDay = checkDay.subtract(const Duration(days: 1));
    }

    // 2. Count consecutive completed scheduled days backwards
    while (earliestDate != null && !checkDay.isBefore(earliestDate)) {
      if (_isDayScheduled(checkDay, schedule)) {
        if (_isCompleted(entryMap[checkDay], habitType, target)) {
          streak++;
          checkDay = checkDay.subtract(const Duration(days: 1));
        } else {
          // Missed scheduled day -> streak broken
          break;
        }
      } else {
        // Rest day -> skip without breaking streak
        checkDay = checkDay.subtract(const Duration(days: 1));
      }
    }

    return streak;
  }

  /// Computes all contiguous streaks in chronological order.
  static List<({int length, DateTime start, DateTime end})> getAllStreaks(
    List<HabitEntryDto> entries, {
    HabitType habitType = HabitType.boolean,
    double? target,
    HabitScheduleDto? schedule,
    DateTime? today,
  }) {
    if (entries.isEmpty) return [];

    final effectiveToday = today ?? DateTime.now();
    final todayUtc = DateTime.utc(
      effectiveToday.year,
      effectiveToday.month,
      effectiveToday.day,
    );

    final completedDates = <DateTime>{};
    for (final e in entries) {
      if (_isCompleted(e, habitType, target)) {
        completedDates
            .add(DateTime.utc(e.date.year, e.date.month, e.date.day));
      }
    }

    if (completedDates.isEmpty) return [];

    final sortedDates = completedDates.toList()..sort();
    final earliest = sortedDates.first;

    final List<({int length, DateTime start, DateTime end})> streaks = [];

    int currentLen = 0;
    DateTime? currentStart;
    DateTime? currentEnd;

    DateTime day = earliest;
    while (!day.isAfter(todayUtc)) {
      if (_isDayScheduled(day, schedule)) {
        if (completedDates.contains(day)) {
          currentStart ??= day;
          currentLen++;
          currentEnd = day;
        } else {
          // Scheduled day not completed
          if (day == todayUtc) {
            // Today is still ongoing; save accumulated streak
            if (currentLen > 0 &&
                currentStart != null &&
                currentEnd != null) {
              streaks.add(
                  (length: currentLen, start: currentStart, end: currentEnd));
              currentLen = 0;
              currentStart = null;
              currentEnd = null;
            }
          } else {
            if (currentLen > 0 &&
                currentStart != null &&
                currentEnd != null) {
              streaks.add(
                  (length: currentLen, start: currentStart, end: currentEnd));
              currentLen = 0;
              currentStart = null;
              currentEnd = null;
            }
          }
        }
      }
      day = day.add(const Duration(days: 1));
    }

    if (currentLen > 0 && currentStart != null && currentEnd != null) {
      streaks.add((length: currentLen, start: currentStart, end: currentEnd));
    }

    return streaks;
  }

  /// Computes the all-time greatest consecutive streak.
  static int allTimeGreatestStreak(
    List<HabitEntryDto> entries, {
    HabitType habitType = HabitType.boolean,
    double? target,
    HabitScheduleDto? schedule,
    DateTime? today,
  }) {
    final streaks = getAllStreaks(
      entries,
      habitType: habitType,
      target: target,
      schedule: schedule,
      today: today,
    );
    if (streaks.isEmpty) return 0;
    return streaks.map((s) => s.length).reduce(max);
  }

  /// Returns the top [topN] longest streaks within [year] (defaults to current year),
  /// each as a record: (streakLength, startDate, endDate).
  static List<({int length, DateTime start, DateTime end})> topStreaksInYear(
    List<HabitEntryDto> entries, {
    int? year,
    int topN = 5,
    HabitType habitType = HabitType.boolean,
    double? target,
    HabitScheduleDto? schedule,
    DateTime? today,
  }) {
    final targetYear = year ?? (today ?? DateTime.now()).year;
    final all = getAllStreaks(
      entries,
      habitType: habitType,
      target: target,
      schedule: schedule,
      today: today,
    );

    // Filter streaks that touch the given year
    final inYear = all
        .where((s) => s.start.year == targetYear || s.end.year == targetYear)
        .toList();

    // Sort descending by length, then by recency (end date descending)
    inYear.sort((a, b) {
      final cmp = b.length.compareTo(a.length);
      if (cmp != 0) return cmp;
      return b.end.compareTo(a.end);
    });

    return inYear.take(topN).toList();
  }
}
