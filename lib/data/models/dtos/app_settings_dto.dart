class AppSettingsDto {
  final String themeMode; // "dark" | "warm" | "custom"
  final String? wallpaperPath;
  final DateTime updatedAt;
  final bool enableCompletionEffects;

  const AppSettingsDto({
    this.themeMode = 'dark',
    this.wallpaperPath,
    required this.updatedAt,
    this.enableCompletionEffects = false,
  });

  AppSettingsDto copyWith({
    String? themeMode,
    String? wallpaperPath,
    DateTime? updatedAt,
    bool? enableCompletionEffects,
  }) {
    return AppSettingsDto(
      themeMode: themeMode ?? this.themeMode,
      wallpaperPath: wallpaperPath ?? this.wallpaperPath,
      updatedAt: updatedAt ?? this.updatedAt,
      enableCompletionEffects:
          enableCompletionEffects ?? this.enableCompletionEffects,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsDto &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          wallpaperPath == other.wallpaperPath &&
          enableCompletionEffects == other.enableCompletionEffects &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      themeMode.hashCode ^
      wallpaperPath.hashCode ^
      enableCompletionEffects.hashCode ^
      updatedAt.hashCode;
}
