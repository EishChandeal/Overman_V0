import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/data/database/ai_settings_entity.dart';
import 'package:habit_tracker/objectbox.g.dart';

class AiSettingsRepository {
  final Store _store;
  late final Box<AiSettingsEntity> _box;

  AiSettingsRepository(this._store) {
    _box = _store.box<AiSettingsEntity>();
  }

  static const String defaultEndpoint =
      'https://generativelanguage.googleapis.com/v1beta';

  Future<AiSettingsDto> getSettings() async {
    final entity = _box.getAll().firstOrNull;
    if (entity != null) {
      return entity.toDto();
    }
    return AiSettingsDto(
      apiEndpoint: defaultEndpoint,
      apiKey: '',
      selectedPersona: null,
      contextWindowDays: 30,
      contextWindowUnit: 'days',
      updatedAt: DateTime.now().toUtc(),
    );
  }

  Future<void> saveSettings(AiSettingsDto dto) async {
    final existing = _box.getAll().firstOrNull;
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

    if (existing != null) {
      existing.apiEndpoint = dto.apiEndpoint;
      existing.apiKey = dto.apiKey;
      existing.selectedPersona = dto.selectedPersona;
      existing.contextWindowDays = dto.contextWindowDays;
      existing.contextWindowUnit = dto.contextWindowUnit;
      existing.updatedAt = nowMs;
      _box.put(existing);
    } else {
      final entity = AiSettingsEntity(
        apiEndpoint: dto.apiEndpoint,
        apiKey: dto.apiKey,
        selectedPersona: dto.selectedPersona,
        contextWindowDays: dto.contextWindowDays,
        contextWindowUnit: dto.contextWindowUnit,
        updatedAt: nowMs,
      );
      _box.put(entity);
    }
  }

  Stream<AiSettingsDto> watchSettings() {
    return _box
        .query()
        .watch(triggerImmediately: true)
        .map((query) {
          final entity = query.findFirst();
          if (entity != null) {
            return entity.toDto();
          }
          return AiSettingsDto(
            apiEndpoint: defaultEndpoint,
            apiKey: '',
            selectedPersona: null,
            contextWindowDays: 30,
            contextWindowUnit: 'days',
            updatedAt: DateTime.now().toUtc(),
          );
        });
  }
}
