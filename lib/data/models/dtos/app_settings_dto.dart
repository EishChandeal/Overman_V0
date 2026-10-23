class AppSettingsDto {
  final String themeMode; // "dark" | "warm" | "custom"
  final String? wallpaperPath;
  final DateTime updatedAt;

  const AppSettingsDto({
    this.themeMode = 'dark',
    this.wallpaperPath,
    required this.updatedAt,
  });

  AppSettingsDto copyWith({
    String? themeMode,
    String? wallpaperPath,
    DateTime? updatedAt,
  }) {
    return AppSettingsDto(
      themeMode: themeMode ?? this.themeMode,
      wallpaperPath: wallpaperPath ?? this.wallpaperPath,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsDto &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          wallpaperPath == other.wallpaperPath &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      themeMode.hashCode ^ wallpaperPath.hashCode ^ updatedAt.hashCode;
}
