import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:habit_tracker/main.dart';
import 'package:habit_tracker/presentation/theme/app_theme.dart';
import 'package:habit_tracker/presentation/widgets/habit_card.dart';
import 'package:habit_tracker/presentation/screens/add/add_habit_screen.dart';

import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/domain/enums/enums.dart';

import 'package:habit_tracker/presentation/screens/history/history_screen.dart';
import 'package:habit_tracker/presentation/screens/settings/settings_screen.dart';
import 'package:habit_tracker/presentation/screens/ai/ai_settings_screen.dart';
import 'package:habit_tracker/presentation/screens/ai/ai_chat_screen.dart';
import 'package:habit_tracker/presentation/screens/ai/ai_history_screen.dart';
import 'package:habit_tracker/presentation/screens/ai/ai_personas.dart';
import 'package:habit_tracker/presentation/screens/home/home_screen.dart';
import 'package:habit_tracker/presentation/screens/splash/splash_screen.dart';
import 'package:habit_tracker/presentation/navigation/app_router.dart';
import 'package:habit_tracker/presentation/widgets/details_panel.dart';

import 'package:habit_tracker/presentation/widgets/notes_panel.dart';


import 'package:habit_tracker/data/database/app_database.dart';
import 'package:habit_tracker/data/repositories/repositories.dart';
import 'package:habit_tracker/application/providers/providers.dart';
import 'package:objectbox/objectbox.dart';

void main() {
  late Store testStore;

  setUpAll(() async {
    testStore = await AppDatabase.openStore();
  });

  tearDownAll(() {
    AppDatabase.closeStore();
  });
  testWidgets('HabitTrackerApp renders HomeScreen with dark theme and header controls',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HabitTrackerApp(initialRoute: AppRoutes.home),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify today's date formatted is present in the header
    final formattedDate = DateFormat('d MMM').format(DateTime.now());
    expect(find.text(formattedDate), findsOneWidget);

    // Verify Add and Settings icons are present in the header
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    // Verify dark theme values are active
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, AppColors.background);

    final theme = Theme.of(tester.element(find.byIcon(Icons.add)));
    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.colorScheme.primary, AppColors.blue);
    expect(theme.colorScheme.surface, AppColors.surface);
  });

  testWidgets('HabitCard renders boolean habit details and toggles completion',
      (WidgetTester tester) async {
    bool tappedCompletion = false;

    final habit = HabitDto(
      id: 'test-h1',
      name: 'Morning Jog',
      type: HabitType.boolean,
      colorHex: '#216CCF',
      iconName: 'directions_run',
      createdAt: DateTime.now().toUtc(),
      isArchived: false,
    );

    final item = HabitDayStatus(
      habit: habit,
      entry: null,
      isScheduledToday: true,
      status: DayStatus.missed,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: HabitCard(
              item: item,
              onCompletionTap: () => tappedCompletion = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Morning Jog'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);

    // Tap completion control
    await tester.tap(find.text('—'));
    await tester.pump();
    expect(tappedCompletion, isTrue);
  });

  testWidgets('HabitCard renders numeric habit with logged value and unit',
      (WidgetTester tester) async {
    final habit = HabitDto(
      id: 'test-h2',
      name: 'Drink Water',
      type: HabitType.numeric,
      unit: 'ml',
      targetValue: 2000,
      colorHex: '#216CCF',
      iconName: 'water_drop',
      createdAt: DateTime.now().toUtc(),
      isArchived: false,
    );

    final entry = HabitEntryDto(
      id: 'entry-1',
      habitId: 'test-h2',
      date: DateTime.now().toUtc(),
      value: 1500,
      createdAt: DateTime.now().toUtc(),
    );

    final item = HabitDayStatus(
      habit: habit,
      entry: entry,
      isScheduledToday: true,
      status: DayStatus.partiallyMet,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: HabitCard(
              item: item,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Drink Water'), findsOneWidget);
    expect(find.text('1500'), findsOneWidget);
    expect(find.text('ml'), findsWidgets);
  });

  testWidgets('Tapping Add button on HomeScreen navigates to AddHabitScreen and back',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 917 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: HabitTrackerApp(initialRoute: AppRoutes.home),
      ),
    );

    await tester.pump();

    // Tap the Add button (+)
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Verify AddHabitScreen is visible
    expect(find.text('New Habit'), findsOneWidget);
    expect(find.text('HABIT NAME'), findsOneWidget);
    expect(find.text('TRACKING TYPE'), findsOneWidget);

    // Tap back arrow to return to HomeScreen
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('New Habit'), findsNothing);
  });

  testWidgets('AddHabitScreen validates empty name and toggles numeric fields',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 917 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AddHabitScreen(),
        ),
      ),
    );

    await tester.pump();

    // Tap Create Habit without entering a name
    await tester.scrollUntilVisible(
      find.text('Create Habit'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Create Habit'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // Scroll up to check validation error
    await tester.scrollUntilVisible(
      find.text('Please enter a habit name'),
      -100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Please enter a habit name'), findsOneWidget);

    // By default numeric fields are not shown (boolean selected)
    expect(find.text('TARGET VALUE'), findsNothing);

    // Switch to Numeric tracking type
    await tester.scrollUntilVisible(
      find.text('Numeric'),
      -100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Numeric'));
    await tester.pump();

    // Now numeric fields should be present
    expect(find.text('TARGET VALUE'), findsOneWidget);
    expect(find.text('UNIT'), findsOneWidget);
  });

  testWidgets('HabitCard expands on tap and supports circular panel sequence',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 917 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final habit = HabitDto(
      id: 'test-expand-bool',
      name: 'Read Books',
      type: HabitType.boolean,
      colorHex: '#216CCF',
      iconName: 'book',
      createdAt: DateTime.now().toUtc(),
      isArchived: false,
    );

    final item = HabitDayStatus(
      habit: habit,
      entry: null,
      isScheduledToday: true,
      status: DayStatus.notTracked,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: HabitCard(item: item),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // Initially collapsed: panel title HEATMAP is not present
    expect(find.text('HEATMAP'), findsNothing);

    // Tap habit card to expand
    await tester.tap(find.text('Read Books').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    // Panel title HEATMAP should now be visible
    expect(find.text('HEATMAP'), findsOneWidget);
    expect(find.text('Current Streak'), findsOneWidget);
    expect(find.text('Best Streak'), findsOneWidget);

    // Tap next panel button (>)
    await tester.tap(find.byTooltip('Next panel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    // Panel should switch to STATISTICS
    expect(find.text('STATISTICS'), findsOneWidget);
    expect(find.text('Completion Rate'), findsOneWidget);

    // Tap next panel button (>)
    await tester.tap(find.byTooltip('Next panel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    // Panel should switch to NOTES
    expect(find.text('NOTES'), findsOneWidget);
    expect(find.text('No notes yet. Hold the card to add one.'), findsOneWidget);

    // Tap next panel button (>)
    await tester.tap(find.byTooltip('Next panel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    // Panel should switch to DETAILS (for boolean habits: Heatmap -> Statistics -> Notes -> Details)
    expect(find.text('DETAILS'), findsOneWidget);
    expect(find.text('Start Date'), findsOneWidget);

    // Tap next panel button (>) to complete the circle back to HEATMAP
    await tester.tap(find.byTooltip('Next panel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('HEATMAP'), findsOneWidget);

    // Tap habit name again to collapse
    await tester.tap(find.text('Read Books').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('HEATMAP'), findsNothing);

    // Reopen collapsed card: must reset to HEATMAP
    await tester.tap(find.text('Read Books').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('HEATMAP'), findsOneWidget);
  });

  testWidgets('HabitCard for numeric habit includes Trend Graph in panel sequence',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 917 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final habit = HabitDto(
      id: 'test-expand-num',
      name: 'Pushups',
      type: HabitType.numeric,
      unit: 'reps',
      targetValue: 50,
      colorHex: '#FF7A45',
      iconName: 'fitness_center',
      createdAt: DateTime.now().toUtc(),
      isArchived: false,
    );

    final item = HabitDayStatus(
      habit: habit,
      entry: null,
      isScheduledToday: true,
      status: DayStatus.notTracked,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: HabitCard(item: item),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // Tap card to expand
    await tester.tap(find.text('Pushups'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    // 0: HEATMAP
    expect(find.text('HEATMAP'), findsOneWidget);

    // 1: Next -> STATISTICS
    await tester.tap(find.byTooltip('Next panel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.text('STATISTICS'), findsOneWidget);
    expect(find.text('Daily Average'), findsOneWidget);

    // 2: Next -> TREND GRAPH (numeric only)
    await tester.tap(find.byTooltip('Next panel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.text('TREND GRAPH'), findsOneWidget);
    expect(find.text('Last 7 Days'), findsOneWidget);

    // 3: Next -> NOTES
    await tester.tap(find.byTooltip('Next panel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.text('NOTES'), findsOneWidget);

    // 4: Next -> DETAILS
    await tester.tap(find.byTooltip('Next panel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.text('DETAILS'), findsOneWidget);
  });

  testWidgets('Tapping History button on HomeScreen navigates to HistoryScreen and back',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 917 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
        ],
        child: const HabitTrackerApp(initialRoute: AppRoutes.home),
      ),
    );

    await tester.pump();

    // Tap History button (which displays today's date formatted, e.g. 14 Oct)
    final formattedDate = DateFormat('d MMM').format(DateTime.now());
    await tester.tap(find.text(formattedDate));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Verify HistoryScreen is active
    expect(find.text('History'), findsOneWidget);
    expect(find.byTooltip('Jump to today'), findsOneWidget);

    // Tap back button
    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify back on HomeScreen
    expect(find.text('History'), findsNothing);
    expect(find.text(formattedDate), findsOneWidget);
  });

  testWidgets('Tapping Settings button navigates to SettingsScreen, triggers export, and visits Insights',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 917 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
        ],
        child: const HabitTrackerApp(initialRoute: AppRoutes.home),
      ),
    );

    await tester.pump();

    // Tap Settings button in header
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Verify SettingsScreen is active
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('NAVIGATION SHORTCUTS'), findsOneWidget);
    expect(find.text('DATA EXPORT'), findsOneWidget);

    // Tap Export to CSV
    await tester.tap(find.text('Export to CSV'));
    await tester.pump();
    expect(find.byType(SnackBar), findsWidgets);

    // Tap Insights & Analytics shortcut from Settings
    await tester.tap(find.text('Insights & Analytics'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Verify InsightsScreen is active
    expect(find.widgetWithText(AppBar, 'Insights & Analytics'), findsOneWidget);

    // Tap back button to return to SettingsScreen
    await tester.tap(find.byTooltip('Back').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Settings'), findsOneWidget);

    // Tap back button to return to HomeScreen
    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('Tapping Insights action in HistoryScreen navigates to InsightsScreen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 917 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HistoryScreen(),
        ),
      ),
    );

    await tester.pump();

    // Tap View Insights action in HistoryScreen AppBar
    await tester.tap(find.byTooltip('View Insights'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Verify InsightsScreen is pushed
    expect(find.widgetWithText(AppBar, 'Insights & Analytics'), findsOneWidget);
  });

  testWidgets('Long-press habit enters selection mode and exposes Edit/Delete in header row',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 917 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = HabitRepository(testStore, HabitScheduleRepository(testStore));
    await repo.createHabit(
      name: 'Morning Meditation',
      type: HabitType.boolean,
      colorHex: '#216CCF',
      iconName: 'check',
      scheduleType: ScheduleType.daily,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
        ],
        child: const HabitTrackerApp(initialRoute: AppRoutes.home),
      ),
    );

    await tester.pumpAndSettle();

    // Verify habit appears
    expect(find.text('Morning Meditation'), findsOneWidget);

    // Long press on habit card
    await tester.longPress(find.text('Morning Meditation'));
    await tester.pumpAndSettle();

    // Selection mode active in top header row: 4 square-like containers (Close, Note, Edit, Delete)
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byIcon(Icons.note_alt_outlined), findsNWidgets(2));
    expect(find.text('Close'), findsOneWidget);
    expect(find.text('Note'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    // Tap Note button to verify note sheet design opens
    await tester.tap(find.text('Note'));
    await tester.pumpAndSettle();
    final todayNoteHeader = 'Note for ${DateFormat('E, d MMM').format(DateTime.now())}';
    expect(find.text(todayNoteHeader), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Save'), findsOneWidget);

    // Close note sheet
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Tap Close (cross icon button) to deselect habit
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    // Selection mode exited, normal header restored
    expect(find.text('Close'), findsNothing);
    expect(find.text('Note'), findsNothing);
    final formattedDate = DateFormat('d MMM').format(DateTime.now());
    expect(find.text(formattedDate), findsOneWidget);
  });

  testWidgets('Selecting habit and tapping Edit prepopulates form and persists changes',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 917 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = HabitRepository(testStore, HabitScheduleRepository(testStore));
    await repo.createHabit(
      name: 'Evening Read',
      type: HabitType.boolean,
      colorHex: '#216CCF',
      iconName: 'check',
      scheduleType: ScheduleType.daily,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
        ],
        child: const HabitTrackerApp(initialRoute: AppRoutes.home),
      ),
    );

    await tester.pumpAndSettle();

    // Long-press to select
    await tester.longPress(find.text('Evening Read'));
    await tester.pumpAndSettle();

    // Tap Edit in the selection header
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    // Verify Edit Habit screen opened and pre-filled
    expect(find.widgetWithText(AppBar, 'Edit Habit'), findsOneWidget);
    expect(find.text('Evening Read'), findsWidgets);
    expect(find.text('Save Changes'), findsOneWidget);

    // Edit habit name
    await tester.enterText(find.widgetWithText(TextFormField, 'Evening Read'), 'Evening Study');
    await tester.pumpAndSettle();

    // Tap Save Changes
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    // Returned to home screen, habit name updated
    expect(find.text('Evening Study'), findsOneWidget);
  });

  testWidgets('Selecting habit and tapping Delete shows confirmation dialog and removes habit',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 917 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = HabitRepository(testStore, HabitScheduleRepository(testStore));
    await repo.createHabit(
      name: 'Temporary Habit',
      type: HabitType.boolean,
      colorHex: '#216CCF',
      iconName: 'check',
      scheduleType: ScheduleType.daily,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
        ],
        child: const HabitTrackerApp(initialRoute: AppRoutes.home),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Temporary Habit'), findsOneWidget);

    // Long press to select
    await tester.longPress(find.text('Temporary Habit'));
    await tester.pumpAndSettle();

    // Tap Delete in selection header
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Verify confirmation dialog
    expect(find.text('Delete Habit'), findsOneWidget);
    expect(find.textContaining('Are you sure you want to delete "Temporary Habit"?'), findsOneWidget);

    // Tap Delete in dialog
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    // Habit is removed and confirmation snackbar shown
    expect(find.text('Temporary Habit'), findsNothing);
    expect(find.text('Deleted habit "Temporary Habit"'), findsOneWidget);
  });

  testWidgets('DetailsPanel exposes direct Edit and Delete buttons on expanded habit',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 917 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = HabitRepository(testStore, HabitScheduleRepository(testStore));
    await repo.createHabit(
      name: 'Deep Breathing',
      type: HabitType.boolean,
      colorHex: '#216CCF',
      iconName: 'check',
      scheduleType: ScheduleType.daily,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
        ],
        child: const HabitTrackerApp(initialRoute: AppRoutes.home),
      ),
    );

    await tester.pumpAndSettle();

    // Tap card to expand
    await tester.tap(find.text('Deep Breathing'));
    await tester.pumpAndSettle();

    // Navigate panels: Heatmap -> Statistics -> Notes -> Details
    await tester.tap(find.byTooltip('Next panel'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next panel'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next panel'));
    await tester.pumpAndSettle();

    // Verify Details panel buttons
    expect(find.widgetWithText(OutlinedButton, 'Edit'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Delete'), findsOneWidget);
  });

  testWidgets(
      'AddHabitScreen toggle switches between Habit and One-time Task and animates Schedule',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AddHabitScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Defaults to "Habit"
    expect(find.text('Habit'), findsOneWidget);
    expect(find.text('One-time Task'), findsOneWidget);
    expect(find.text('SCHEDULE'), findsOneWidget);

    // Tap "One-time Task"
    await tester.tap(find.text('One-time Task'));
    await tester.pumpAndSettle();

    // Schedule section is collapsed/hidden
    expect(find.text('SCHEDULE'), findsNothing);
    expect(find.text('TASK NAME'), findsOneWidget);

    // Tap back to "Habit"
    await tester.tap(find.text('Habit'));
    await tester.pumpAndSettle();

    expect(find.text('SCHEDULE'), findsOneWidget);
    expect(find.text('HABIT NAME'), findsOneWidget);
  });

  testWidgets(
      'One-time task card renders badge, skips Heatmap panel, and applies strikethrough when completed',
      (WidgetTester tester) async {
    final habit = HabitDto(
      id: 'task-1',
      name: 'File Taxes',
      type: HabitType.boolean,
      colorHex: '#216CCF',
      iconName: 'check',
      isOneTime: true,
      completedAt: DateTime.now().toUtc(),
      createdAt: DateTime.now().toUtc(),
      isArchived: false,
    );

    final item = HabitDayStatus(
      habit: habit,
      entry: null,
      isScheduledToday: true,
      status: DayStatus.met,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: HabitCard(item: item),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify "One-time" badge is rendered
    expect(find.text('One-time'), findsOneWidget);
    expect(find.text('File Taxes'), findsOneWidget);

    // Verify strikethrough styling and 0.5 opacity
    final textWidget = tester.widget<Text>(find.text('File Taxes'));
    expect(textWidget.style?.decoration, TextDecoration.lineThrough);
    final opacityWidget = tester.widget<Opacity>(find.byType(Opacity).first);
    expect(opacityWidget.opacity, 0.5);

    // Tap to expand
    await tester.tap(find.text('File Taxes'));
    await tester.pumpAndSettle();

    // Heatmap should NOT be present; Details is shown directly
    expect(find.text('HEATMAP'), findsNothing);
    expect(find.text('DETAILS'), findsOneWidget);
    expect(find.text('Task Type'), findsOneWidget);
    expect(find.text('One-time Task'), findsOneWidget);
  });

  testWidgets(
      'AddHabitScreen displays description field below icon picker and saves description',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddHabitScreen()),
                ),
                child: const Text('Open Add Screen'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Add Screen'));
    await tester.pumpAndSettle();

    // Verify description field is present below icon picker
    expect(find.text('DESCRIPTION (OPTIONAL)'), findsOneWidget);
    expect(find.text('Add a reason or description (optional)'), findsOneWidget);

    // Enter habit name
    await tester.enterText(find.byType(TextFormField).first, 'Meditation Habit');
    await tester.pumpAndSettle();

    // Enter description
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Add a reason or description (optional)'),
      'Calm the mind each morning',
    );
    await tester.pumpAndSettle();

    // Tap Save / Create Habit button
    await tester.tap(find.text('Create Habit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Returned to Open Add Screen
    expect(find.text('Open Add Screen'), findsOneWidget);

    // Verify habit persisted with description
    final habitRepo = HabitRepository(testStore, HabitScheduleRepository(testStore));
    final habits = await habitRepo.getAllHabits();
    final created = habits.firstWhere((h) => h.name == 'Meditation Habit');
    expect(created.description, 'Calm the mind each morning');
  });

  testWidgets(
      'DetailsPanel renders habit name and italic description when present, omits when null',
      (WidgetTester tester) async {
    final habitWithDesc = HabitDto(
      id: 'h-desc-1',
      name: 'Morning Workout',
      type: HabitType.boolean,
      colorHex: '#216CCF',
      iconName: 'fitness',
      description: 'Strengthen body and sharpen discipline.',
      createdAt: DateTime.utc(2026, 1, 1),
      isArchived: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: DetailsPanel(habit: habitWithDesc),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Morning Workout'), findsOneWidget);
    expect(find.text('Strengthen body and sharpen discipline.'), findsOneWidget);

    // Verify italic style
    final descText = tester.widget<Text>(find.text('Strengthen body and sharpen discipline.'));
    expect(descText.style?.fontStyle, FontStyle.italic);

    // Now test with null description
    final habitWithoutDesc = habitWithDesc.copyWith(description: null);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: DetailsPanel(habit: habitWithoutDesc),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Morning Workout'), findsOneWidget);
    expect(find.text('Strengthen body and sharpen discipline.'), findsNothing);
  });

  testWidgets(
      'HabitCard displays notepad icon only when selected and tapping it opens DayNoteBottomSheet',
      (WidgetTester tester) async {
    final habit = HabitDto(
      id: 'h-note-test',
      name: 'Journaling',
      type: HabitType.boolean,
      colorHex: '#216CCF',
      iconName: 'book',
      createdAt: DateTime.now().toUtc(),
      isArchived: false,
    );
    final item = HabitDayStatus(
      habit: habit,
      entry: null,
      isScheduledToday: true,
      status: DayStatus.notTracked,
    );

    // 1. When not selected: notepad icon does NOT appear
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: HabitCard(item: item, isSelected: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Day note'), findsNothing);

    // 2. When selected: notepad icon DOES appear
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: HabitCard(item: item, isSelected: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Day note'), findsOneWidget);

    // 3. Tap notepad icon -> opens DayNoteBottomSheet
    await tester.tap(find.byTooltip('Day note'));
    await tester.pumpAndSettle();

    final todayFormatted = DateFormat('E, d MMM').format(DateTime.now());
    expect(find.text('Note for $todayFormatted'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Save'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);

    // Enter note text and tap Save
    await tester.enterText(find.byType(TextField), 'Great journaling session today.');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify note persisted via DayNoteRepository
    final noteRepo = DayNoteRepository(testStore);
    final notes = await noteRepo.getNotesForHabit('h-note-test');
    expect(notes, hasLength(1));
    expect(notes.first.note, 'Great journaling session today.');
  });

  testWidgets(
      'NotesPanel displays placeholder when empty and notes list when notes exist',
      (WidgetTester tester) async {
    final noteRepo = DayNoteRepository(testStore);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
          dayNoteRepositoryProvider.overrideWith((ref) async => noteRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: NotesPanel(habitId: 'habit-empty-notes'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No notes yet. Hold the card to add one.'), findsOneWidget);

    // Add notes to repository
    await noteRepo.upsertNote(
      DayNoteDto(
        id: 'n-1',
        habitId: 'habit-with-notes',
        date: DateTime.utc(2026, 10, 20),
        note: 'Completed 10 km run today!',
        createdAt: DateTime.utc(2026, 10, 20),
        updatedAt: DateTime.utc(2026, 10, 20),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
          dayNoteRepositoryProvider.overrideWith((ref) async => noteRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: NotesPanel(habitId: 'habit-with-notes'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Completed 10 km run today!'), findsOneWidget);
    expect(find.text('No notes yet. Hold the card to add one.'), findsNothing);
  });

  testWidgets(
      'HistoryScreen hides habits on dates before createdAt and displays on or after createdAt',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 917 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final habitRepo = HabitRepository(testStore, HabitScheduleRepository(testStore));
    await habitRepo.createHabit(
      name: 'Today Only Habit',
      type: HabitType.boolean,
      colorHex: '#216CCF',
      iconName: 'check',
      scheduleType: ScheduleType.daily,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // On Today, habit is visible
    expect(find.text('Today Only Habit'), findsOneWidget);

    // Tap on Yesterday in the horizontal date strip
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayDayStr = DateFormat('d').format(yesterday);

    await tester.tap(find.text(yesterdayDayStr).first);
    await tester.pumpAndSettle();

    // Habit should NOT be visible on yesterday since createdAt is today
    expect(find.text('Today Only Habit'), findsNothing);
    expect(find.text('No habits found for this date.'), findsOneWidget);
  });

  testWidgets(
      'HistoryScreen one-time task lifecycle: visible on created date and until completed date, then disappears on subsequent days',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 917 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    final habitRepo = HabitRepository(testStore, HabitScheduleRepository(testStore));
    final task = await habitRepo.createHabit(
      name: 'Walk the dog yesterday',
      type: HabitType.boolean,
      colorHex: '#216CCF',
      iconName: 'check',
      isOneTime: true,
      scheduleType: ScheduleType.daily,
    );
    // Update its createdAt to yesterday and completedAt to yesterday
    final updatedTask = task.copyWith(
      createdAt: DateTime.utc(yesterday.year, yesterday.month, yesterday.day, 10, 0),
      completedAt: DateTime.utc(yesterday.year, yesterday.month, yesterday.day, 18, 0),
    );
    await habitRepo.updateHabit(updatedTask);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // On Today: task should have disappeared since it completed yesterday!
    expect(find.text('Walk the dog yesterday'), findsNothing);

    // Tap Yesterday in date strip
    final yesterdayDayStr = DateFormat('d').format(yesterday);
    await tester.tap(find.text(yesterdayDayStr).first);
    await tester.pumpAndSettle();

    // On Yesterday: task was completed yesterday, so it IS visible!
    expect(find.text('Walk the dog yesterday'), findsOneWidget);
    expect(find.text('One-time'), findsOneWidget);

    // Tap 2 days ago (before created date)
    final twoDaysAgo = now.subtract(const Duration(days: 2));
    final twoDaysAgoDayStr = DateFormat('d').format(twoDaysAgo);
    await tester.tap(find.text(twoDaysAgoDayStr).first);
    await tester.pumpAndSettle();

    // On 2 days ago: task did not exist yet, so NOT visible!
    expect(find.text('Walk the dog yesterday'), findsNothing);
  });

  testWidgets(
      'HistoryScreen tapping habit row opens DayNoteBottomSheet for selected date and saves note',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 917 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final habitRepo = HabitRepository(testStore, HabitScheduleRepository(testStore));
    await habitRepo.createHabit(
      name: 'History Note Habit',
      type: HabitType.boolean,
      colorHex: '#216CCF',
      iconName: 'check',
      scheduleType: ScheduleType.daily,
    );

    final noteRepo = DayNoteRepository(testStore);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
          dayNoteRepositoryProvider.overrideWith((ref) async => noteRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the habit row text
    await tester.tap(find.text('History Note Habit'));
    await tester.pumpAndSettle();

    // DayNoteBottomSheet should be open
    final todayFormatted = DateFormat('E, d MMM').format(DateTime.now());
    expect(find.text('Note for $todayFormatted'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Save'), findsOneWidget);

    // Enter note and save
    await tester.enterText(find.byType(TextField), 'Historical note from history screen');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Note preview appears on history row
    expect(find.text('Historical note from history screen'), findsOneWidget);
  });

  testWidgets(
      'HomeScreen one-time task deletion deletes immediately without confirmation dialog',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 917 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final habitRepo = HabitRepository(testStore, HabitScheduleRepository(testStore));
    await habitRepo.createHabit(
      name: 'Quick Task Delete',
      type: HabitType.boolean,
      colorHex: '#216CCF',
      iconName: 'check',
      isOneTime: true,
      scheduleType: ScheduleType.daily,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
        ],
        child: const HabitTrackerApp(initialRoute: AppRoutes.home),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quick Task Delete'), findsOneWidget);

    // Long press to select
    await tester.longPress(find.text('Quick Task Delete'));
    await tester.pumpAndSettle();

    // Tap Delete button
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // No AlertDialog asking 'Are you sure'
    expect(find.text('Delete habit'), findsNothing);
    expect(find.text('Are you sure you want to delete'), findsNothing);

    // Task is immediately deleted from list
    expect(find.text('Quick Task Delete'), findsNothing);
    expect(find.text('Deleted task "Quick Task Delete"'), findsOneWidget);
  });

  testWidgets(
      'SettingsScreen displays AI Assistant section and navigates to AiSettingsScreen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 917 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AI ASSISTANT'), findsOneWidget);
    expect(find.text('AI Assistant'), findsOneWidget);
    expect(find.text('Chat with your habit data'), findsOneWidget);

    await tester.tap(find.text('AI Assistant'));
    await tester.pumpAndSettle();

    expect(find.byType(AiSettingsScreen), findsOneWidget);
  });

  testWidgets(
      'AiSettingsScreen configures API credentials, context window slider, and persona selection',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 917 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final aiRepo = AiSettingsRepository(testStore);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
          aiSettingsRepositoryProvider.overrideWith((ref) async => aiRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AiSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify sections rendered
    expect(find.text('API CONFIGURATION'), findsOneWidget);
    expect(find.text('CONTEXT WINDOW'), findsOneWidget);
    expect(find.text('Conversation Memory'), findsOneWidget);
    expect(find.text('PERSONA'), findsOneWidget);
    expect(find.text('Friedrich Nietzsche'), findsOneWidget);
    expect(find.text('Vegeta'), findsOneWidget);
    expect(find.text('Albus Dumbledore'), findsOneWidget);

    // Enter API key and tap Save Settings
    await tester.enterText(find.widgetWithText(TextField, 'Your API key'), 'test-gemini-key');
    await tester.enterText(
      find.byWidgetPredicate((w) =>
          w is TextField &&
          w.decoration?.labelText == 'Model Name (optional)'),
      'openai/gpt-oss-120b',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Settings'));
    await tester.pumpAndSettle();

    // Verify snackbar & repository persistence
    expect(find.text('Settings saved'), findsOneWidget);
    final saved = await aiRepo.getSettings();
    expect(saved.apiKey, 'test-gemini-key');
    expect(saved.modelName, 'openai/gpt-oss-120b');

    // Wait for snackbar to dismiss so it does not obscure lower widgets
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Drag up to center persona section
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Friedrich Nietzsche'));
    await tester.pumpAndSettle();

    final savedWithPersona = await aiRepo.getSettings();
    expect(savedWithPersona.selectedPersona, 'nietzsche');

    // Tap "Friedrich Nietzsche" again to deselect
    await tester.tap(find.text('Friedrich Nietzsche'));
    await tester.pumpAndSettle();

    final savedDeselected = await aiRepo.getSettings();
    expect(savedDeselected.selectedPersona, isNull);
  });

  testWidgets(
      'AiSettingsScreen Start Chat button is disabled without credentials and opens AiChatScreen when valid',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 917 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final aiRepo = AiSettingsRepository(testStore);
    // Clear API key
    await aiRepo.saveSettings(
      AiSettingsDto(
        apiEndpoint: 'https://generativelanguage.googleapis.com/v1beta',
        apiKey: '',
        selectedPersona: 'vegeta',
        contextWindowDays: 30,
        contextWindowUnit: 'days',
        updatedAt: DateTime.utc(2026, 10, 20),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
          aiSettingsRepositoryProvider.overrideWith((ref) async => aiRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AiSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Drag up to reveal Start Chat button
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();

    // Start Chat button should be disabled when key is empty
    final startChatFinder = find.widgetWithText(ElevatedButton, 'Start Chat');
    expect(startChatFinder, findsOneWidget);
    final elevatedBtn = tester.widget<ElevatedButton>(startChatFinder);
    expect(elevatedBtn.onPressed, isNull);

    // Drag back down to reach text field
    await tester.drag(find.byType(ListView), const Offset(0, 900));
    await tester.pumpAndSettle();

    // Enter API key -> becomes enabled
    await tester.enterText(find.widgetWithText(TextField, 'Your API key'), 'my-active-api-key');
    await tester.pumpAndSettle();

    // Drag up to Start Chat button
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();

    final elevatedBtnEnabled = tester.widget<ElevatedButton>(startChatFinder);
    expect(elevatedBtnEnabled.onPressed, isNotNull);

    // Tap Start Chat -> opens AiChatScreen
    await tester.tap(startChatFinder);
    await tester.pumpAndSettle();

    expect(find.byType(AiChatScreen), findsOneWidget);
    expect(find.text('Chat with Vegeta'), findsOneWidget);
    final autoSaved = await aiRepo.getSettings();
    expect(autoSaved.apiKey, 'my-active-api-key');
  });

  testWidgets('AiChatScreen renders persona header, context chip, and user/assistant messages',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 917 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final aiConvRepo = AiConversationRepository(testStore);
    final conv = await aiConvRepo.createConversation(
      personaId: 'sakuta',
      contextWindowDays: 14,
    );

    await aiConvRepo.addMessage(
      conversationId: conv.id,
      role: 'system',
      content: 'System instruction hidden from UI',
    );
    await aiConvRepo.addMessage(
      conversationId: conv.id,
      role: 'user',
      content: 'How are my habits doing?',
    );
    await aiConvRepo.addMessage(
      conversationId: conv.id,
      role: 'assistant',
      content: 'You are doing great, keep going!',
    );

    final aiSettingsRepo = AiSettingsRepository(testStore);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
          aiConversationRepositoryProvider.overrideWith((ref) async => aiConvRepo),
          aiSettingsRepositoryProvider.overrideWith((ref) async => aiSettingsRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: AiChatScreen(
            conversationId: conv.id,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify AppBar shows persona name
    expect(find.text('Sakuta Azusagawa'), findsOneWidget);

    // Verify context chip
    expect(find.text('Context: last 14 days of your habits'), findsOneWidget);

    // System message should NOT be in the widget tree
    expect(find.text('System instruction hidden from UI'), findsNothing);

    // User and assistant bubbles should be visible
    expect(find.text('How are my habits doing?'), findsOneWidget);
    expect(find.text('You are doing great, keep going!'), findsOneWidget);

    // Input field should be present
    expect(find.widgetWithText(TextField, 'Message...'), findsOneWidget);

    // Clear conversation option in popup menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Clear conversation'), findsOneWidget);

    // Tap Clear conversation -> dialog appears
    await tester.tap(find.text('Clear conversation'));
    await tester.pumpAndSettle();
    expect(find.text('Clear conversation?'), findsOneWidget);

    // Confirm clear
    await tester.tap(find.widgetWithText(TextButton, 'Clear'));
    await tester.pumpAndSettle();

    // Messages should be cleared and empty state displayed
    expect(find.text('How are my habits doing?'), findsNothing);
    expect(find.text('Chat with Sakuta Azusagawa'), findsOneWidget);
  });

  testWidgets('AiChatScreen renders generic AI Assistant header when no persona selected',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 917 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final aiConvRepo = AiConversationRepository(testStore);
    final aiSettingsRepo = AiSettingsRepository(testStore);
    await aiSettingsRepo.saveSettings(
      AiSettingsDto(
        apiEndpoint: 'https://generativelanguage.googleapis.com/v1beta',
        apiKey: 'key',
        selectedPersona: null,
        contextWindowDays: 30,
        contextWindowUnit: 'days',
        updatedAt: DateTime.utc(2026, 10, 20),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
          aiConversationRepositoryProvider.overrideWith((ref) async => aiConvRepo),
          aiSettingsRepositoryProvider.overrideWith((ref) async => aiSettingsRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AiChatScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AI Assistant'), findsOneWidget);
    expect(find.text('Start a Conversation'), findsOneWidget);
    expect(find.byIcon(Icons.smart_toy_outlined), findsWidgets);
  });

  testWidgets('AiSettingsScreen navigates to AiHistoryScreen when Previous Conversations is tapped',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 917 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final aiSettingsRepo = AiSettingsRepository(testStore);
    final aiConvRepo = AiConversationRepository(testStore);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
          aiSettingsRepositoryProvider.overrideWith((ref) async => aiSettingsRepo),
          aiConversationRepositoryProvider.overrideWith((ref) async => aiConvRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AiSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll to Previous Conversations tile
    await tester.scrollUntilVisible(
      find.text('Previous Conversations'),
      50,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final prevConvFinder = find.text('Previous Conversations');
    expect(prevConvFinder, findsOneWidget);

    await tester.tap(prevConvFinder);
    await tester.pumpAndSettle();

    expect(find.byType(AiHistoryScreen), findsOneWidget);
  });

  testWidgets('AiHistoryScreen renders conversation list, snippet, and resumes on tap',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 917 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final aiConvRepo = AiConversationRepository(testStore);
    final conv = await aiConvRepo.createConversation(
      personaId: 'dumbledore',
      contextWindowDays: 14,
    );
    await aiConvRepo.addMessage(
      conversationId: conv.id,
      role: 'system',
      content: 'System instruction',
    );
    await aiConvRepo.addMessage(
      conversationId: conv.id,
      role: 'user',
      content: 'How do I master patience?',
    );
    await aiConvRepo.addMessage(
      conversationId: conv.id,
      role: 'assistant',
      content: 'Patience is a great virtue, young wizard.',
    );

    final aiSettingsRepo = AiSettingsRepository(testStore);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
          aiConversationRepositoryProvider.overrideWith((ref) async => aiConvRepo),
          aiSettingsRepositoryProvider.overrideWith((ref) async => aiSettingsRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AiHistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify conversation row
    expect(find.text('Albus Dumbledore'), findsOneWidget);
    expect(find.text('Patience is a great virtue, young wizard.'), findsOneWidget);

    // Tap conversation to resume
    await tester.tap(find.text('Albus Dumbledore'));
    await tester.pumpAndSettle();

    // Verify AiChatScreen opened with conversation, correct persona, and message history
    expect(find.byType(AiChatScreen), findsOneWidget);
    expect(find.text('Albus Dumbledore'), findsWidgets);
    expect(find.text('How do I master patience?'), findsOneWidget);
    expect(find.text('Patience is a great virtue, young wizard.'), findsOneWidget);

    // Tap memory pill: toggles cleanly without bottom SnackBar blocking input
    expect(find.text('Memory ON'), findsOneWidget);
    await tester.tap(find.text('Memory ON'));
    await tester.pumpAndSettle();
    expect(find.text('Memory OFF'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('AiHistoryScreen swipe-to-delete shows confirmation dialog and removes conversation',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 917 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final aiConvRepo = AiConversationRepository(testStore);
    final existingConvs = await aiConvRepo.getAllConversations();
    for (final c in existingConvs) {
      await aiConvRepo.deleteConversation(c.id);
    }

    final conv = await aiConvRepo.createConversation(
      personaId: 'spiderman',
      contextWindowDays: 7,
    );
    await aiConvRepo.addMessage(
      conversationId: conv.id,
      role: 'user',
      content: 'Hello Spidey',
    );

    final aiSettingsRepo = AiSettingsRepository(testStore);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
          aiConversationRepositoryProvider.overrideWith((ref) async => aiConvRepo),
          aiSettingsRepositoryProvider.overrideWith((ref) async => aiSettingsRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AiHistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Peter Parker (Spider-Man)'), findsOneWidget);

    // Swipe dismissible to delete
    await tester.drag(find.byKey(ValueKey(conv.id)), const Offset(-500, 0));
    await tester.pumpAndSettle();

    // Confirm dialog appears
    expect(find.text('Delete conversation?'), findsOneWidget);

    // Tap Delete
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    // Should now show empty state
    expect(find.text('Peter Parker (Spider-Man)'), findsNothing);
    expect(find.text('No conversations yet'), findsOneWidget);
    expect(await aiConvRepo.getConversation(conv.id), isNull);
  });

  testWidgets('appRouter routes to AiChatScreen with conversationId and persona intact via extra',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 917 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final aiConvRepo = AiConversationRepository(testStore);
    final conv = await aiConvRepo.createConversation(
      personaId: 'nietzsche',
      contextWindowDays: 20,
    );
    await aiConvRepo.addMessage(
      conversationId: conv.id,
      role: 'user',
      content: 'What does not kill me makes me stronger.',
    );

    final aiSettingsRepo = AiSettingsRepository(testStore);
    await aiSettingsRepo.saveSettings(
      AiSettingsDto(
        apiEndpoint: 'https://example.com',
        apiKey: 'key',
        selectedPersona: 'vegeta', // Settings has Vegeta
        updatedAt: DateTime.now().toUtc(),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
          aiConversationRepositoryProvider.overrideWith((ref) async => aiConvRepo),
          aiSettingsRepositoryProvider.overrideWith((ref) async => aiSettingsRepo),
        ],
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: createAppRouter(initialLocation: AppRoutes.home),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to aiChat with extra
    final ctx = tester.element(find.byType(HomeScreen));
    appNavigateTo(
      ctx,
      AppRoutes.aiChat,
      AiChatScreen(
        conversationId: conv.id,
        persona: AiPersona.fromIdString('nietzsche'),
      ),
    );
    await tester.pumpAndSettle();

    // Verify it opened with Friedrich Nietzsche, NOT Vegeta, and has the message
    expect(find.byType(AiChatScreen), findsOneWidget);
    expect(find.text('Friedrich Nietzsche'), findsWidgets);
    expect(find.text('What does not kill me makes me stronger.'), findsOneWidget);
  });

  testWidgets('SplashScreen displays brand visual, quote, and auto-navigates to /home after 2.5s',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
        ],
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: createAppRouter(initialLocation: AppRoutes.splash),
        ),
      ),
    );

    // Initial pump renders SplashScreen
    await tester.pump();

    // Verify SplashScreen is active
    expect(find.byType(SplashScreen), findsOneWidget);

    // Verify asset image for icon_logo is present
    final imageFinder = find.byType(Image);
    expect(imageFinder, findsOneWidget);
    final imageWidget = tester.widget<Image>(imageFinder);
    expect((imageWidget.image as AssetImage).assetName, 'assets/icon_logo.png');

    // Verify fallback or picked quote is rendered
    expect(find.textContaining('Become who you are.'), findsWidgets);
    expect(find.text('— Friedrich Nietzsche'), findsWidgets);

    // Fast-forward 2.5s timer
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    // Verify transition to HomeScreen
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('SplashScreen navigates immediately to /home on user tap',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
        ],
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: createAppRouter(initialLocation: AppRoutes.splash),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);

    // Tap splash screen
    await tester.tap(find.byType(SplashScreen));
    await tester.pumpAndSettle();

    // Verify immediate navigation to HomeScreen
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });
}
