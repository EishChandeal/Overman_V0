import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/application/services/habit_stats_calculator.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/domain/enums/enums.dart';

void main() {
  group('HabitStatsCalculator (STRAT-02-C)', () {
    test('Daily habit, 7 days active, 5 completions -> 71.4%', () {
      final createdAt = DateTime.utc(2026, 10, 1);
      final today = DateTime.utc(2026, 10, 7); // 7 days: Oct 1, 2, 3, 4, 5, 6, 7

      final habit = HabitDto(
        id: 'h1',
        name: 'Running',
        type: HabitType.boolean,
        colorHex: '#216CCF',
        iconName: 'directions_run',
        isArchived: false,
        createdAt: createdAt,
      );

      final entries = List<HabitEntryDto>.generate(
        5,
        (i) => HabitEntryDto(
          id: 'e$i',
          habitId: 'h1',
          date: createdAt.add(Duration(days: i)),
          value: 1.0,
          createdAt: createdAt.add(Duration(days: i)),
        ),
      );

      final activeDays = HabitStatsCalculator.computeActiveDays(habit, [], today);
      expect(activeDays, 7);

      final completedDays = HabitStatsCalculator.computeCompletedDays(entries, habit);
      expect(completedDays, 5);

      final rate = HabitStatsCalculator.computeCompletionRate(habit, entries, [], today);
      expect((rate).toStringAsFixed(1), '71.4');
    });

    test('Mon/Wed/Fri habit over 2 weeks (6 scheduled days), 6 completions -> 100%', () {
      // 2026-10-05 is a Monday. 2 full weeks ends on Sunday 2026-10-18.
      final startMonday = DateTime.utc(2026, 10, 5);
      final endSunday = DateTime.utc(2026, 10, 18);

      final habit = HabitDto(
        id: 'h2',
        name: 'Gym',
        type: HabitType.boolean,
        colorHex: '#FF9500',
        iconName: 'fitness_center',
        isArchived: false,
        createdAt: startMonday,
      );

      final weekdays = ['monday', 'wednesday', 'friday'];
      final activeDays = HabitStatsCalculator.computeActiveDays(habit, weekdays, endSunday);
      expect(activeDays, 6);

      // Create 6 completed entries on those scheduled days
      final scheduledDates = [
        DateTime.utc(2026, 10, 5),  // Mon
        DateTime.utc(2026, 10, 7),  // Wed
        DateTime.utc(2026, 10, 9),  // Fri
        DateTime.utc(2026, 10, 12), // Mon
        DateTime.utc(2026, 10, 14), // Wed
        DateTime.utc(2026, 10, 16), // Fri
      ];

      final entries = scheduledDates
          .map((d) => HabitEntryDto(
                id: d.toIso8601String(),
                habitId: 'h2',
                date: d,
                value: 1.0,
                createdAt: d,
              ))
          .toList();

      final rate = HabitStatsCalculator.computeCompletionRate(habit, entries, weekdays, endSunday);
      expect(rate, 100.0);
    });

    test('One-time task completed -> 100%', () {
      final habit = HabitDto(
        id: 't1',
        name: 'File Taxes',
        type: HabitType.boolean,
        colorHex: '#216CCF',
        iconName: 'task',
        isArchived: false,
        createdAt: DateTime.utc(2026, 10, 1),
        isOneTime: true,
      );

      final entries = [
        HabitEntryDto(
          id: 'e1',
          habitId: 't1',
          date: DateTime.utc(2026, 10, 2),
          value: 1.0,
          createdAt: DateTime.utc(2026, 10, 2),
        ),
      ];

      final rate = HabitStatsCalculator.computeCompletionRate(habit, entries, [], DateTime.utc(2026, 10, 5));
      expect(rate, 100.0);
    });

    test('One-time task pending -> 0%', () {
      final habit = HabitDto(
        id: 't2',
        name: 'Dentist Appointment',
        type: HabitType.boolean,
        colorHex: '#216CCF',
        iconName: 'task',
        isArchived: false,
        createdAt: DateTime.utc(2026, 10, 1),
        isOneTime: true,
      );

      final rate = HabitStatsCalculator.computeCompletionRate(habit, [], [], DateTime.utc(2026, 10, 5));
      expect(rate, 0.0);
    });

    test('activeDays == 0 guard returns 0%', () {
      final habit = HabitDto(
        id: 'h3',
        name: 'Future Habit',
        type: HabitType.boolean,
        colorHex: '#216CCF',
        iconName: 'star',
        isArchived: false,
        createdAt: DateTime.utc(2026, 10, 10),
      );

      // today is before createdAt
      final today = DateTime.utc(2026, 10, 5);
      final activeDays = HabitStatsCalculator.computeActiveDays(habit, [], today);
      expect(activeDays, 0);

      final rate = HabitStatsCalculator.computeCompletionRate(habit, [], [], today);
      expect(rate, 0.0);
    });
  });
}
