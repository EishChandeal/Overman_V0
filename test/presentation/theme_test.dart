import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/presentation/theme/app_theme.dart';

void main() {
  group('AppTheme & ThemeMode Selection (STRAT-03-B & STRAT-03-C)', () {
    test('darkTheme has expected tokens and dark brightness', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
      expect(theme.colorScheme.surface, AppColors.surface);
      expect(theme.colorScheme.primary, AppColors.blue);
      expect(theme.colorScheme.secondary, AppColors.orange);
    });

    test('warmTheme has expected Blanchedalmond palette and light brightness', () {
      final theme = AppTheme.warmTheme;
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, const Color(0xFFFFEBCD));
      expect(theme.colorScheme.surface, const Color(0xFFFFE4C4));
      expect(theme.colorScheme.primary, const Color(0xFFA0522D));
      expect(theme.colorScheme.onSurface, const Color(0xFF3E2009));
      expect(theme.textTheme.bodyLarge?.color, const Color(0xFF3E2009));
      expect(theme.textTheme.titleLarge?.color, const Color(0xFF3E2009));
    });

    test('customTheme includes WallpaperThemeExtension with translucent defaults', () {
      final theme = AppTheme.customTheme(wallpaperPath: '/test/bg.jpg');
      final ext = theme.extension<WallpaperThemeExtension>();

      expect(ext, isNotNull);
      expect(ext!.wallpaperPath, '/test/bg.jpg');
      expect(ext.cardOpacity, 0.75);
      expect(ext.surfaceOpacity, 0.70);
    });

    test('themeForMode maps strings correctly', () {
      expect(AppTheme.themeForMode('dark').brightness, Brightness.dark);
      expect(AppTheme.themeForMode('warm').brightness, Brightness.light);
      expect(
        AppTheme.themeForMode('custom').extension<WallpaperThemeExtension>(),
        isNotNull,
      );
      // Fallback
      expect(AppTheme.themeForMode('unknown').brightness, Brightness.dark);
    });

    test('WallpaperThemeExtension copyWith and lerp', () {
      const ext1 = WallpaperThemeExtension(
        wallpaperPath: 'p1',
        cardOpacity: 0.6,
        surfaceOpacity: 0.5,
      );

      final copy = ext1.copyWith(cardOpacity: 0.8);
      expect(copy.wallpaperPath, 'p1');
      expect(copy.cardOpacity, 0.8);
      expect(copy.surfaceOpacity, 0.5);

      const ext2 = WallpaperThemeExtension(
        wallpaperPath: 'p2',
        cardOpacity: 0.8,
        surfaceOpacity: 0.7,
      );

      final lerped = ext1.lerp(ext2, 0.5);
      expect(lerped.cardOpacity, closeTo(0.7, 0.001));
      expect(lerped.surfaceOpacity, closeTo(0.6, 0.001));
    });
  });
}
