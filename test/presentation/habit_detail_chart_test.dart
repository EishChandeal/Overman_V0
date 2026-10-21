import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/domain/enums/enums.dart';
import 'package:habit_tracker/presentation/screens/habit_detail/habit_detail_screen.dart';
import 'package:habit_tracker/presentation/widgets/habit_detail_chart.dart';

void main() {
  const testColor = Color(0xFF216CCF);

  final booleanHabit = HabitDto(
    id: 'bool-habit-1',
    name: 'Morning Run',
    type: HabitType.boolean,
    colorHex: '#216CCF',
    iconName: 'directions_run',
    createdAt: DateTime.now(),
    isArchived: false,
  );

  final numericHabit = HabitDto(
    id: 'num-habit-1',
    name: 'Water Intake',
    type: HabitType.numeric,
    unit: 'glasses',
    targetValue: 8.0,
    colorHex: '#216CCF',
    iconName: 'local_drink',
    createdAt: DateTime.now(),
    isArchived: false,
  );

  group('HabitDetailChart Widget Tests (STRAT-01-C)', () {
    testWidgets('renders not enough data placeholder when entries < 2',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HabitDetailChart(
              habit: booleanHabit,
              entries: const [],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('chart_not_enough_data')), findsOneWidget);
      expect(find.text('Not enough data yet — keep going!'), findsOneWidget);
      expect(find.byType(BarChart), findsNothing);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('renders WeeklyCompletionBarChart with perfect week goal line for boolean habit',
        (tester) async {
      final entries = [
        HabitEntryDto(
          id: 'e1',
          habitId: booleanHabit.id,
          date: DateTime.now().subtract(const Duration(days: 1)),
          value: 1.0,
          createdAt: DateTime.now(),
        ),
        HabitEntryDto(
          id: 'e2',
          habitId: booleanHabit.id,
          date: DateTime.now(),
          value: 1.0,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HabitDetailChart(
              habit: booleanHabit,
              entries: entries,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(WeeklyCompletionBarChart), findsOneWidget);
      expect(find.byType(BarChart), findsOneWidget);

      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      expect(barChart.data.extraLinesData.horizontalLines, isNotEmpty);
      final goalLine = barChart.data.extraLinesData.horizontalLines.first;
      expect(goalLine.y, 7.0); // Daily habit default 7 days/week
      expect(goalLine.dashArray, isNotNull);
    });

    testWidgets('renders NumericProgressLineChart with dashed target line for numeric habit',
        (tester) async {
      final entries = [
        HabitEntryDto(
          id: 'e1',
          habitId: numericHabit.id,
          date: DateTime.now().subtract(const Duration(days: 2)),
          value: 6.0,
          createdAt: DateTime.now(),
        ),
        HabitEntryDto(
          id: 'e2',
          habitId: numericHabit.id,
          date: DateTime.now(),
          value: 8.0,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HabitDetailChart(
              habit: numericHabit,
              entries: entries,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NumericProgressLineChart), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);

      final lineChart = tester.widget<LineChart>(find.byType(LineChart));
      expect(lineChart.data.extraLinesData.horizontalLines, isNotEmpty);
      final targetLine = lineChart.data.extraLinesData.horizontalLines.first;
      expect(targetLine.y, 8.0);
      expect(targetLine.dashArray, isNotNull);
    });

    testWidgets('HabitDetailScreen integrates performance section and renders chart',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: HabitDetailScreen(
              habitId: numericHabit.id,
              initialHabit: numericHabit,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('habit_detail_performance_header')),
          findsOneWidget);
      expect(find.text('Performance'), findsOneWidget);
      expect(find.byKey(const Key('habit_detail_chart')), findsOneWidget);
      expect(find.byKey(const Key('chart_not_enough_data')), findsOneWidget);
    });
  });
}
