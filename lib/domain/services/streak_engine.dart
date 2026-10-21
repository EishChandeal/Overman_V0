import 'package:flutter/foundation.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/domain/enums/enums.dart';

/// Pure domain service calculating streaks and heatmaps.
///
/// Pragmatic Clean Architecture Note:
/// To ensure zero-overhead functional evaluation without duplicate boilerplate
/// mapping classes, this pure domain calculation operates directly on immutable
/// data records ([HabitEntryDto], [HabitScheduleDto]).
class StreakResult {
  final int currentStreak;
  final int longestStreak;
  final Map<DateTime, DayStatus> heatmap;

  const StreakResult({
    required this.currentStreak,
    required this.longestStreak,
    required this.heatmap,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StreakResult &&
        other.currentStreak == currentStreak &&
        other.longestStreak == longestStreak &&
        mapEquals(other.heatmap, heatmap);
  }

  @override
  int get hashCode => Object.hash(currentStreak, longestStreak, heatmap.length);

  @override
  String toString() {
    return 'StreakResult(currentStreak: $currentStreak, longestStreak: $longestStreak, heatmapSize: ${heatmap.length})';
  }
}

class StreakEngine {
  static StreakResult calculate({
    required List<HabitEntryDto> entries,
    required List<HabitScheduleDto> scheduleHistory,
  }) {
    if (entries.isEmpty) {
      return const StreakResult(
        currentStreak: 0,
        longestStreak: 0,
        heatmap: {},
      );
    }

    // 1. Normalize all entry dates to midnight UTC
    final normalizedEntries = entries.map((e) => e.copyWith(
      date: DateTime.utc(e.date.year, e.date.month, e.date.day),
    )).toList();

    // 2. Sort entries by date ascending
    normalizedEntries.sort((a, b) => a.date.compareTo(b.date));

    // Note: If multiple entries exist for the same date (which shouldn't happen 
    // due to repo layer deduplication), this will silently overwrite earlier ones.
    final entryMap = {for (final e in normalizedEntries) e.date: e};

    final earliestEntryDate = normalizedEntries.first.date;
    final localNow = DateTime.now();
    final todayMidnight = DateTime.utc(localNow.year, localNow.month, localNow.day);

    final startDate = earliestEntryDate;

    final Map<DateTime, DayStatus> heatmap = {};
    final Map<String, int> completionsCache = {};
    DateTime currentDay = startDate;

    // 3. Populate heatmap day by day
    while (!currentDay.isAfter(todayMidnight)) {
      if (currentDay.isBefore(earliestEntryDate)) {
        heatmap[currentDay] = DayStatus.notTracked;
      } else {
        final schedule = _scheduleForDate(currentDay, scheduleHistory);
        if (schedule == null) {
          heatmap[currentDay] = DayStatus.notScheduled;
        } else {
          final entry = entryMap[currentDay];
          switch (schedule.scheduleType) {
            case ScheduleType.daily:
              if (entry != null && entry.value > 0.0) {
                heatmap[currentDay] = DayStatus.met;
              } else {
                heatmap[currentDay] = DayStatus.missed;
              }
              break;

            case ScheduleType.specificWeekdays:
              final weekdayEnum = Weekday.fromDateTimeWeekday(currentDay.weekday);
              final scheduledDays = schedule.scheduledWeekdays ?? [];
              if (scheduledDays.contains(weekdayEnum)) {
                if (entry != null && entry.value > 0.0) {
                  heatmap[currentDay] = DayStatus.met;
                } else {
                  heatmap[currentDay] = DayStatus.missed;
                }
              } else {
                heatmap[currentDay] = DayStatus.notScheduled;
              }
              break;

            case ScheduleType.timesPerWeek:
              final windowStart = currentDay.subtract(Duration(days: currentDay.weekday - 1));
              final windowEnd = windowStart.add(const Duration(days: 6));
              final cacheKey = 'week_${windowStart.toIso8601String()}';
              final completedCount = completionsCache.putIfAbsent(cacheKey, () => 
                _countCompletionsInWindow(
                  windowStart,
                  windowEnd,
                  scheduleHistory,
                  entryMap,
                  ScheduleType.timesPerWeek,
                )
              );
              final target = schedule.targetCount ?? 1;

              if (entry != null && entry.value > 0.0) {
                heatmap[currentDay] = DayStatus.met;
              } else {
                if (completedCount >= target) {
                  heatmap[currentDay] = DayStatus.notScheduled;
                } else if (windowEnd.isBefore(todayMidnight)) {
                  heatmap[currentDay] = DayStatus.missed;
                } else {
                  heatmap[currentDay] = DayStatus.notScheduled;
                }
              }
              break;

            case ScheduleType.timesPerMonth:
              final windowStart = DateTime.utc(currentDay.year, currentDay.month, 1);
              final windowEnd = DateTime.utc(currentDay.year, currentDay.month + 1, 1)
                  .subtract(const Duration(days: 1));
              final cacheKey = 'month_${windowStart.toIso8601String()}';
              final completedCount = completionsCache.putIfAbsent(cacheKey, () =>
                _countCompletionsInWindow(
                  windowStart,
                  windowEnd,
                  scheduleHistory,
                  entryMap,
                  ScheduleType.timesPerMonth,
                )
              );
              final target = schedule.targetCount ?? 1;

              if (entry != null && entry.value > 0.0) {
                heatmap[currentDay] = DayStatus.met;
              } else {
                if (completedCount >= target) {
                  heatmap[currentDay] = DayStatus.notScheduled;
                } else if (windowEnd.isBefore(todayMidnight)) {
                  heatmap[currentDay] = DayStatus.missed;
                } else {
                  heatmap[currentDay] = DayStatus.notScheduled;
                }
              }
              break;
          }
        }
      }
      currentDay = currentDay.add(const Duration(days: 1));
    }

    // 4. Calculate current streak (backwards from today)
    int currentStreak = 0;
    DateTime checkDay = todayMidnight;
    bool isToday = true;

    while (true) {
      if (checkDay.isBefore(startDate)) {
        break;
      }

      final status = heatmap[checkDay] ?? DayStatus.notScheduled;

      if (status == DayStatus.met || status == DayStatus.exceeded) {
        currentStreak++;
        isToday = false;
        checkDay = checkDay.subtract(const Duration(days: 1));
      } else if (status == DayStatus.notScheduled) {
        // UX Note: This skips notScheduled days indefinitely. For example, if a user 
        // only tracks on Mondays, they will see a streak of "1" even on Saturday.
        isToday = false;
        checkDay = checkDay.subtract(const Duration(days: 1));
      } else if (status == DayStatus.missed) {
        // If today has no entry yet, do not break the streak
        if (isToday && entryMap[checkDay] == null) {
          isToday = false;
          checkDay = checkDay.subtract(const Duration(days: 1));
        } else {
          break;
        }
      } else {
        break;
      }
    }

    // 5. Calculate longest streak (forward from start)
    int longestStreak = 0;
    int tempStreak = 0;
    currentDay = startDate;

    while (!currentDay.isAfter(todayMidnight)) {
      final status = heatmap[currentDay] ?? DayStatus.notScheduled;

      if (status == DayStatus.met || status == DayStatus.exceeded) {
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else if (status == DayStatus.notScheduled) {
        // Skip notScheduled days.
        // Design Decision: For timesPerWeek/Month schedules, days after the target 
        // is met become notScheduled. This means the longest streak seamlessly spans 
        // across these "completed" rest days into the next week/month window.
      } else {
        tempStreak = 0;
      }
      currentDay = currentDay.add(const Duration(days: 1));
    }

    return StreakResult(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      heatmap: heatmap,
    );
  }

  static HabitScheduleDto? _scheduleForDate(
    DateTime date,
    List<HabitScheduleDto> history,
  ) {
    final dateMidnight = DateTime.utc(date.year, date.month, date.day);
    HabitScheduleDto? bestMatch;
    DateTime? bestStart;

    for (final schedule in history) {
      final startMidnight = DateTime.utc(
        schedule.effectiveFrom.year,
        schedule.effectiveFrom.month,
        schedule.effectiveFrom.day,
      );
      final endMidnight = schedule.effectiveTo != null
          ? DateTime.utc(
              schedule.effectiveTo!.year,
              schedule.effectiveTo!.month,
              schedule.effectiveTo!.day,
            )
          : null;

      if (!dateMidnight.isBefore(startMidnight) &&
          (endMidnight == null || dateMidnight.isBefore(endMidnight))) {
        if (bestStart == null || startMidnight.isAfter(bestStart)) {
          bestMatch = schedule;
          bestStart = startMidnight;
        }
      }
    }
    return bestMatch;
  }

  static int _countCompletionsInWindow(
    DateTime start,
    DateTime end,
    List<HabitScheduleDto> history,
    Map<DateTime, HabitEntryDto> entryMap,
    ScheduleType type,
  ) {
    int count = 0;
    DateTime current = start;
    while (!current.isAfter(end)) {
      final sched = _scheduleForDate(current, history);
      if (sched != null && sched.scheduleType == type) {
        final entry = entryMap[current];
        if (entry != null && entry.value > 0.0) {
          count++;
        }
      }
      current = current.add(const Duration(days: 1));
    }
    return count;
  }
}
