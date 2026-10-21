import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/application/services/streak_calculator.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/domain/enums/enums.dart';
import 'package:habit_tracker/presentation/screens/habit_detail/habit_detail_screen.dart';
import 'package:habit_tracker/presentation/theme/app_theme.dart';
import 'package:habit_tracker/presentation/widgets/streak_analytics_widget.dart';

void main() {
  final testHabit = HabitDto(
    id: 'habit-streak-1',
    name: 'Pushups',
    type: HabitType.boolean,
    colorHex: '#216CCF',
    iconName: 'fitness_center',
    createdAt: DateTime.utc(2026, 1, 1),
    isArchived: false,
  );

  group('StreakCalculator Unit Tests (STRAT-01-D)', () {
    test('currentStreak returns 0 when entries are empty', () {
      final streak = StreakCalculator.currentStreak(
        [],
        today: DateTime.utc(2026, 3, 10),
      );
      expect(streak, 0);
    });

    test('currentStreak counts consecutive days ending on today', () {
      final today = DateTime.utc(2026, 3, 10);
      final entries = [
        HabitEntryDto(
          id: '1',
          habitId: 'h1',
          date: DateTime.utc(2026, 3, 8),
          value: 1.0,
          createdAt: today,
        ),
        HabitEntryDto(
          id: '2',
          habitId: 'h1',
          date: DateTime.utc(2026, 3, 9),
          value: 1.0,
          createdAt: today,
        ),
        HabitEntryDto(
          id: '3',
          habitId: 'h1',
          date: DateTime.utc(2026, 3, 10),
          value: 1.0,
          createdAt: today,
        ),
      ];

      final streak = StreakCalculator.currentStreak(entries, today: today);
      expect(streak, 3);
    });

    test('currentStreak is not broken if today is not yet logged but yesterday was', () {
      final today = DateTime.utc(2026, 3, 10);
      final entries = [
        HabitEntryDto(
          id: '1',
          habitId: 'h1',
          date: DateTime.utc(2026, 3, 8),
          value: 1.0,
          createdAt: today,
        ),
        HabitEntryDto(
          id: '2',
          habitId: 'h1',
          date: DateTime.utc(2026, 3, 9),
          value: 1.0,
          createdAt: today,
        ),
      ];

      final streak = StreakCalculator.currentStreak(entries, today: today);
      expect(streak, 2);
    });

    test('currentStreak returns 0 if today and yesterday were both missed', () {
      final today = DateTime.utc(2026, 3, 10);
      final entries = [
        HabitEntryDto(
          id: '1',
          habitId: 'h1',
          date: DateTime.utc(2026, 3, 7),
          value: 1.0,
          createdAt: today,
        ),
        HabitEntryDto(
          id: '2',
          habitId: 'h1',
          date: DateTime.utc(2026, 3, 8),
          value: 1.0,
          createdAt: today,
        ),
      ];

      final streak = StreakCalculator.currentStreak(entries, today: today);
      expect(streak, 0);
    });

    test('currentStreak skips unscheduled days without breaking streak', () {
      // Habit runs only Mon, Wed, Fri
      final schedule = HabitScheduleDto(
        id: 's1',
        habitId: 'h1',
        scheduleType: ScheduleType.specificWeekdays,
        scheduledWeekdays: [Weekday.monday, Weekday.wednesday, Weekday.friday],
        effectiveFrom: DateTime.utc(2026, 1, 1),
      );

      // Mon Mar 2, Wed Mar 4, Fri Mar 6
      final today = DateTime.utc(2026, 3, 8); // Sunday (unscheduled)
      final entries = [
        HabitEntryDto(
          id: '1',
          habitId: 'h1',
          date: DateTime.utc(2026, 3, 2), // Mon
          value: 1.0,
          createdAt: today,
        ),
        HabitEntryDto(
          id: '2',
          habitId: 'h1',
          date: DateTime.utc(2026, 3, 4), // Wed
          value: 1.0,
          createdAt: today,
        ),
        HabitEntryDto(
          id: '3',
          habitId: 'h1',
          date: DateTime.utc(2026, 3, 6), // Fri
          value: 1.0,
          createdAt: today,
        ),
      ];

      final streak = StreakCalculator.currentStreak(
        entries,
        today: today,
        schedule: schedule,
      );
      expect(streak, 3);
    });

    test('allTimeGreatestStreak returns max across multiple separate streaks', () {
      final entries = [
        // Streak of 2
        HabitEntryDto(
          id: '1',
          habitId: 'h1',
          date: DateTime.utc(2026, 1, 1),
          value: 1.0,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
        HabitEntryDto(
          id: '2',
          habitId: 'h1',
          date: DateTime.utc(2026, 1, 2),
          value: 1.0,
          createdAt: DateTime.utc(2026, 1, 2),
        ),
        // Gap on Jan 3, 4
        // Streak of 4
        HabitEntryDto(
          id: '3',
          habitId: 'h1',
          date: DateTime.utc(2026, 1, 5),
          value: 1.0,
          createdAt: DateTime.utc(2026, 1, 5),
        ),
        HabitEntryDto(
          id: '4',
          habitId: 'h1',
          date: DateTime.utc(2026, 1, 6),
          value: 1.0,
          createdAt: DateTime.utc(2026, 1, 6),
        ),
        HabitEntryDto(
          id: '5',
          habitId: 'h1',
          date: DateTime.utc(2026, 1, 7),
          value: 1.0,
          createdAt: DateTime.utc(2026, 1, 7),
        ),
        HabitEntryDto(
          id: '6',
          habitId: 'h1',
          date: DateTime.utc(2026, 1, 8),
          value: 1.0,
          createdAt: DateTime.utc(2026, 1, 8),
        ),
      ];

      final greatest = StreakCalculator.allTimeGreatestStreak(
        entries,
        today: DateTime.utc(2026, 1, 10),
      );
      expect(greatest, 4);
    });

    test('topStreaksInYear returns top streaks sorted by length in target year', () {
      final entries = [
        // 2025 streak of 10
        for (int i = 1; i <= 10; i++)
          HabitEntryDto(
            id: '2025-$i',
            habitId: 'h1',
            date: DateTime.utc(2025, 6, i),
            value: 1.0,
            createdAt: DateTime.utc(2025, 6, i),
          ),
        // 2026 streak of 3
        for (int i = 1; i <= 3; i++)
          HabitEntryDto(
            id: '2026a-$i',
            habitId: 'h1',
            date: DateTime.utc(2026, 1, i),
            value: 1.0,
            createdAt: DateTime.utc(2026, 1, i),
          ),
        // 2026 streak of 5
        for (int i = 10; i <= 14; i++)
          HabitEntryDto(
            id: '2026b-$i',
            habitId: 'h1',
            date: DateTime.utc(2026, 2, i),
            value: 1.0,
            createdAt: DateTime.utc(2026, 2, i),
          ),
      ];

      final top2026 = StreakCalculator.topStreaksInYear(
        entries,
        year: 2026,
        topN: 5,
        today: DateTime.utc(2026, 3, 1),
      );

      // Only 2026 streaks are included
      expect(top2026.length, 2);
      expect(top2026.first.length, 5);
      expect(top2026.first.start, DateTime.utc(2026, 2, 10));
      expect(top2026.first.end, DateTime.utc(2026, 2, 14));
      expect(top2026[1].length, 3);
    });
  });

  group('StreakAnalyticsWidget & HabitDetailScreen Tests (STRAT-01-D)', () {
    testWidgets('renders placeholder when no streaks exist', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreakAnalyticsWidget(
              habit: testHabit,
              entries: const [],
              selectedYear: 2026,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('0 days'), findsNWidgets(2)); // Current and Best both 0
      expect(find.byKey(const Key('no_streaks_placeholder')), findsOneWidget);
      expect(find.text('No streaks yet — start your first one today!'),
          findsOneWidget);
    });

    testWidgets('renders current streak with orange color, best streak, and top list with rank & date range',
        (tester) async {
      final entries = [
        HabitEntryDto(
          id: '1',
          habitId: testHabit.id,
          date: DateTime.now().subtract(const Duration(days: 1)),
          value: 1.0,
          createdAt: DateTime.now(),
        ),
        HabitEntryDto(
          id: '2',
          habitId: testHabit.id,
          date: DateTime.now(),
          value: 1.0,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreakAnalyticsWidget(
              habit: testHabit,
              entries: entries,
              selectedYear: DateTime.now().year,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final currentStreakText = tester.widget<Text>(
        find.byKey(const Key('streak_current_number')),
      );
      expect(currentStreakText.style?.color, equals(AppColors.orange));
      expect(currentStreakText.data, '2 days');

      expect(find.text('All-Time Best'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.textContaining('→'), findsOneWidget);
    });

    testWidgets('HabitDetailScreen renders streaks header and streak analytics widget',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: HabitDetailScreen(
              habitId: testHabit.id,
              initialHabit: testHabit,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('habit_detail_streaks_header')),
          findsOneWidget);
      expect(find.text('Streaks'), findsOneWidget);
      expect(find.byKey(const Key('habit_detail_streaks_widget')),
          findsOneWidget);
    });
  });
}
