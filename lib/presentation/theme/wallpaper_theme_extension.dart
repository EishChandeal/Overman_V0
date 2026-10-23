import 'dart:ui';
import 'package:flutter/material.dart';

/// ThemeExtension enabling translucent cards and surfaces when a custom wallpaper is active.
class WallpaperThemeExtension extends ThemeExtension<WallpaperThemeExtension> {
  final String? wallpaperPath;
  final double cardOpacity;
  final double surfaceOpacity;

  const WallpaperThemeExtension({
    this.wallpaperPath,
    this.cardOpacity = 0.75,
    this.surfaceOpacity = 0.70,
  });

  @override
  WallpaperThemeExtension copyWith({
    String? wallpaperPath,
    double? cardOpacity,
    double? surfaceOpacity,
  }) {
    return WallpaperThemeExtension(
      wallpaperPath: wallpaperPath ?? this.wallpaperPath,
      cardOpacity: cardOpacity ?? this.cardOpacity,
      surfaceOpacity: surfaceOpacity ?? this.surfaceOpacity,
    );
  }

  @override
  WallpaperThemeExtension lerp(
    ThemeExtension<WallpaperThemeExtension>? other,
    double t,
  ) {
    if (other is! WallpaperThemeExtension) {
      return this;
    }
    return WallpaperThemeExtension(
      wallpaperPath: t < 0.5 ? wallpaperPath : other.wallpaperPath,
      cardOpacity:
          lerpDouble(cardOpacity, other.cardOpacity, t) ?? cardOpacity,
      surfaceOpacity:
          lerpDouble(surfaceOpacity, other.surfaceOpacity, t) ?? surfaceOpacity,
    );
  }
}
