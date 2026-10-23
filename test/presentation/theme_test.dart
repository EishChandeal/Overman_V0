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
      expect(theme.colorScheme.surface, const Color(0xFFFFF0D8));
      expect(theme.colorScheme.primary, const Color(0xFF2878D0));
      expect(theme.colorScheme.onSurface, const Color(0xFF3D2B1F));
      expect(theme.textTheme.bodyLarge?.color, const Color(0xFF3D2B1F));
      expect(theme.textTheme.titleLarge?.color, const Color(0xFF3D2B1F));
    });

    test('darkTheme attaches AppPaletteExtension.dark with protected dark tokens', () {
      final theme = AppTheme.darkTheme;
      final palette = theme.extension<AppPaletteExtension>();
      expect(palette, isNotNull);
      expect(palette!.isDark, isTrue);
      expect(palette.primaryBackground, AppColors.background);
      expect(palette.secondarySurface, AppColors.surface);
      expect(palette.primaryText, AppColors.primaryText);
      expect(palette.secondaryText, AppColors.mutedGrey);
      expect(palette.interactiveAccent, AppColors.blue);
      expect(palette.trackingButtonBackground, AppColors.background);
      expect(palette.settingsCardBackground, AppColors.surface);
      expect(palette.settingsCardTitle, AppColors.primaryText);
      expect(palette.innerTileBackground, AppColors.background);
    });

    test('warmTheme attaches AppPaletteExtension.blanchedAlmond with refined tokens', () {
      final theme = AppTheme.warmTheme;
      final palette = theme.extension<AppPaletteExtension>();
      expect(palette, isNotNull);
      expect(palette!.isDark, isFalse);
      expect(palette.primaryBackground, const Color(0xFFFFEBCD));
      expect(palette.secondarySurface, const Color(0xFFFFF0D8));
      expect(palette.subtleCardTint, const Color(0xFFF5DEB3));
      expect(palette.cardBorder, const Color(0xFFE8CDAA));
      expect(palette.primaryText, const Color(0xFF3D2B1F));
      expect(palette.secondaryText, const Color(0xFF6F8299));
      expect(palette.darkSurface, const Color(0xFF1C1E24));
      expect(palette.textOnDarkSurface, const Color(0xFFF5EBDD));
      expect(palette.interactiveAccent, const Color(0xFF2878D0));
      expect(palette.successColor, const Color(0xFF4F8B57));
      expect(palette.errorColor, const Color(0xFFC64D4D));
      expect(palette.trackingButtonBackground, const Color(0xFF1C1E24));
      expect(palette.settingsCardBackground, const Color(0xFF1C1E24));
      expect(palette.settingsCardTitle, const Color(0xFFF5EBDD));
      expect(palette.innerTileBackground, const Color(0xFFFFF0D8));
      expect(palette.innerTileBorder, const Color(0xFFE8CDAA));
    });

    test('AppPaletteExtension resolves habit pastel cards and borders in BlanchedAlmond', () {
      const palette = AppPaletteExtension.blanchedAlmond;

      // Mindfulness
      expect(
        palette.getHabitCardBackground(const Color(0xFFE85D93), colorHex: '#E85D93'),
        const Color(0xFFFAD8D8),
      );
      expect(
        palette.getHabitIconColor(const Color(0xFFE85D93), colorHex: '#E85D93'),
        const Color(0xFFA93468),
      );
      expect(
        palette.getHabitCardBorder(const Color(0xFFE85D93), colorHex: '#E85D93'),
        const Color(0xFFF4BFBF),
      );

      // Fitness
      expect(
        palette.getHabitCardBackground(const Color(0xFFD88719), colorHex: '#D88719'),
        const Color(0xFFFFE1B9),
      );
      expect(
        palette.getHabitIconColor(const Color(0xFFD88719), colorHex: '#D88719'),
        const Color(0xFF8C560E),
      );
      expect(
        palette.getHabitCardBorder(const Color(0xFFD88719), colorHex: '#D88719'),
        const Color(0xFFF4CE98),
      );

      // Learning
      expect(
        palette.getHabitCardBackground(const Color(0xFF299EAA), colorHex: '#299EAA'),
        const Color(0xFFD4EAE5),
      );
      expect(
        palette.getHabitIconColor(const Color(0xFF299EAA), colorHex: '#299EAA'),
        const Color(0xFF197C87),
      );
      expect(
        palette.getHabitCardBorder(const Color(0xFF299EAA), colorHex: '#299EAA'),
        const Color(0xFFB0D8D0),
      );

      // Discipline
      expect(
        palette.getHabitCardBackground(const Color(0xFFE97850), colorHex: '#E97850'),
        const Color(0xFFFAD9C9),
      );
      expect(
        palette.getHabitIconColor(const Color(0xFFE97850), colorHex: '#E97850'),
        const Color(0xFFB95130),
      );

      // Creativity
      expect(
        palette.getHabitCardBackground(const Color(0xFF8870C5), colorHex: '#8870C5'),
        const Color(0xFFE4DDF5),
      );
      expect(
        palette.getHabitIconColor(const Color(0xFF8870C5), colorHex: '#8870C5'),
        const Color(0xFF6950A6),
      );

      // Wellbeing
      expect(
        palette.getHabitCardBackground(const Color(0xFF789348), colorHex: '#789348'),
        const Color(0xFFDFE8C9),
      );
      expect(
        palette.getHabitIconColor(const Color(0xFF789348), colorHex: '#789348'),
        const Color(0xFF566E30),
      );
    });

    test('Dark theme habit card resolution remains protected and identical', () {
      const darkPalette = AppPaletteExtension.dark;
      const testColor = Color(0xFFE85D93);

      expect(darkPalette.isDark, isTrue);
      expect(darkPalette.getHabitIconColor(testColor), testColor);
      expect(
        darkPalette.getHabitCardBorder(testColor, isSelected: false),
        testColor.withValues(alpha: 0.22),
      );
      expect(
        darkPalette.getHabitCardBorder(testColor, isSelected: true),
        testColor,
      );
      expect(
        darkPalette.getHabitCardBackground(testColor),
        Color.alphaBlend(testColor.withValues(alpha: 0.05), AppColors.surface),
      );
    });

    test('AppPaletteExtension copyWith and lerp', () {
      const ext = AppPaletteExtension.blanchedAlmond;
      final copy = ext.copyWith(primaryText: Colors.black);
      expect(copy.primaryText, Colors.black);
      expect(copy.primaryBackground, ext.primaryBackground);

      final lerped = ext.lerp(AppPaletteExtension.dark, 0.5);
      expect(lerped.isDark, isTrue); // t >= 0.5 takes other
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
