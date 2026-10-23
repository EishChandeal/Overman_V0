import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/application/providers/providers.dart';
import 'package:habit_tracker/data/database/app_database.dart';
import 'package:habit_tracker/data/models/dtos/app_settings_dto.dart';
import 'package:habit_tracker/data/repositories/app_settings_repository.dart';
import 'package:habit_tracker/presentation/screens/settings/settings_screen.dart';
import 'package:habit_tracker/presentation/widgets/theme_selector_sheet.dart';
import 'package:objectbox/objectbox.dart';

void main() {
  late Store testStore;

  setUpAll(() async {
    testStore = await AppDatabase.openStore();
  });

  tearDownAll(() {
    AppDatabase.closeStore();
  });

  setUp(() async {
    // Reset app settings to default dark
    final repo = AppSettingsRepository(testStore);
    await repo.saveSettings(
      AppSettingsDto(
        themeMode: 'dark',
        wallpaperPath: null,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  });

  testWidgets('SettingsScreen displays APPEARANCE section with Theme row',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 1200 * 3);
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
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('APPEARANCE'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('Tapping Theme opens ThemeSelectorSheet with 3 options and active checkmark',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 1200 * 3);
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
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();

    expect(find.byType(ThemeSelectorSheet), findsOneWidget);
    expect(find.text('Choose Appearance'), findsOneWidget);
    expect(find.text('Dark'), findsWidgets); // on settings row and in sheet
    expect(find.text('Warm'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget); // On dark option
  });

  testWidgets('Selecting Warm updates themeMode to warm and dismisses sheet',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 1200 * 3);
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
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Warm'));
    await tester.pumpAndSettle();

    // Sheet dismissed
    expect(find.byType(ThemeSelectorSheet), findsNothing);

    // Settings screen updated
    expect(find.text('Warm (Blanchedalmond)'), findsOneWidget);

    final repo = AppSettingsRepository(testStore);
    final current = await repo.getSettings();
    expect(current.themeMode, 'warm');
  });

  testWidgets('Selecting Custom saves wallpaper path and updates themeMode',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 1200 * 3);
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
          home: SettingsScreen(
            onPickWallpaperFile: () async {
              return FilePickerResult([
                PlatformFile(
                  name: 'my_wallpaper.jpg',
                  size: 1024,
                  path: '/fake/path/my_wallpaper.jpg',
                ),
              ]);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();

    expect(find.byType(ThemeSelectorSheet), findsNothing);
    expect(find.text('Custom Wallpaper'), findsOneWidget);

    final repo = AppSettingsRepository(testStore);
    final current = await repo.getSettings();
    expect(current.themeMode, 'custom');
    expect(current.wallpaperPath, '/fake/path/my_wallpaper.jpg');
  });

  testWidgets('Cancelling Custom wallpaper picker shows SnackBar and preserves current theme',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 1200 * 3);
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
          home: SettingsScreen(
            onPickWallpaperFile: () async => null, // cancelled
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();

    expect(
      find.text('No wallpaper chosen — staying on current theme.'),
      findsOneWidget,
    );

    final repo = AppSettingsRepository(testStore);
    final current = await repo.getSettings();
    expect(current.themeMode, 'dark');
  });
}
