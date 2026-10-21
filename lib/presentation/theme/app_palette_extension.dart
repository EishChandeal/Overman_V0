import 'package:flutter/material.dart';
import 'app_theme.dart';

/// ThemeExtension holding isolated color tokens for Dark and BlanchedAlmond themes.
class AppPaletteExtension extends ThemeExtension<AppPaletteExtension> {
  final bool isDark;

  // Base canvas and surface tokens
  final Color primaryBackground;
  final Color secondarySurface;
  final Color subtleCardTint;
  final Color cardBorder;

  // Text tokens
  final Color primaryText;
  final Color secondaryText;
  final Color accessibleSecondaryText;

  // Dark elements & controls
  final Color darkSurface;
  final Color textOnDarkSurface;

  // Common interactive and state accents
  final Color interactiveAccent;
  final Color successColor;
  final Color errorColor;

  // Controls & card-specific tokens
  final Color trackingButtonBackground;
  final Color settingsCardBackground;
  final Color settingsCardTitle;
  final Color settingsCardSubtitle;
  final Color settingsInteractiveAccent;
  final Color sectionHeader;

  // Inner card panels (details, stats, heatmap badges, notes)
  final Color innerTileBackground;
  final Color innerTileBorder;

  const AppPaletteExtension({
    required this.isDark,
    required this.primaryBackground,
    required this.secondarySurface,
    required this.subtleCardTint,
    required this.cardBorder,
    required this.primaryText,
    required this.secondaryText,
    required this.accessibleSecondaryText,
    required this.darkSurface,
    required this.textOnDarkSurface,
    required this.interactiveAccent,
    required this.successColor,
    required this.errorColor,
    required this.trackingButtonBackground,
    required this.settingsCardBackground,
    required this.settingsCardTitle,
    required this.settingsCardSubtitle,
    required this.settingsInteractiveAccent,
    required this.sectionHeader,
    required this.innerTileBackground,
    required this.innerTileBorder,
  });

  /// Protected dark theme palette preset (matching exact original dark theme values).
  static const AppPaletteExtension dark = AppPaletteExtension(
    isDark: true,
    primaryBackground: AppColors.background, // 0xFF0F1115
    secondarySurface: AppColors.surface, // 0xFF1C1F26
    subtleCardTint: AppColors.surface, // 0xFF1C1F26
    cardBorder: Color(0xFF2E3440),
    primaryText: AppColors.primaryText, // 0xFFE7E8EA
    secondaryText: AppColors.mutedGrey, // 0xFFA4AFBE
    accessibleSecondaryText: AppColors.mutedGrey, // 0xFFA4AFBE
    darkSurface: AppColors.surface, // 0xFF1C1F26
    textOnDarkSurface: AppColors.primaryText, // 0xFFE7E8EA
    interactiveAccent: AppColors.blue, // 0xFF216CCF
    successColor: Color(0xFF4F8B57),
    errorColor: Color(0xFFCF6679),
    trackingButtonBackground: AppColors.background, // 0xFF0F1115
    settingsCardBackground: AppColors.surface, // 0xFF1C1F26
    settingsCardTitle: AppColors.primaryText, // 0xFFE7E8EA
    settingsCardSubtitle: AppColors.mutedGrey, // 0xFFA4AFBE
    settingsInteractiveAccent: AppColors.blue, // 0xFF216CCF
    sectionHeader: AppColors.mutedGrey, // 0xFFA4AFBE
    innerTileBackground: AppColors.background, // 0xFF0F1115
    innerTileBorder: Colors.transparent,
  );

  /// Refined BlanchedAlmond warm theme palette preset.
  static const AppPaletteExtension blanchedAlmond = AppPaletteExtension(
    isDark: false,
    primaryBackground: Color(0xFFFFEBCD), // Primary screen background #FFEBCD
    secondarySurface: Color(0xFFFFF0D8), // Secondary cream surface #FFF0D8
    subtleCardTint: Color(0xFFF5DEB3), // Secondary surface / subtle card tint #F5DEB3
    cardBorder: Color(0xFFE8CDAA), // Card borders and subtle dividers #E8CDAA
    primaryText: Color(0xFF3D2B1F), // Primary text on light surfaces #3D2B1F
    secondaryText: Color(0xFF6F8299), // Secondary text on light surfaces #6F8299
    accessibleSecondaryText: Color(0xFF4E6178), // WCAG AA accessible shade (≥ 4.5:1 on #FFEBCD, #FFF0D8, #FAD8D8)
    darkSurface: Color(0xFF1C1E24), // Dark surfaces and tracking buttons #1C1E24
    textOnDarkSurface: Color(0xFFF5EBDD), // Primary text on dark surfaces #F5EBDD
    interactiveAccent: Color(0xFF2878D0), // Common interactive accent #2878D0
    successColor: Color(0xFF4F8B57), // Success and completed states #4F8B57
    errorColor: Color(0xFFC64D4D), // Error and destructive actions #C64D4D
    trackingButtonBackground: Color(0xFF1C1E24), // #1C1E24
    settingsCardBackground: Color(0xFF1C1E24), // #1C1E24
    settingsCardTitle: Color(0xFFF5EBDD), // #F5EBDD
    settingsCardSubtitle: Color(0xFFA4AFBE), // Legible muted light text on dark card
    settingsInteractiveAccent: Color(0xFF2878D0), // #2878D0
    sectionHeader: Color(0xFF3D2B1F), // Clear section headings against #FFEBCD
    innerTileBackground: Color(0xFFFFF0D8), // #FFF0D8
    innerTileBorder: Color(0xFFE8CDAA), // #E8CDAA
  );

  /// Resolves the card background color for a habit.
  Color getHabitCardBackground(
    Color habitColor, {
    String? colorHex,
    String? iconName,
    double cardOpacity = 1.0,
  }) {
    if (isDark) {
      final baseSurface = secondarySurface.withValues(alpha: cardOpacity);
      return Color.alphaBlend(habitColor.withValues(alpha: 0.05), baseSurface);
    }

    final hex = (colorHex ?? '').replaceAll('#', '').trim().toUpperCase();
    if (hex == 'E85D93' || iconName == 'meditation' || iconName == 'self_improvement') {
      return const Color(0xFFFAD8D8); // Mindfulness
    } else if (hex == 'D88719' || iconName == 'fitness' || iconName == 'fitness_center' || iconName == 'run' || iconName == 'directions_run') {
      return const Color(0xFFFFE1B9); // Fitness
    } else if (hex == '299EAA' || iconName == 'book' || iconName == 'menu_book' || iconName == 'menu_book_outlined' || iconName == 'code') {
      return const Color(0xFFD4EAE5); // Learning
    } else if (hex == 'E97850') {
      return const Color(0xFFFAD9C9); // Discipline
    } else if (hex == '8870C5') {
      return const Color(0xFFE4DDF5); // Creativity
    } else if (hex == '789348' || iconName == 'water' || iconName == 'water_drop' || iconName == 'water_drop_outlined' || iconName == 'sleep' || iconName == 'bedtime' || iconName == 'bedtime_outlined') {
      return const Color(0xFFDFE8C9); // Wellbeing
    }

    // Dynamic pastel fallback on secondary cream
    return Color.alphaBlend(habitColor.withValues(alpha: 0.12), const Color(0xFFFFF0D8));
  }

  /// Resolves the card border color for a habit.
  Color getHabitCardBorder(
    Color habitColor, {
    bool isSelected = false,
    String? colorHex,
    String? iconName,
  }) {
    if (isSelected) {
      return habitColor;
    }
    if (isDark) {
      return habitColor.withValues(alpha: 0.22);
    }

    final hex = (colorHex ?? '').replaceAll('#', '').trim().toUpperCase();
    if (hex == 'E85D93' || iconName == 'meditation' || iconName == 'self_improvement') {
      return const Color(0xFFF4BFBF);
    } else if (hex == 'D88719' || iconName == 'fitness' || iconName == 'fitness_center' || iconName == 'run' || iconName == 'directions_run') {
      return const Color(0xFFF4CE98);
    } else if (hex == '299EAA' || iconName == 'book' || iconName == 'menu_book' || iconName == 'menu_book_outlined' || iconName == 'code') {
      return const Color(0xFFB0D8D0);
    } else if (hex == 'E97850') {
      return const Color(0xFFF2BDAB);
    } else if (hex == '8870C5') {
      return const Color(0xFFCFC3EA);
    } else if (hex == '789348' || iconName == 'water' || iconName == 'water_drop' || iconName == 'sleep' || iconName == 'bedtime') {
      return const Color(0xFFC6D4A5);
    }

    return Color.alphaBlend(habitColor.withValues(alpha: 0.25), const Color(0xFFE8CDAA));
  }

  /// Resolves the suggested icon/accent color for a habit.
  Color getHabitIconColor(
    Color habitColor, {
    String? colorHex,
    String? iconName,
  }) {
    if (isDark) {
      return habitColor;
    }

    final hex = (colorHex ?? '').replaceAll('#', '').trim().toUpperCase();
    if (hex == 'E85D93' || iconName == 'meditation' || iconName == 'self_improvement') {
      return const Color(0xFFA93468); // Mindfulness suggested text/icon
    } else if (hex == 'D88719' || iconName == 'fitness' || iconName == 'fitness_center' || iconName == 'run' || iconName == 'directions_run') {
      return const Color(0xFF8C560E); // Fitness suggested text/icon
    } else if (hex == '299EAA' || iconName == 'book' || iconName == 'menu_book' || iconName == 'menu_book_outlined' || iconName == 'code') {
      return const Color(0xFF197C87); // Learning suggested text/icon
    } else if (hex == 'E97850') {
      return const Color(0xFFB95130); // Discipline suggested text/icon
    } else if (hex == '8870C5') {
      return const Color(0xFF6950A6); // Creativity suggested text/icon
    } else if (hex == '789348' || iconName == 'water' || iconName == 'water_drop' || iconName == 'sleep' || iconName == 'bedtime') {
      return const Color(0xFF566E30); // Wellbeing suggested text/icon
    }

    return habitColor;
  }

  @override
  AppPaletteExtension copyWith({
    bool? isDark,
    Color? primaryBackground,
    Color? secondarySurface,
    Color? subtleCardTint,
    Color? cardBorder,
    Color? primaryText,
    Color? secondaryText,
    Color? accessibleSecondaryText,
    Color? darkSurface,
    Color? textOnDarkSurface,
    Color? interactiveAccent,
    Color? successColor,
    Color? errorColor,
    Color? trackingButtonBackground,
    Color? settingsCardBackground,
    Color? settingsCardTitle,
    Color? settingsCardSubtitle,
    Color? settingsInteractiveAccent,
    Color? sectionHeader,
    Color? innerTileBackground,
    Color? innerTileBorder,
  }) {
    return AppPaletteExtension(
      isDark: isDark ?? this.isDark,
      primaryBackground: primaryBackground ?? this.primaryBackground,
      secondarySurface: secondarySurface ?? this.secondarySurface,
      subtleCardTint: subtleCardTint ?? this.subtleCardTint,
      cardBorder: cardBorder ?? this.cardBorder,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      accessibleSecondaryText: accessibleSecondaryText ?? this.accessibleSecondaryText,
      darkSurface: darkSurface ?? this.darkSurface,
      textOnDarkSurface: textOnDarkSurface ?? this.textOnDarkSurface,
      interactiveAccent: interactiveAccent ?? this.interactiveAccent,
      successColor: successColor ?? this.successColor,
      errorColor: errorColor ?? this.errorColor,
      trackingButtonBackground: trackingButtonBackground ?? this.trackingButtonBackground,
      settingsCardBackground: settingsCardBackground ?? this.settingsCardBackground,
      settingsCardTitle: settingsCardTitle ?? this.settingsCardTitle,
      settingsCardSubtitle: settingsCardSubtitle ?? this.settingsCardSubtitle,
      settingsInteractiveAccent: settingsInteractiveAccent ?? this.settingsInteractiveAccent,
      sectionHeader: sectionHeader ?? this.sectionHeader,
      innerTileBackground: innerTileBackground ?? this.innerTileBackground,
      innerTileBorder: innerTileBorder ?? this.innerTileBorder,
    );
  }

  @override
  AppPaletteExtension lerp(ThemeExtension<AppPaletteExtension>? other, double t) {
    if (other is! AppPaletteExtension) return this;
    return AppPaletteExtension(
      isDark: t < 0.5 ? isDark : other.isDark,
      primaryBackground: Color.lerp(primaryBackground, other.primaryBackground, t) ?? primaryBackground,
      secondarySurface: Color.lerp(secondarySurface, other.secondarySurface, t) ?? secondarySurface,
      subtleCardTint: Color.lerp(subtleCardTint, other.subtleCardTint, t) ?? subtleCardTint,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t) ?? cardBorder,
      primaryText: Color.lerp(primaryText, other.primaryText, t) ?? primaryText,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t) ?? secondaryText,
      accessibleSecondaryText: Color.lerp(accessibleSecondaryText, other.accessibleSecondaryText, t) ?? accessibleSecondaryText,
      darkSurface: Color.lerp(darkSurface, other.darkSurface, t) ?? darkSurface,
      textOnDarkSurface: Color.lerp(textOnDarkSurface, other.textOnDarkSurface, t) ?? textOnDarkSurface,
      interactiveAccent: Color.lerp(interactiveAccent, other.interactiveAccent, t) ?? interactiveAccent,
      successColor: Color.lerp(successColor, other.successColor, t) ?? successColor,
      errorColor: Color.lerp(errorColor, other.errorColor, t) ?? errorColor,
      trackingButtonBackground: Color.lerp(trackingButtonBackground, other.trackingButtonBackground, t) ?? trackingButtonBackground,
      settingsCardBackground: Color.lerp(settingsCardBackground, other.settingsCardBackground, t) ?? settingsCardBackground,
      settingsCardTitle: Color.lerp(settingsCardTitle, other.settingsCardTitle, t) ?? settingsCardTitle,
      settingsCardSubtitle: Color.lerp(settingsCardSubtitle, other.settingsCardSubtitle, t) ?? settingsCardSubtitle,
      settingsInteractiveAccent: Color.lerp(settingsInteractiveAccent, other.settingsInteractiveAccent, t) ?? settingsInteractiveAccent,
      sectionHeader: Color.lerp(sectionHeader, other.sectionHeader, t) ?? sectionHeader,
      innerTileBackground: Color.lerp(innerTileBackground, other.innerTileBackground, t) ?? innerTileBackground,
      innerTileBorder: Color.lerp(innerTileBorder, other.innerTileBorder, t) ?? innerTileBorder,
    );
  }
}

/// Convenience getter on [BuildContext] to access the active [AppPaletteExtension].
extension ThemePaletteContext on BuildContext {
  AppPaletteExtension get palette =>
      Theme.of(this).extension<AppPaletteExtension>() ?? AppPaletteExtension.dark;
}
