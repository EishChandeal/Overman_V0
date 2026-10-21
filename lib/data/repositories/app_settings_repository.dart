import '../../objectbox.g.dart';
import '../database/app_settings_entity.dart';
import '../models/dtos/app_settings_dto.dart';

/// Repository managing application-wide appearance and behavior settings.
class AppSettingsRepository {
  final Store _store;
  late final Box<AppSettingsEntity> _box;

  AppSettingsRepository(this._store) {
    _box = _store.box<AppSettingsEntity>();
  }

  /// Fetches the current app settings, returning default values if not configured.
  Future<AppSettingsDto> getSettings() async {
    final entity = _box.getAll().firstOrNull;
    if (entity != null) {
      return entity.toDto();
    }
    return AppSettingsDto(
      themeMode: 'dark',
      wallpaperPath: null,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  /// Persists updated app settings.
  Future<void> saveSettings(AppSettingsDto dto) async {
    final existing = _box.getAll().firstOrNull;
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

    if (existing != null) {
      existing.themeMode = dto.themeMode;
      existing.wallpaperPath = dto.wallpaperPath;
      existing.updatedAt = nowMs;
      _box.put(existing);
    } else {
      final entity = AppSettingsEntity(
        themeMode: dto.themeMode,
        wallpaperPath: dto.wallpaperPath,
        updatedAt: nowMs,
      );
      _box.put(entity);
    }
  }

  /// Watches app settings changes reactively.
  Stream<AppSettingsDto> watchSettings() {
    return _box
        .query()
        .watch(triggerImmediately: true)
        .map((query) {
          final entity = query.findFirst();
          if (entity != null) {
            return entity.toDto();
          }
          return AppSettingsDto(
            themeMode: 'dark',
            wallpaperPath: null,
            updatedAt: DateTime.now().toUtc(),
          );
        });
  }
}
