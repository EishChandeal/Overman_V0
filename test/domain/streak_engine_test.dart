import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/domain/enums/enums.dart';
import 'package:habit_tracker/domain/services/streak_engine.dart';

void main() {
  HabitEntryDto entry(DateTime date, double value) => HabitEntryDto(
    id: const Uuid().v4(),
    habitId: 'test-habit',
    date: date,
    value: value,
    createdAt: DateTime.now().toUtc(),
  );

  final defaultSchedule = HabitScheduleDto(
    id: const Uuid().v4(),
    habitId: 'test-habit',
    scheduleType: ScheduleType.daily,
    effectiveFrom: DateTime.utc(2000, 1, 1),
  );

  final localNow = DateTime.now();
  final todayMidnight = DateTime.utc(localNow.year, localNow.month, localNow.day);

  group('empty input', () {
    test('returns currentStreak of 0 when entry list is empty', () {
      final result = StreakEngine.calculate(entries: [], scheduleHistory: [defaultSchedule]);
      expect(result.currentStreak, 0);
    });
    test('returns longestStreak of 0 when entry list is empty', () {
      final result = StreakEngine.calculate(entries: [], scheduleHistory: [defaultSchedule]);
      expect(result.longestStreak, 0);
    });
    test('returns empty heatmap when entry list is empty', () {
      final result = StreakEngine.calculate(entries: [], scheduleHistory: [defaultSchedule]);
      expect(result.heatmap.isEmpty, true);
    });
  });

  group('basic streak building', () {
    test('1 consecutive day gives currentStreak of 1', () {
      final entries = [entry(todayMidnight, 1.0)];
      final result = StreakEngine.calculate(entries: entries, scheduleHistory: [defaultSchedule]);
      expect(result.currentStreak, 1);
    });
    
    test('5 consecutive days gives currentStreak of 5', () {
      final entries = List.generate(5, (i) => entry(todayMidnight.subtract(Duration(days: i)), 1.0));
      final result = StreakEngine.calculate(entries: entries, scheduleHistory: [defaultSchedule]);
      expect(result.currentStreak, 5);
    });
    
    test('streak counts correctly when entries are unsorted', () {
      final entries = [
        entry(todayMidnight.subtract(const Duration(days: 1)), 1.0),
        entry(todayMidnight, 1.0),
        entry(todayMidnight.subtract(const Duration(days: 2)), 1.0),
      ];
      final result = StreakEngine.calculate(entries: entries, scheduleHistory: [defaultSchedule]);
      expect(result.currentStreak, 3);
    });
  });

  group('streak breaking', () {
    test('a gap in the middle breaks the current streak', () {
      final entries = [
        entry(todayMidnight, 1.0),
        entry(todayMidnight.subtract(const Duration(days: 1)), 1.0),
        // Missed day 2
        entry(todayMidnight.subtract(const Duration(days: 3)), 1.0),
        entry(todayMidnight.subtract(const Duration(days: 4)), 1.0),
      ];
      final result = StreakEngine.calculate(entries: entries, scheduleHistory: [defaultSchedule]);
      expect(result.currentStreak, 2);
    });
    
    test('current streak resets to days after the last gap', () {
      final entries = [
        entry(todayMidnight, 1.0), // 1
        // gap at 1
        entry(todayMidnight.subtract(const Duration(days: 2)), 1.0),
        entry(todayMidnight.subtract(const Duration(days: 3)), 1.0),
      ];
      final result = StreakEngine.calculate(entries: entries, scheduleHistory: [defaultSchedule]);
      expect(result.currentStreak, 1);
    });
    
    test('longestStreak preserves the record before the gap', () {
      final entries = [
        entry(todayMidnight, 1.0),
        // gap at 1
        entry(todayMidnight.subtract(const Duration(days: 2)), 1.0),
        entry(todayMidnight.subtract(const Duration(days: 3)), 1.0),
        entry(todayMidnight.subtract(const Duration(days: 4)), 1.0),
      ];
      final result = StreakEngine.calculate(entries: entries, scheduleHistory: [defaultSchedule]);
      expect(result.longestStreak, 3);
    });
    
    test('two gaps leaves longestStreak as the longest run', () {
      final entries = [
        entry(todayMidnight, 1.0), // run of 1
        // gap 1
        entry(todayMidnight.subtract(const Duration(days: 2)), 1.0),
        entry(todayMidnight.subtract(const Duration(days: 3)), 1.0), // run of 2
        // gap 4
        entry(todayMidnight.subtract(const Duration(days: 5)), 1.0),
        entry(todayMidnight.subtract(const Duration(days: 6)), 1.0),
        entry(todayMidnight.subtract(const Duration(days: 7)), 1.0),
        entry(todayMidnight.subtract(const Duration(days: 8)), 1.0), // run of 4
      ];
      final result = StreakEngine.calculate(entries: entries, scheduleHistory: [defaultSchedule]);
      expect(result.longestStreak, 4);
    });
  });

  group('today edge cases', () {
    test('if today has no entry but yesterday was completed, current streak is not broken', () {
      final entries = [
        entry(todayMidnight.subtract(const Duration(days: 1)), 1.0),
        entry(todayMidnight.subtract(const Duration(days: 2)), 1.0),
      ];
      final result = StreakEngine.calculate(entries: entries, scheduleHistory: [defaultSchedule]);
      expect(result.currentStreak, 2);
    });
    
    test('if today AND yesterday have no entry, streak is 0', () {
      final entries = [
        entry(todayMidnight.subtract(const Duration(days: 2)), 1.0),
        entry(todayMidnight.subtract(const Duration(days: 3)), 1.0),
      ];
      final result = StreakEngine.calculate(entries: entries, scheduleHistory: [defaultSchedule]);
      expect(result.currentStreak, 0);
    });
    
    test('a single entry for today gives currentStreak of 1', () {
      final entries = [entry(todayMidnight, 1.0)];
      final result = StreakEngine.calculate(entries: entries, scheduleHistory: [defaultSchedule]);
      expect(result.currentStreak, 1);
    });
  });

  group('heatmap correctness', () {
    test('a completed day maps to DayStatus.met', () {
      final entries = [entry(todayMidnight, 1.0)];
      final result = StreakEngine.calculate(entries: entries, scheduleHistory: [defaultSchedule]);
      expect(result.heatmap[todayMidnight], DayStatus.met);
    });
    
    test('a day with no entry maps to DayStatus.missed', () {
      final start = todayMidnight.subtract(const Duration(days: 2));
      final entries = [
        entry(start, 1.0),
        // Missed yesterday
        entry(todayMidnight, 1.0),
      ];
      final result = StreakEngine.calculate(entries: entries, scheduleHistory: [defaultSchedule]);
      expect(result.heatmap[todayMidnight.subtract(const Duration(days: 1))], DayStatus.missed);
    });
    
    test('days before first entry map to DayStatus.notTracked', () {
      final start = todayMidnight.subtract(const Duration(days: 2));
      final entries = [
        entry(start, 1.0),
      ];
      final result = StreakEngine.calculate(entries: entries, scheduleHistory: [defaultSchedule]);
      
      final beforeStart = start.subtract(const Duration(days: 1));
      final status = result.heatmap[beforeStart] ?? DayStatus.notTracked;
      expect(status, DayStatus.notTracked);
    });
    
    test('heatmap contains an entry for every day from first entry to today', () {
      final start = todayMidnight.subtract(const Duration(days: 10));
      final entries = [
        entry(start, 1.0),
        entry(todayMidnight, 1.0),
      ];
      final result = StreakEngine.calculate(entries: entries, scheduleHistory: [defaultSchedule]);
      expect(result.heatmap.length, 11); // 10 days ago to today = 11 days
    });
  });

  group('timezone safety', () {
    test('entries created with local DateTime are normalized and streak calculates correctly', () {
      final nowLocal = DateTime.now(); // not .toUtc()
      final entries = [
        entry(nowLocal, 1.0),
        entry(nowLocal.subtract(const Duration(days: 1)), 1.0),
      ];
      final result = StreakEngine.calculate(entries: entries, scheduleHistory: [defaultSchedule]);
      expect(result.currentStreak, 2);
    });
  });

  group('non-daily schedule types', () {
    test('specificWeekdays marks non-scheduled days as notScheduled and maintains streak', () {
      final schedule = HabitScheduleDto(
        id: const Uuid().v4(),
        habitId: 'test-habit',
        scheduleType: ScheduleType.specificWeekdays,
        scheduledWeekdays: [Weekday.monday, Weekday.wednesday],
        effectiveFrom: DateTime.utc(2000, 1, 1),
      );

      // Create entries for Monday and Wednesday up to today
      final entries = <HabitEntryDto>[];
      var current = todayMidnight.subtract(const Duration(days: 6));
      DateTime? aMonday;
      while (!current.isAfter(todayMidnight)) {
        if (current.weekday == DateTime.monday || current.weekday == DateTime.wednesday) {
          entries.add(entry(current, 1.0));
          if (current.weekday == DateTime.monday) aMonday = current;
        }
        current = current.add(const Duration(days: 1));
      }

      final result = StreakEngine.calculate(
        entries: entries,
        scheduleHistory: [schedule],
      );

      if (aMonday != null) {
        expect(result.heatmap[aMonday], DayStatus.met);
        final tuesday = aMonday.add(const Duration(days: 1));
        if (!tuesday.isAfter(todayMidnight)) {
          expect(result.heatmap[tuesday], DayStatus.notScheduled);
        }
      }
      expect(result.currentStreak >= 1, true);
    });

    test('timesPerWeek marks rest days as notScheduled once weekly target is met', () {
      // Pick a Monday 14 days ago so full past weeks are evaluated deterministically
      var monday = todayMidnight.subtract(const Duration(days: 14));
      while (monday.weekday != DateTime.monday) {
        monday = monday.subtract(const Duration(days: 1));
      }
      final schedule = HabitScheduleDto(
        id: const Uuid().v4(),
        habitId: 'test-habit',
        scheduleType: ScheduleType.timesPerWeek,
        targetCount: 2,
        effectiveFrom: DateTime.utc(2000, 1, 1),
      );

      final entries = [
        entry(monday, 1.0),
        entry(monday.add(const Duration(days: 1)), 1.0), // Tuesday -> 2nd completion (target met)
      ];

      final result = StreakEngine.calculate(
        entries: entries,
        scheduleHistory: [schedule],
      );

      expect(result.heatmap[monday], DayStatus.met);
      expect(result.heatmap[monday.add(const Duration(days: 1))], DayStatus.met);
      expect(result.heatmap[monday.add(const Duration(days: 2))], DayStatus.notScheduled);
    });

    test('timesPerMonth calculates correctly when monthly target is met', () {
      final startOfMonth = DateTime.utc(todayMidnight.year, todayMidnight.month, 1);
      final schedule = HabitScheduleDto(
        id: const Uuid().v4(),
        habitId: 'test-habit',
        scheduleType: ScheduleType.timesPerMonth,
        targetCount: 1,
        effectiveFrom: DateTime.utc(2000, 1, 1),
      );

      final entries = [
        entry(startOfMonth, 1.0),
      ];

      final result = StreakEngine.calculate(
        entries: entries,
        scheduleHistory: [schedule],
      );

      expect(result.heatmap[startOfMonth], DayStatus.met);
    });
  });

  group('StreakResult value equality and hashCode', () {
    test('instances with identical streaks and heatmap are equal and have matching hashCode', () {
      final date = DateTime.utc(2026, 7, 1);
      final r1 = StreakResult(
        currentStreak: 5,
        longestStreak: 10,
        heatmap: {date: DayStatus.met},
      );
      final r2 = StreakResult(
        currentStreak: 5,
        longestStreak: 10,
        heatmap: {date: DayStatus.met},
      );

      expect(r1 == r2, isTrue);
      expect(r1.hashCode, equals(r2.hashCode));
    });

    test('instances with identical streaks but different heatmap are not equal', () {
      final date1 = DateTime.utc(2026, 7, 1);
      final date2 = DateTime.utc(2026, 7, 2);
      final r1 = StreakResult(
        currentStreak: 5,
        longestStreak: 10,
        heatmap: {date1: DayStatus.met},
      );
      final r2 = StreakResult(
        currentStreak: 5,
        longestStreak: 10,
        heatmap: {date1: DayStatus.met, date2: DayStatus.missed},
      );

      expect(r1 == r2, isFalse);
      expect(r1.hashCode == r2.hashCode, isFalse);
    });
  });
}
