import 'package:objectbox/objectbox.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';

@Entity()
class AiSettingsEntity {
  @Id()
  int obId;

  String apiEndpoint;
  String apiKey;
  String? modelName;
  String? selectedPersona;
  int contextWindowDays;
  String contextWindowUnit;
  bool enableMemory;
  int updatedAt;

  AiSettingsEntity({
    this.obId = 0,
    required this.apiEndpoint,
    required this.apiKey,
    this.modelName,
    this.selectedPersona,
    this.contextWindowDays = 30,
    this.contextWindowUnit = 'days',
    this.enableMemory = true,
    required this.updatedAt,
  });

  factory AiSettingsEntity.fromDto(AiSettingsDto dto) {
    return AiSettingsEntity(
      apiEndpoint: dto.apiEndpoint,
      apiKey: dto.apiKey,
      modelName: dto.modelName,
      selectedPersona: dto.selectedPersona,
      contextWindowDays: dto.contextWindowDays,
      contextWindowUnit: dto.contextWindowUnit,
      enableMemory: dto.enableMemory,
      updatedAt: dto.updatedAt.millisecondsSinceEpoch,
    );
  }

  AiSettingsDto toDto() {
    return AiSettingsDto(
      apiEndpoint: apiEndpoint,
      apiKey: apiKey,
      modelName: modelName,
      selectedPersona: selectedPersona,
      contextWindowDays: contextWindowDays,
      contextWindowUnit: contextWindowUnit,
      enableMemory: enableMemory,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt, isUtc: true),
    );
  }
}
