import 'package:objectbox/objectbox.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';

@Entity()
class AppSettingsEntity {
  @Id()
  int obId;

  String themeMode; // "dark" | "warm" | "custom"
  String? wallpaperPath;
  int updatedAt;

  AppSettingsEntity({
    this.obId = 0,
    this.themeMode = 'dark',
    this.wallpaperPath,
    required this.updatedAt,
  });

  factory AppSettingsEntity.fromDto(AppSettingsDto dto) {
    return AppSettingsEntity(
      themeMode: dto.themeMode,
      wallpaperPath: dto.wallpaperPath,
      updatedAt: dto.updatedAt.millisecondsSinceEpoch,
    );
  }

  AppSettingsDto toDto() {
    return AppSettingsDto(
      themeMode: themeMode,
      wallpaperPath: wallpaperPath,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt, isUtc: true),
    );
  }
}
