import 'package:flutter/material.dart';

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

