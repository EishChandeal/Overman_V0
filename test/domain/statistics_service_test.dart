import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/domain/services/statistics_service.dart';

void main() {
  HabitEntryDto entry(DateTime date, double value) => HabitEntryDto(
    id: const Uuid().v4(),
    habitId: 'test-habit',
    date: date,
    value: value,
    createdAt: DateTime.now().toUtc(),
  );

  final today = DateTime.now().toUtc();
  final todayMidnight = DateTime.utc(today.year, today.month, today.day);

  group('empty input', () {
    test('average is 0.0 with no entries', () {
      final stats = StatisticsService.calculate(entries: []);
      expect(stats.average, 0.0);
    });
    test('completionRate is 0.0 with no entries', () {
      final stats = StatisticsService.calculate(entries: []);
      expect(stats.completionRate, 0.0);
    });
    test('weeklyAverages is empty with no entries', () {
      final stats = StatisticsService.calculate(entries: []);
      expect(stats.weeklyAverages.isEmpty, true);
    });
  });

  group('average calculation', () {
    test('average of [10, 20, 30] is 20.0', () {
      final entries = [
        entry(todayMidnight, 10.0),
        entry(todayMidnight.subtract(const Duration(days: 1)), 20.0),
        entry(todayMidnight.subtract(const Duration(days: 2)), 30.0),
      ];
      final stats = StatisticsService.calculate(entries: entries);
      expect(stats.average, 20.0);
    });
    
    test('average ignores no entries (all positive values)', () {
      final entries = [
        entry(todayMidnight, 10.0),
        entry(todayMidnight.subtract(const Duration(days: 2)), 20.0),
      ];
      final stats = StatisticsService.calculate(entries: entries);
      expect(stats.average, 15.0);
    });
  });

  group('completion rate', () {
    test('completionRate is 1.0 when all entries have value > 0', () {
      final entries = [
        entry(todayMidnight, 1.0),
        entry(todayMidnight.subtract(const Duration(days: 1)), 5.0),
      ];
      final stats = StatisticsService.calculate(entries: entries);
      expect(stats.completionRate, 1.0);
    });
    
    test('completionRate is 0.5 when half the entries are 0.0', () {
      final entries = [
        entry(todayMidnight, 1.0),
        entry(todayMidnight.subtract(const Duration(days: 1)), 0.0),
        entry(todayMidnight.subtract(const Duration(days: 2)), 5.0),
        entry(todayMidnight.subtract(const Duration(days: 3)), 0.0),
      ];
      final stats = StatisticsService.calculate(entries: entries);
      expect(stats.completionRate, 0.5);
    });
    
    test('completionRate is 0.0 when all entries have value 0.0', () {
      final entries = [
        entry(todayMidnight, 0.0),
        entry(todayMidnight.subtract(const Duration(days: 1)), 0.0),
      ];
      final stats = StatisticsService.calculate(entries: entries);
      expect(stats.completionRate, 0.0);
    });
  });

  group('best value', () {
    test('bestValue returns the highest single entry', () {
      final entries = [
        entry(todayMidnight, 10.0),
        entry(todayMidnight.subtract(const Duration(days: 1)), 50.0),
        entry(todayMidnight.subtract(const Duration(days: 2)), 5.0),
      ];
      final stats = StatisticsService.calculate(entries: entries);
      expect(stats.bestValue, 50.0);
    });
    
    test('bestValue is 0.0 with no entries', () {
      final stats = StatisticsService.calculate(entries: []);
      expect(stats.bestValue, 0.0);
    });
  });

  group('weekly averages', () {
    test('two entries in the same ISO week average together', () {
      // Find a Monday and a Tuesday of the same week
      final monday = DateTime.utc(2026, 6, 29); // Monday
      final tuesday = DateTime.utc(2026, 6, 30); // Tuesday
      final entries = [
        entry(monday, 10.0),
        entry(tuesday, 30.0),
      ];
      final stats = StatisticsService.calculate(entries: entries);
      expect(stats.weeklyAverages.length, 1);
      expect(stats.weeklyAverages.values.first, 20.0);
    });
    
    test('entries in different ISO weeks produce separate keys', () {
      final monday = DateTime.utc(2026, 6, 29); // Monday
      final lastMonday = DateTime.utc(2026, 6, 22); // Previous Monday
      final entries = [
        entry(monday, 10.0),
        entry(lastMonday, 30.0),
      ];
      final stats = StatisticsService.calculate(entries: entries);
      expect(stats.weeklyAverages.length, 2);
    });
    
    test('a week with only one entry has that value as the average', () {
      final monday = DateTime.utc(2026, 6, 29);
      final entries = [entry(monday, 42.0)];
      final stats = StatisticsService.calculate(entries: entries);
      expect(stats.weeklyAverages.values.first, 42.0);
    });
  });

  group('totalTrackedDays and totalMissedDays', () {
    test('counts entries with value > 0 as tracked', () {
      final entries = [entry(todayMidnight, 5.0)];
      final stats = StatisticsService.calculate(entries: entries);
      expect(stats.totalTrackedDays, 1);
      expect(stats.totalMissedDays, 0);
    });
    
    test('counts entries with value == 0 as missed', () {
      final entries = [entry(todayMidnight, 0.0)];
      final stats = StatisticsService.calculate(entries: entries);
      expect(stats.totalTrackedDays, 0);
      expect(stats.totalMissedDays, 1);
    });
    
    test('sum of tracked and missed equals total entry count', () {
      final entries = [
        entry(todayMidnight, 5.0),
        entry(todayMidnight.subtract(const Duration(days: 1)), 0.0),
        entry(todayMidnight.subtract(const Duration(days: 2)), 0.0),
        entry(todayMidnight.subtract(const Duration(days: 3)), 10.0),
      ];
      final stats = StatisticsService.calculate(entries: entries);
      expect(stats.totalTrackedDays + stats.totalMissedDays, entries.length);
    });
  });

  group('StatisticsResult value equality and hashCode', () {
    test('instances with identical fields and weeklyAverages map have matching hashCode and equality', () {
      const s1 = StatisticsResult(
        average: 10.0,
        sum: 100.0,
        completionRate: 0.8,
        totalTrackedDays: 8,
        totalMissedDays: 2,
        bestValue: 20.0,
        weeklyAverages: {202601: 10.0, 202602: 12.0},
      );
      const s2 = StatisticsResult(
        average: 10.0,
        sum: 100.0,
        completionRate: 0.8,
        totalTrackedDays: 8,
        totalMissedDays: 2,
        bestValue: 20.0,
        weeklyAverages: {202601: 10.0, 202602: 12.0},
      );

      expect(s1 == s2, isTrue);
      expect(s1.hashCode, equals(s2.hashCode));
    });

    test('instances differing in weeklyAverages are not equal and have different hashCode', () {
      const s1 = StatisticsResult(
        average: 10.0,
        sum: 100.0,
        completionRate: 0.8,
        totalTrackedDays: 8,
        totalMissedDays: 2,
        bestValue: 20.0,
        weeklyAverages: {202601: 10.0},
      );
      const s2 = StatisticsResult(
        average: 10.0,
        sum: 100.0,
        completionRate: 0.8,
        totalTrackedDays: 8,
        totalMissedDays: 2,
        bestValue: 20.0,
        weeklyAverages: {202601: 10.0, 202602: 12.0},
      );

      expect(s1 == s2, isFalse);
      expect(s1.hashCode == s2.hashCode, isFalse);
    });
  });
}
