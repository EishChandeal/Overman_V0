import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/application/services/ai_data_formatter.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/domain/enums/enums.dart';

void main() {
  group('AiDataFormatter unit tests', () {
    final fixedToday = DateTime.utc(2026, 10, 20);

    test('0 habits returns "No habit data available."', () {
      final output = AiDataFormatter.format(
        habits: [],
        entriesByHabitId: {},
        windowDays: 7,
        today: fixedToday,
      );

      expect(output, equals('No habit data available.'));
    });

    test('1 boolean habit with entries in window formats correct ✅/❌/— grid', () {
      final habit = HabitDto(
        id: 'h-bool-1',
        name: 'Morning Run',
        type: HabitType.boolean,
        colorHex: '#216CCF',
        iconName: 'directions_run',
        createdAt: DateTime.utc(2026, 1, 1),
        isArchived: false,
      );

      final entries = [
        HabitEntryDto(
          id: 'e-1',
          habitId: 'h-bool-1',
          date: DateTime.utc(2026, 10, 18),
          value: 1,
          createdAt: DateTime.utc(2026, 10, 18),
        ),
        HabitEntryDto(
          id: 'e-2',
          habitId: 'h-bool-1',
          date: DateTime.utc(2026, 10, 19),
          value: 0,
          createdAt: DateTime.utc(2026, 10, 19),
        ),
        // 20 Oct has no entry -> should be '—'
      ];

      final output = AiDataFormatter.format(
        habits: [habit],
        entriesByHabitId: {habit.id: entries},
        windowDays: 3,
        today: fixedToday,
      );

      expect(output, contains('=== User Habit Data (last 3 days) ==='));
      expect(output, contains('Generated: Tue, 20 Oct 2026'));
      expect(output, contains('--- Habit: "Morning Run" ---'));
      expect(output, contains('Sun 18 Oct ✅'));
      expect(output, contains('Mon 19 Oct ❌'));
      expect(output, contains('Tue 20 Oct —'));
    });

    test('1 numeric habit with entry at target appends ✅, below target shows value only', () {
      final habit = HabitDto(
        id: 'h-num-1',
        name: 'Hydration',
        type: HabitType.numeric,
        unit: 'ml',
        targetValue: 2000,
        colorHex: '#33B3FF',
        iconName: 'water_drop',
        createdAt: DateTime.utc(2026, 1, 1),
        isArchived: false,
      );

      final entries = [
        HabitEntryDto(
          id: 'e-1',
          habitId: 'h-num-1',
          date: DateTime.utc(2026, 10, 19),
          value: 2000,
          createdAt: DateTime.utc(2026, 10, 19),
        ),
        HabitEntryDto(
          id: 'e-2',
          habitId: 'h-num-1',
          date: DateTime.utc(2026, 10, 20),
          value: 1500,
          createdAt: DateTime.utc(2026, 10, 20),
        ),
      ];

      final output = AiDataFormatter.format(
        habits: [habit],
        entriesByHabitId: {habit.id: entries},
        windowDays: 2,
        today: fixedToday,
      );

      expect(output, contains('Type: Habit (numeric) | Unit: ml | Target: 2000'));
      expect(output, contains('Mon 19 Oct 2000 ✅'));
      expect(output, contains('Tue 20 Oct 1500'));
      expect(output, isNot(contains('Tue 20 Oct 1500 ✅')));
    });

    test('Habit description and day notes both appear in output', () {
      final habit = HabitDto(
        id: 'h-desc-1',
        name: 'Deep Reading',
        type: HabitType.boolean,
        colorHex: '#216CCF',
        iconName: 'book',
        description: 'Read 20 pages of philosophical works.',
        createdAt: DateTime.utc(2026, 1, 1),
        isArchived: false,
      );

      final dayNotes = [
        DayNoteDto(
          id: 'n-1',
          habitId: 'h-desc-1',
          date: DateTime.utc(2026, 10, 19),
          note: 'Read Chapter 4 of Beyond Good and Evil.',
          createdAt: DateTime.utc(2026, 10, 19),
          updatedAt: DateTime.utc(2026, 10, 19),
        ),
      ];

      final output = AiDataFormatter.format(
        habits: [habit],
        entriesByHabitId: {habit.id: []},
        dayNotesByHabitId: {habit.id: dayNotes},
        windowDays: 3,
        today: fixedToday,
      );

      expect(output, contains('Description: Read 20 pages of philosophical works.'));
      expect(output, contains('Notes:'));
      expect(output, contains('[Mon 19 Oct] "Read Chapter 4 of Beyond Good and Evil."'));
    });

    test('windowDays = 7 excludes entries older than 7 days from output', () {
      final habit = HabitDto(
        id: 'h-window-1',
        name: 'Guitar Practice',
        type: HabitType.boolean,
        colorHex: '#FF9500',
        iconName: 'music_note',
        createdAt: DateTime.utc(2026, 1, 1),
        isArchived: false,
      );

      final entries = [
        HabitEntryDto(
          id: 'e-old',
          habitId: 'h-window-1',
          date: DateTime.utc(2026, 10, 10), // 10 days ago (outside 7-day window)
          value: 1,
          createdAt: DateTime.utc(2026, 10, 10),
        ),
        HabitEntryDto(
          id: 'e-recent',
          habitId: 'h-window-1',
          date: DateTime.utc(2026, 10, 18), // in window
          value: 1,
          createdAt: DateTime.utc(2026, 10, 18),
        ),
      ];

      final output = AiDataFormatter.format(
        habits: [habit],
        entriesByHabitId: {habit.id: entries},
        windowDays: 7,
        today: fixedToday,
      );

      expect(output, isNot(contains('10 Oct')));
      expect(output, contains('Sun 18 Oct ✅'));
    });

    test('Date injection parameter ensures deterministic output', () {
      final habit = HabitDto(
        id: 'h-det-1',
        name: 'Evening Walk',
        type: HabitType.boolean,
        colorHex: '#34C759',
        iconName: 'directions_walk',
        createdAt: DateTime.utc(2026, 5, 1),
        isArchived: false,
      );

      final customDate = DateTime.utc(2025, 6, 15);
      final output = AiDataFormatter.format(
        habits: [habit],
        entriesByHabitId: {habit.id: []},
        windowDays: 1,
        today: customDate,
      );

      expect(output, contains('Generated: Sun, 15 Jun 2025'));
      expect(output, contains('Sun 15 Jun —'));
    });

    test('One-time task completed vs pending format', () {
      final taskDone = HabitDto(
        id: 't-1',
        name: 'Submit Proposal',
        type: HabitType.boolean,
        colorHex: '#FF9500',
        iconName: 'task_alt',
        isOneTime: true,
        completedAt: DateTime.utc(2026, 10, 18),
        createdAt: DateTime.utc(2026, 10, 1),
        isArchived: false,
      );

      final taskPending = HabitDto(
        id: 't-2',
        name: 'Renew Passport',
        type: HabitType.boolean,
        colorHex: '#AF52DE',
        iconName: 'task_alt',
        isOneTime: true,
        createdAt: DateTime.utc(2026, 10, 1),
        isArchived: false,
      );

      final output = AiDataFormatter.format(
        habits: [taskDone, taskPending],
        entriesByHabitId: {},
        windowDays: 7,
        today: fixedToday,
      );

      expect(output, contains('--- One-time Task: "Submit Proposal" ---'));
      expect(output, contains('Status: ✅ Completed on Sun 18 Oct 2026'));
      expect(output, contains('--- One-time Task: "Renew Passport" ---'));
      expect(output, contains('Status: ⏳ Pending'));
    });
  });
}
