import 'package:flutter/material.dart';
import 'app_palette_extension.dart';
import 'wallpaper_theme_extension.dart';

export 'app_palette_extension.dart';
export 'wallpaper_theme_extension.dart';

/// Design tokens extracted from DESIGN.md and PROJECT_BRIEF.md.
class AppColors {
  AppColors._();

  // Core canvas and surfaces
  static const Color background = Color(0xFF0F1115);
  static const Color surface = Color(0xFF1C1F26);

  // Action and state accents
  static const Color blue = Color(0xFF216CCF);
  static const Color orange = Color(0xFFFF7A45);
  static const Color mutedGrey = Color(0xFFA4AFBE);

  // Typography and control text
  static const Color primaryText = Color(0xFFE7E8EA);
  static const Color controlText = Color(0xFF0F1115);

  // Semantic aliases matching design documentation
  static const Color incomplete = mutedGrey;
  static const Color accentBlue = blue;
  static const Color accentOrange = orange;

  // Warm theme palette tokens (refined BlanchedAlmond palette)
  static const Color warmBackground = Color(0xFFFFEBCD); // Primary screen background #FFEBCD
  static const Color warmSecondaryCream = Color(0xFFFFF0D8); // Secondary cream surface #FFF0D8
  static const Color warmSubtleCardTint = Color(0xFFF5DEB3); // Secondary surface / subtle card tint #F5DEB3
  static const Color warmCardBorder = Color(0xFFE8CDAA); // Card borders & subtle dividers #E8CDAA
  static const Color warmPrimaryText = Color(0xFF3D2B1F); // Primary text on light surfaces #3D2B1F
  static const Color warmSecondaryText = Color(0xFF6F8299); // Secondary text on light surfaces #6F8299
  static const Color warmDarkSurface = Color(0xFF1C1E24); // Dark surfaces & tracking buttons #1C1E24
  static const Color warmTextOnDark = Color(0xFFF5EBDD); // Primary text on dark surfaces #F5EBDD
  static const Color warmInteractiveAccent = Color(0xFF2878D0); // Common interactive accent #2878D0
  static const Color warmSuccess = Color(0xFF4F8B57); // Success and completed states #4F8B57
  static const Color warmError = Color(0xFFC64D4D); // Error and destructive actions #C64D4D

  // Aliases for compatibility
  static const Color warmSurface = warmSecondaryCream;
  static const Color warmSurface2 = warmSubtleCardTint;
  static const Color warmAccent = warmInteractiveAccent;
  static const Color warmAccent2 = warmSubtleCardTint;
  static const Color warmDivider = warmCardBorder;
}

/// Dedicated token container for the Blanchedalmond Warm Theme.
class WarmColors {
  WarmColors._();

  static const Color background = AppColors.warmBackground;
  static const Color surface = AppColors.warmSecondaryCream;
  static const Color surface2 = AppColors.warmSubtleCardTint;
  static const Color cardBorder = AppColors.warmCardBorder;
  static const Color primaryText = AppColors.warmPrimaryText;
  static const Color secondaryText = AppColors.warmSecondaryText;
  static const Color darkSurface = AppColors.warmDarkSurface;
  static const Color textOnDark = AppColors.warmTextOnDark;
  static const Color accent = AppColors.warmInteractiveAccent;
  static const Color accent2 = AppColors.warmSubtleCardTint;
  static const Color divider = AppColors.warmCardBorder;
  static const Color success = AppColors.warmSuccess;
  static const Color error = AppColors.warmError;
}

/// Central application theme adhering to the dark palette specified in DESIGN.md.
class AppTheme {
  AppTheme._();

  static const String fontPrimary = 'Montserrat';

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.blue,
      onPrimary: AppColors.controlText,
      secondary: AppColors.orange,
      onSecondary: AppColors.controlText,
      surface: AppColors.surface,
      onSurface: AppColors.primaryText,
      error: Color(0xFFCF6679),
      onError: Color(0xFF000000),
      outline: AppColors.mutedGrey,
    );

    final baseTextTheme = Typography.material2021(platform: TargetPlatform.android).white;
    final textTheme = baseTextTheme.apply(
      fontFamily: fontPrimary,
      bodyColor: AppColors.primaryText,
      displayColor: AppColors.primaryText,
    ).copyWith(
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontFamily: fontPrimary,
        color: AppColors.primaryText,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontFamily: fontPrimary,
        color: AppColors.primaryText,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontFamily: fontPrimary,
        color: AppColors.mutedGrey,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontFamily: fontPrimary,
        color: AppColors.primaryText,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontFamily: fontPrimary,
        color: AppColors.primaryText,
        fontWeight: FontWeight.bold,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontPrimary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: colorScheme,
      textTheme: textTheme,
      extensions: const [
        AppPaletteExtension.dark,
      ],
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.controlText,
          textStyle: const TextStyle(
            fontFamily: fontPrimary,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: AppColors.controlText,
          textStyle: const TextStyle(
            fontFamily: fontPrimary,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          side: const BorderSide(color: AppColors.surface),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(
          color: AppColors.mutedGrey,
          fontFamily: fontPrimary,
        ),
        labelStyle: const TextStyle(
          color: AppColors.mutedGrey,
          fontFamily: fontPrimary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.primaryText,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surface,
        thickness: 1,
      ),
    );
  }

  /// Warm palette theme with Blanchedalmond canvas and dark brown typography.
  static ThemeData get warmTheme {
    const colorScheme = ColorScheme.light(
      primary: WarmColors.accent,
      onPrimary: Colors.white,
      secondary: WarmColors.accent2,
      onSecondary: Colors.white,
      surface: WarmColors.surface,
      onSurface: WarmColors.primaryText,
      error: WarmColors.error,
      onError: Colors.white,
      outline: WarmColors.cardBorder,
    );

    final baseTextTheme =
        Typography.material2021(platform: TargetPlatform.android).black;
    final textTheme = baseTextTheme.apply(
      fontFamily: fontPrimary,
      bodyColor: WarmColors.primaryText,
      displayColor: WarmColors.primaryText,
    ).copyWith(
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontFamily: fontPrimary,
        color: WarmColors.primaryText,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontFamily: fontPrimary,
        color: WarmColors.primaryText,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontFamily: fontPrimary,
        color: WarmColors.secondaryText,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontFamily: fontPrimary,
        color: WarmColors.primaryText,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontFamily: fontPrimary,
        color: WarmColors.primaryText,
        fontWeight: FontWeight.bold,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontPrimary,
      scaffoldBackgroundColor: WarmColors.background,
      colorScheme: colorScheme,
      textTheme: textTheme,
      extensions: const [
        AppPaletteExtension.blanchedAlmond,
      ],
      appBarTheme: const AppBarTheme(
        backgroundColor: WarmColors.surface,
        foregroundColor: WarmColors.primaryText,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: WarmColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: WarmColors.cardBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: WarmColors.accent,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: fontPrimary,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: WarmColors.accent,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: fontPrimary,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: WarmColors.primaryText,
          side: const BorderSide(color: WarmColors.divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WarmColors.surface,
        hintStyle: const TextStyle(
          color: WarmColors.secondaryText,
          fontFamily: fontPrimary,
        ),
        labelStyle: const TextStyle(
          color: WarmColors.secondaryText,
          fontFamily: fontPrimary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: WarmColors.accent, width: 1.5),
        ),
      ),
      iconTheme: const IconThemeData(
        color: WarmColors.primaryText,
      ),
      dividerTheme: const DividerThemeData(
        color: WarmColors.divider,
        thickness: 1,
      ),
    );
  }

  /// Custom theme with wallpaper transparency extension.
  static ThemeData customTheme({String? wallpaperPath}) {
    return darkTheme.copyWith(
      extensions: [
        AppPaletteExtension.dark,
        WallpaperThemeExtension(
          wallpaperPath: wallpaperPath,
          cardOpacity: 0.75,
          surfaceOpacity: 0.70,
        ),
      ],
    );
  }

  /// Returns the corresponding [ThemeData] for a theme mode string ("dark", "warm", "custom").
  static ThemeData themeForMode(String mode, {String? wallpaperPath}) {
    switch (mode.toLowerCase()) {
      case 'warm':
        return warmTheme;
      case 'custom':
        return customTheme(wallpaperPath: wallpaperPath);
      case 'dark':
      default:
        return darkTheme;
    }
  }
}

/// Helper utilities for habit visual representation (colors and icons).
class HabitVisuals {
  HabitVisuals._();

  /// Parse a color from hex string, defaulting to [AppColors.blue].
  static Color parseColor(String? hexString, [Color fallback = AppColors.blue]) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      final clean = hexString.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return fallback;
  }

  /// Get appropriate high-contrast foreground color on top of a fill color.
  static Color getOnColor(Color color) {
    return color.computeLuminance() > 0.4 ? const Color(0xFF0F1115) : Colors.white;
  }

  /// Map an icon string identifier to its corresponding [IconData].
  static IconData getIcon(String? iconName) {
    switch (iconName) {
      case 'fitness':
      case 'fitness_center':
        return Icons.fitness_center;
      case 'run':
      case 'directions_run':
        return Icons.directions_run;
      case 'water':
      case 'water_drop':
      case 'water_drop_outlined':
        return Icons.water_drop_outlined;
      case 'book':
      case 'menu_book':
      case 'menu_book_outlined':
        return Icons.menu_book_outlined;
      case 'meditation':
      case 'self_improvement':
        return Icons.self_improvement;
      case 'sleep':
      case 'bedtime':
      case 'bedtime_outlined':
        return Icons.bedtime_outlined;
      case 'code':
        return Icons.code;
      case 'check':
      case 'check_circle':
      case 'check_circle_outline':
      default:
        return Icons.check_circle_outline;
    }
  }
}

