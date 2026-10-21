import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/application/providers/providers.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/domain/enums/enums.dart';
import 'package:habit_tracker/presentation/screens/habit_detail/habit_detail_screen.dart';
import 'package:habit_tracker/presentation/theme/app_theme.dart';
import 'package:habit_tracker/presentation/widgets/year_heatmap_widget.dart';

void main() {
  final now = DateTime.now();
  const testColor = Color(0xFFFF7A45);

  group('YearHeatmapWidget Tests (STRAT-01-B)', () {
    testWidgets('renders exactly 365 cells for non-leap year (2025)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: YearHeatmapWidget(
              year: 2025,
              entries: [],
              habitColor: testColor,
              habitType: HabitType.boolean,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final cells = find.byType(HeatmapCell);
      expect(cells, findsNWidgets(365));
    });

    testWidgets('renders exactly 366 cells for leap year (2024)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: YearHeatmapWidget(
              year: 2024,
              entries: [],
              habitColor: testColor,
              habitType: HabitType.boolean,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final cells = find.byType(HeatmapCell);
      expect(cells, findsNWidgets(366));
    });

    testWidgets('calculates correct color intensity for boolean habits',
        (tester) async {
      final entries = [
        HabitEntryDto(
          id: 'e1',
          habitId: 'h1',
          date: DateTime.utc(2025, 5, 10),
          value: 1.0,
          createdAt: DateTime.utc(2025, 5, 10),
        ),
        HabitEntryDto(
          id: 'e2',
          habitId: 'h1',
          date: DateTime.utc(2025, 5, 11),
          value: 0.0,
          createdAt: DateTime.utc(2025, 5, 11),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: YearHeatmapWidget(
              year: 2025,
              entries: entries,
              habitColor: testColor,
              habitType: HabitType.boolean,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final completedCell = tester.widget<HeatmapCell>(
        find.byKey(const Key('heatmap_cell_2025-05-10')),
      );
      expect(completedCell.color, equals(testColor));
      expect(completedCell.tooltip, contains('✅'));

      final missedCell = tester.widget<HeatmapCell>(
        find.byKey(const Key('heatmap_cell_2025-05-11')),
      );
      expect(
          missedCell.color, equals(testColor.withValues(alpha: 0.20)));
      expect(missedCell.tooltip, contains('❌'));

      final noEntryCell = tester.widget<HeatmapCell>(
        find.byKey(const Key('heatmap_cell_2025-05-12')),
      );
      expect(noEntryCell.color,
          equals(AppColors.surface.withValues(alpha: 0.35)));
      expect(noEntryCell.tooltip, contains('No entry'));
    });

    testWidgets('calculates correct color intensity for numeric habits',
        (tester) async {
      final entries = [
        HabitEntryDto(
          id: 'e1',
          habitId: 'h1',
          date: DateTime.utc(2025, 6, 1),
          value: 10.0, // 100% of 10
          createdAt: DateTime.utc(2025, 6, 1),
        ),
        HabitEntryDto(
          id: 'e2',
          habitId: 'h1',
          date: DateTime.utc(2025, 6, 2),
          value: 6.0, // 60% of 10 (>= 50%)
          createdAt: DateTime.utc(2025, 6, 2),
        ),
        HabitEntryDto(
          id: 'e3',
          habitId: 'h1',
          date: DateTime.utc(2025, 6, 3),
          value: 3.0, // 30% of 10 (>= 25%)
          createdAt: DateTime.utc(2025, 6, 3),
        ),
        HabitEntryDto(
          id: 'e4',
          habitId: 'h1',
          date: DateTime.utc(2025, 6, 4),
          value: 1.0, // 10% of 10 (< 25%)
          createdAt: DateTime.utc(2025, 6, 4),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: YearHeatmapWidget(
              year: 2025,
              entries: entries,
              habitColor: testColor,
              habitType: HabitType.numeric,
              target: 10.0,
              unit: 'pages',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final cell100 = tester.widget<HeatmapCell>(
        find.byKey(const Key('heatmap_cell_2025-06-01')),
      );
      expect(cell100.color, equals(testColor));
      expect(cell100.tooltip, contains('10 pages'));

      final cell60 = tester.widget<HeatmapCell>(
        find.byKey(const Key('heatmap_cell_2025-06-02')),
      );
      expect(cell60.color, equals(testColor.withValues(alpha: 0.65)));

      final cell30 = tester.widget<HeatmapCell>(
        find.byKey(const Key('heatmap_cell_2025-06-03')),
      );
      expect(cell30.color, equals(testColor.withValues(alpha: 0.40)));

      final cell10 = tester.widget<HeatmapCell>(
        find.byKey(const Key('heatmap_cell_2025-06-04')),
      );
      expect(cell10.color, equals(testColor.withValues(alpha: 0.20)));
    });

    testWidgets('horizontal scroll works and month labels are rendered',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: YearHeatmapWidget(
              year: 2026,
              entries: [],
              habitColor: testColor,
              habitType: HabitType.boolean,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('year_heatmap_scroll_view')), findsOneWidget);
      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('Less'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
    });
  });

  group('HabitDetailScreen Year Switcher & Integration (STRAT-01-B)', () {
    final habit = HabitDto(
      id: 'habit-year-test',
      name: 'Daily Workout',
      type: HabitType.boolean,
      colorHex: '#FF7A45',
      iconName: 'fitness_center',
      createdAt: DateTime.now(),
      isArchived: false,
    );

    testWidgets('Year switcher increments and decrements, disabling next year button for current year',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: HabitDetailScreen(
              habitId: habit.id,
              initialHabit: habit,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('This Year'), findsOneWidget);
      expect(find.text(now.year.toString()), findsOneWidget);

      // Next year button should be disabled for current year
      final nextBtn = tester.widget<IconButton>(
        find.byKey(const Key('heatmap_next_year_btn')),
      );
      expect(nextBtn.onPressed, isNull);

      // Tap prev year button
      await tester.tap(find.byKey(const Key('heatmap_prev_year_btn')));
      await tester.pumpAndSettle();

      final prevYear = now.year - 1;
      expect(find.text('Year $prevYear'), findsOneWidget);
      expect(find.text(prevYear.toString()), findsOneWidget);

      // Now next year button should be enabled
      final nextBtnEnabled = tester.widget<IconButton>(
        find.byKey(const Key('heatmap_next_year_btn')),
      );
      expect(nextBtnEnabled.onPressed, isNotNull);

      // Tap next year button to return to current year
      await tester.tap(find.byKey(const Key('heatmap_next_year_btn')));
      await tester.pumpAndSettle();

      expect(find.text('This Year'), findsOneWidget);
      expect(find.text(now.year.toString()), findsOneWidget);
    });

    testWidgets('One-time tasks omit the YearHeatmapWidget', (tester) async {
      final oneTimeTask = HabitDto(
        id: 'task-test',
        name: 'Submit Proposal',
        type: HabitType.boolean,
        colorHex: '#FF7A45',
        iconName: 'task',
        isOneTime: true,
        createdAt: DateTime.now(),
        isArchived: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: HabitDetailScreen(
              habitId: oneTimeTask.id,
              initialHabit: oneTimeTask,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Submit Proposal'), findsOneWidget);
      expect(find.byType(YearHeatmapWidget), findsNothing);
      expect(find.byKey(const Key('heatmap_year_title')), findsNothing);
    });
  });
}
