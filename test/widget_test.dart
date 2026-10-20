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
        child: HabitTrackerApp(),
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
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: HabitTrackerApp(),
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
    addTearDown(() => tester.view.resetPhysicalSize());

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
    addTearDown(() => tester.view.resetPhysicalSize());

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
    addTearDown(() => tester.view.resetPhysicalSize());

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
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
        ],
        child: const HabitTrackerApp(),
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
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxStoreProvider.overrideWith((ref) async => testStore),
        ],
        child: const HabitTrackerApp(),
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
    addTearDown(() => tester.view.resetPhysicalSize());

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
    addTearDown(() => tester.view.resetPhysicalSize());

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
        child: const HabitTrackerApp(),
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
    addTearDown(() => tester.view.resetPhysicalSize());

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
        child: const HabitTrackerApp(),
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
    addTearDown(() => tester.view.resetPhysicalSize());

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
        child: const HabitTrackerApp(),
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
    addTearDown(() => tester.view.resetPhysicalSize());

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
        child: const HabitTrackerApp(),
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
}
