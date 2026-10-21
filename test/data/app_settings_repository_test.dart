import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/database/app_database.dart';
import 'package:habit_tracker/data/models/dtos/app_settings_dto.dart';
import 'package:habit_tracker/data/repositories/app_settings_repository.dart';

void main() {
  setUp(() async {
    await AppDatabase.openStore();
  });

  tearDown(() {
    AppDatabase.closeStore();
  });

  group('AppSettingsRepository (STRAT-03-A)', () {
    test('getSettings returns default dark theme when empty', () async {
      final store = AppDatabase.instance;
      final repo = AppSettingsRepository(store);

      final settings = await repo.getSettings();
      expect(settings.themeMode, 'dark');
      expect(settings.wallpaperPath, isNull);
    });

    test('saveSettings persists and updates settings singleton', () async {
      final store = AppDatabase.instance;
      final repo = AppSettingsRepository(store);

      final newSettings = AppSettingsDto(
        themeMode: 'warm',
        wallpaperPath: null,
        updatedAt: DateTime.now().toUtc(),
      );

      await repo.saveSettings(newSettings);

      final fetched = await repo.getSettings();
      expect(fetched.themeMode, 'warm');
      expect(fetched.wallpaperPath, isNull);

      // Update to custom with wallpaper
      final customSettings = AppSettingsDto(
        themeMode: 'custom',
        wallpaperPath: '/path/to/wallpaper.png',
        updatedAt: DateTime.now().toUtc(),
      );

      await repo.saveSettings(customSettings);

      final updated = await repo.getSettings();
      expect(updated.themeMode, 'custom');
      expect(updated.wallpaperPath, '/path/to/wallpaper.png');
    });

    test('watchSettings emits initial and updated settings reactively', () async {
      final store = AppDatabase.instance;
      final repo = AppSettingsRepository(store);

      final stream = repo.watchSettings();

      final first = await stream.first;
      expect(first.themeMode, 'dark');

      await repo.saveSettings(
        AppSettingsDto(
          themeMode: 'warm',
          wallpaperPath: null,
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      final second = await repo.watchSettings().first;
      expect(second.themeMode, 'warm');
    });
  });
}
