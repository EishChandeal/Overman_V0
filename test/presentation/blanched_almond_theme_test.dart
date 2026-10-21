import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/application/providers/providers.dart';
import 'package:habit_tracker/data/database/app_database.dart';
import 'package:habit_tracker/data/models/dtos/app_settings_dto.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/data/repositories/app_settings_repository.dart';
import 'package:habit_tracker/domain/enums/enums.dart';
import 'package:habit_tracker/presentation/screens/home/home_screen.dart';
import 'package:habit_tracker/presentation/screens/settings/settings_screen.dart';
import 'package:habit_tracker/presentation/theme/app_theme.dart';
import 'package:habit_tracker/presentation/widgets/habit_card.dart';
import 'package:objectbox/objectbox.dart';

void main() {
  late Store testStore;

  setUpAll(() async {
    testStore = await AppDatabase.openStore();
  });

  tearDownAll(() {
    AppDatabase.closeStore();
  });

  group('BlanchedAlmond Theme Refinement & Strict Dark Isolation', () {
    testWidgets('HabitCard in BlanchedAlmond theme uses pastel background, dark tracking button, and accessible text',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412 * 3, 917 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final habitStatus = HabitDayStatus(
        habit: HabitDto(
          id: 'test-mindfulness',
          name: 'Morning Meditation',
          type: HabitType.boolean,
          colorHex: '#E85D93', // Mindfulness category
          iconName: 'meditation',
          createdAt: DateTime.utc(2026, 1, 1),
          isArchived: false,
        ),
        entry: null,
        status: DayStatus.notTracked,
        isScheduledToday: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            objectBoxStoreProvider.overrideWith((ref) async => testStore),
          ],
          child: MaterialApp(
            theme: AppTheme.warmTheme,
            home: Scaffold(
              body: HabitCard(item: habitStatus),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify habit card background is mindfulness pastel (#FAD8D8)
      final materialFinder = find.descendant(
        of: find.byType(HabitCard),
        matching: find.byType(Material),
      );
      final cardMaterial = tester.widget<Material>(materialFinder.first);
      expect(cardMaterial.color, const Color(0xFFFAD8D8));

      // Verify title is dark primary text (#3D2B1F)
      final titleWidget = tester.widget<Text>(find.text('Morning Meditation'));
      expect(titleWidget.style?.color, const Color(0xFF3D2B1F));

      // Verify tracking button is dark charcoal (#1C1E24)
      final trackingButtonSemantics = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Mark habit as complete',
      );
      expect(trackingButtonSemantics, findsOneWidget);
      final buttonMaterial = tester.widget<Material>(
        find.descendant(of: trackingButtonSemantics, matching: find.byType(Material)).first,
      );
      expect(buttonMaterial.color, const Color(0xFF1C1E24));
    });

    testWidgets('HabitCard in Dark theme remains 100% dark and unaffected',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412 * 3, 917 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final habitStatus = HabitDayStatus(
        habit: HabitDto(
          id: 'test-mindfulness-dark',
          name: 'Morning Meditation',
          type: HabitType.boolean,
          colorHex: '#E85D93',
          iconName: 'meditation',
          createdAt: DateTime.utc(2026, 1, 1),
          isArchived: false,
        ),
        entry: null,
        status: DayStatus.notTracked,
        isScheduledToday: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            objectBoxStoreProvider.overrideWith((ref) async => testStore),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: HabitCard(item: habitStatus),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Dark card material: blended onto AppColors.surface (not pastel!)
      final materialFinder = find.descendant(
        of: find.byType(HabitCard),
        matching: find.byType(Material),
      );
      final cardMaterial = tester.widget<Material>(materialFinder.first);
      expect(
        cardMaterial.color,
        Color.alphaBlend(const Color(0xFFE85D93).withValues(alpha: 0.05), AppColors.surface),
      );

      // Verify tracking button in dark theme is AppColors.background (0xFF0F1115)
      final trackingButtonSemantics = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Mark habit as complete',
      );
      expect(trackingButtonSemantics, findsOneWidget);
      final buttonMaterial = tester.widget<Material>(
        find.descendant(of: trackingButtonSemantics, matching: find.byType(Material)).first,
      );
      expect(buttonMaterial.color, AppColors.background);
    });

    testWidgets('SettingsScreen in BlanchedAlmond has warm background, dark cards, light titles, and interactive blue accents',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412 * 3, 1200 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final settingsRepo = AppSettingsRepository(testStore);
      await settingsRepo.saveSettings(
        AppSettingsDto(themeMode: 'warm', updatedAt: DateTime.now().toUtc()),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            objectBoxStoreProvider.overrideWith((ref) async => testStore),
          ],
          child: MaterialApp(
            theme: AppTheme.warmTheme,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Page background is BlanchedAlmond (#FFEBCD)
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFFFEBCD));

      // Section header uses dark high-contrast text (#3D2B1F) against cream
      final sectionHeaderText = tester.widget<Text>(find.text('NAVIGATION SHORTCUTS'));
      expect(sectionHeaderText.style?.color, const Color(0xFF3D2B1F));

      // Settings tiles use dark charcoal cards (#1C1E24)
      final themeTileFinder = find.byKey(const Key('settings_theme_tile'));
      expect(themeTileFinder, findsOneWidget);
      final themeTileMaterial = tester.widget<Material>(themeTileFinder);
      expect(themeTileMaterial.color, const Color(0xFF1C1E24));

      // Card title is high-contrast light (#F5EBDD)
      final themeTitle = tester.widget<Text>(find.text('Theme'));
      expect(themeTitle.style?.color, const Color(0xFFF5EBDD));

      // Interactive icons use #2878D0 (Theme tile palette icon)
      final paletteIcon = tester.widget<Icon>(find.byIcon(Icons.palette_outlined));
      expect(paletteIcon.color, const Color(0xFF2878D0));

      // Semantic accent (History orange) is preserved
      final historyIcon = tester.widget<Icon>(find.byIcon(Icons.history_outlined));
      expect(historyIcon.color, AppColors.orange);
    });

    testWidgets('HomeScreen in BlanchedAlmond renders warm cream headers and BlanchedAlmond canvas',
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
            todayDashboardProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            theme: AppTheme.warmTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify canvas background is BlanchedAlmond (#FFEBCD)
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFFFEBCD));

      // Verify empty state is rendered with accessible palette text
      expect(find.text('No habits yet'), findsOneWidget);
      final emptyText = tester.widget<Text>(find.text('No habits yet'));
      expect(emptyText.style?.color, const Color(0xFF3D2B1F));
    });
  });
}
