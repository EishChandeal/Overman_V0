import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/application/providers/providers.dart';
import 'package:habit_tracker/data/database/app_database.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/domain/enums/enums.dart';
import 'package:habit_tracker/domain/services/statistics_service.dart';
import 'package:habit_tracker/presentation/widgets/statistics_panel.dart';
import 'package:objectbox/objectbox.dart';

void main() {
  late Store testStore;

  setUpAll(() async {
    testStore = await AppDatabase.openStore();
  });

  tearDownAll(() {
    AppDatabase.closeStore();
  });

  testWidgets(
      'StatisticsPanel renders accurate completion percentage and missed days based on activeDays formula',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final createdAt = DateTime.now().subtract(const Duration(days: 3)); // 4 active days (0, 1, 2, 3)

    final habit = HabitDto(
      id: 'h_stat_test',
      name: 'Daily Workout',
      type: HabitType.boolean,
      colorHex: '#216CCF',
      iconName: 'fitness_center',
      isArchived: false,
      createdAt: createdAt,
    );

    // Only 1 completed entry out of 4 days => 25% completion, 1 completed, 3 missed days
    final entries = [
      HabitEntryDto(
        id: 'e1',
        habitId: 'h_stat_test',
        date: createdAt,
        value: 1.0,
        createdAt: createdAt,
      ),
    ];

    const dummyStats = StatisticsResult(
      average: 1.0,
      sum: 1.0,
      completionRate: 1.0, // legacy raw calculation on entries only
      totalTrackedDays: 1,
      totalMissedDays: 0,
      bestValue: 1.0,
      weeklyAverages: {},
    );

    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final oneYearAgo = todayUtc.subtract(const Duration(days: 365));
    final range = DateRange(start: oneYearAgo, end: todayUtc);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
          habitEntriesProvider('h_stat_test').overrideWith((ref) => Stream.value(entries)),
          activeScheduleProvider('h_stat_test').overrideWith((ref) async => null),
          habitStatisticsProvider('h_stat_test', range).overrideWith((ref) async => dummyStats),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: StatisticsPanel(habit: habit),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Completion Rate shows 25% (not 100%)
    expect(find.text('Completion Rate'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);

    // Verify Completed Days shows 1
    expect(find.text('Completed Days'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    // Verify Missed Days shows 3 (not 0)
    expect(find.text('Missed Days'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });
}
