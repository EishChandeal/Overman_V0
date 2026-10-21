import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/application/providers/providers.dart';
import 'package:habit_tracker/data/database/app_database.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/data/repositories/repositories.dart';
import 'package:habit_tracker/domain/enums/enums.dart';
import 'package:habit_tracker/presentation/screens/insights/insights_screen.dart';
import 'package:objectbox/objectbox.dart';

void main() {
  late Store testStore;

  setUpAll(() async {
    testStore = await AppDatabase.openStore();
  });

  tearDownAll(() {
    AppDatabase.closeStore();
  });

  testWidgets('InsightsScreen renders empty state when no active habits exist',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
          habitListProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: InsightsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Insights & Analytics'), findsOneWidget);
    expect(
      find.text('No habits created yet. Start tracking to see insights.'),
      findsOneWidget,
    );
  });

  testWidgets('InsightsScreen renders Common Man rank card and stat row with 5 app opens',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 1200 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final habit = HabitDto(
      id: 'h_test1',
      name: 'Morning Meditation',
      type: HabitType.boolean,
      colorHex: '#216CCF',
      iconName: 'self_improvement',
      isArchived: false,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
          habitListProvider.overrideWith((ref) => Stream.value([habit])),
          totalDaysOpenedProvider.overrideWith((ref) async => 5),
          currentOpenStreakProvider.overrideWith((ref) async => 3),
        ],
        child: const MaterialApp(
          home: InsightsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('insights_user_rank_card')), findsOneWidget);
    expect(find.text('Common Man'), findsOneWidget);
    expect(find.text("You've opened the app 5 days"), findsOneWidget);
    expect(find.text('5 days total'), findsOneWidget);
    expect(find.text('3 day streak'), findsOneWidget);
    expect(find.text('Morning Meditation'), findsOneWidget);
  });

  testWidgets('InsightsScreen renders Übermensch card when conditions met',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 1200 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final habit = HabitDto(
      id: 'h_test2',
      name: 'Cold Shower',
      type: HabitType.boolean,
      colorHex: '#9B59B6',
      iconName: 'shower',
      isArchived: false,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
          habitListProvider.overrideWith((ref) => Stream.value([habit])),
          totalDaysOpenedProvider.overrideWith((ref) async => 105),
          currentOpenStreakProvider.overrideWith((ref) async => 45),
          userRankProvider.overrideWith((ref) async => UserRank.uebermensch),
        ],
        child: const MaterialApp(
          home: InsightsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Übermensch'), findsOneWidget);
    expect(find.text("You've opened the app 105 days"), findsOneWidget);
    expect(find.text('All habits followed with excellence'), findsOneWidget);
    expect(find.text('105 days total'), findsOneWidget);
    expect(find.text('45 day streak'), findsOneWidget);
  });

  testWidgets('InsightsScreen renders calculated completion rate (non-100% when missed days exist)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 1200 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final createdAt = DateTime.now().subtract(const Duration(days: 3)); // 4 active days (0, 1, 2, 3)
    final habit = HabitDto(
      id: 'h_calc',
      name: 'Reading',
      type: HabitType.boolean,
      colorHex: '#FF9500',
      iconName: 'book',
      isArchived: false,
      createdAt: createdAt,
    );

    // 2 entries completed out of 4 days => 50% completion
    final entries = [
      HabitEntryDto(
        id: 'e1',
        habitId: 'h_calc',
        date: createdAt,
        value: 1.0,
        createdAt: createdAt,
      ),
      HabitEntryDto(
        id: 'e2',
        habitId: 'h_calc',
        date: createdAt.add(const Duration(days: 1)),
        value: 1.0,
        createdAt: createdAt.add(const Duration(days: 1)),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
          habitListProvider.overrideWith((ref) => Stream.value([habit])),
          habitEntriesProvider('h_calc').overrideWith((ref) => Stream.value(entries)),
          activeScheduleProvider('h_calc').overrideWith((ref) async => null), // daily
          totalDaysOpenedProvider.overrideWith((ref) async => 10),
          currentOpenStreakProvider.overrideWith((ref) async => 2),
        ],
        child: const MaterialApp(
          home: InsightsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reading'), findsOneWidget);
    expect(find.text('50% completion'), findsOneWidget);
  });

  testWidgets('InsightsScreen only displays regular habits in performance list and shows tasks summary section below',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 1400 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final regularHabit = HabitDto(
      id: 'h_regular',
      name: 'Morning Meditation',
      type: HabitType.boolean,
      colorHex: '#216CCF',
      iconName: 'self_improvement',
      isOneTime: false,
      isArchived: false,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    );

    final pendingTask = HabitDto(
      id: 't_pending',
      name: 'Buy Groceries Task',
      type: HabitType.boolean,
      colorHex: '#FF7A45',
      iconName: 'task_alt',
      isOneTime: true,
      completedAt: null,
      isArchived: false,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    );

    final completedTask = HabitDto(
      id: 't_completed',
      name: 'Call Dentist Task',
      type: HabitType.boolean,
      colorHex: '#FF7A45',
      iconName: 'task_alt',
      isOneTime: true,
      completedAt: DateTime.now().subtract(const Duration(days: 1)),
      isArchived: false,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
          habitListProvider.overrideWith(
            (ref) => Stream.value([regularHabit, pendingTask, completedTask]),
          ),
          totalDaysOpenedProvider.overrideWith((ref) async => 5),
          currentOpenStreakProvider.overrideWith((ref) async => 3),
        ],
        child: const MaterialApp(
          home: InsightsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Regular habit is shown in Habit Performance
    expect(find.text('Morning Meditation'), findsOneWidget);

    // 2. One-time tasks are NOT shown as habit performance cards or task items
    expect(find.text('Buy Groceries Task'), findsNothing);
    expect(find.text('Call Dentist Task'), findsNothing);

    // 3. Active habits overview shows only regular habits count (1, not 3)
    expect(find.text('Active Habits'), findsOneWidget);
    // Find the tile value next to 'Active Habits'
    final activeHabitTile = find.ancestor(
      of: find.text('Active Habits'),
      matching: find.byType(Container),
    );
    expect(
      find.descendant(of: activeHabitTile, matching: find.text('1')),
      findsOneWidget,
    );

    // 4. Tasks section exists just below Habit Performance
    expect(find.text('TASKS'), findsOneWidget);
    expect(find.byKey(const Key('insights_tasks_summary_card')), findsOneWidget);

    final tasksCard = find.byKey(const Key('insights_tasks_summary_card'));
    // Created: 2 tasks total
    expect(find.descendant(of: tasksCard, matching: find.text('Created')), findsOneWidget);
    expect(find.descendant(of: tasksCard, matching: find.text('2')), findsOneWidget);

    // Completed: 1 task completed
    expect(find.descendant(of: tasksCard, matching: find.text('Completed')), findsOneWidget);
    expect(find.descendant(of: tasksCard, matching: find.text('1')), findsOneWidget);

    // Completion rate: 50%
    expect(find.descendant(of: tasksCard, matching: find.text('Completion Rate')), findsOneWidget);
    expect(find.descendant(of: tasksCard, matching: find.text('50%')), findsOneWidget);
  });
}
