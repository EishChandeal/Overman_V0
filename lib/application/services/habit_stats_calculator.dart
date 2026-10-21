import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/domain/enums/enums.dart';

/// Service for calculating habit active days, completed days, and completion rate.
class HabitStatsCalculator {
  /// Computes the number of days the habit was scheduled from [habit.createdAt]
  /// up to and including [today].
  static int computeActiveDays(
    HabitDto habit,
    List<String> scheduledWeekdays,
    DateTime today,
  ) {
    if (habit.isOneTime) {
      return 1;
    }

    final start = DateTime.utc(
      habit.createdAt.year,
      habit.createdAt.month,
      habit.createdAt.day,
    );
    final end = DateTime.utc(
      today.year,
      today.month,
      today.day,
    );

    if (end.isBefore(start)) {
      return 0;
    }

    // Daily schedule if scheduledWeekdays is empty
    if (scheduledWeekdays.isEmpty) {
      return end.difference(start).inDays + 1;
    }

    final scheduledSet =
        scheduledWeekdays.map((s) => s.trim().toLowerCase()).toSet();

    int count = 0;
    DateTime current = start;
    while (!current.isAfter(end)) {
      final weekdayEnum = Weekday.fromDateTimeWeekday(current.weekday);
      if (scheduledSet.contains(weekdayEnum.name.toLowerCase()) ||
          scheduledSet.contains(weekdayEnum.shortName.toLowerCase())) {
        count++;
      }
      current = current.add(const Duration(days: 1));
    }
    return count;
  }

  /// Computes the number of unique calendar days where the habit was completed.
  /// Boolean habit: value >= 1.0.
  /// Numeric habit: value >= target (if target is null, value > 0).
  static int computeCompletedDays(
    List<HabitEntryDto> entries,
    HabitDto habit,
  ) {
    final completedDates = <int>{};

    for (final entry in entries) {
      final isCompleted = habit.type == HabitType.numeric
          ? (habit.targetValue != null
              ? entry.value >= habit.targetValue!
              : entry.value > 0)
          : entry.value >= 1.0;

      if (isCompleted) {
        final d = DateTime.utc(
          entry.date.year,
          entry.date.month,
          entry.date.day,
        );
        completedDates.add(d.millisecondsSinceEpoch);
      }
    }

    return completedDates.length;
  }

  /// Computes the completion percentage (0.0 to 100.0) based on formula:
  /// (completedDays / activeDays) * 100
  static double computeCompletionRate(
    HabitDto habit,
    List<HabitEntryDto> entries,
    List<String> scheduledWeekdays,
    DateTime today,
  ) {
    if (habit.isOneTime) {
      final hasCompleted = computeCompletedDays(entries, habit) > 0;
      return hasCompleted ? 100.0 : 0.0;
    }

    final activeDays = computeActiveDays(habit, scheduledWeekdays, today);
    if (activeDays <= 0) {
      return 0.0;
    }

    final completedDays = computeCompletedDays(entries, habit);
    return (completedDays / activeDays) * 100.0;
  }
}
