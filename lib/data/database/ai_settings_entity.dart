import 'package:objectbox/objectbox.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';

@Entity()
class AiSettingsEntity {
  @Id()
  int obId;

  String apiEndpoint;
  String apiKey;
  String? selectedPersona;
  int contextWindowDays;
  String contextWindowUnit;
  int updatedAt;

  AiSettingsEntity({
    this.obId = 0,
    required this.apiEndpoint,
    required this.apiKey,
    this.selectedPersona,
    this.contextWindowDays = 30,
    this.contextWindowUnit = 'days',
    required this.updatedAt,
  });

  factory AiSettingsEntity.fromDto(AiSettingsDto dto) {
    return AiSettingsEntity(
      apiEndpoint: dto.apiEndpoint,
      apiKey: dto.apiKey,
      selectedPersona: dto.selectedPersona,
      contextWindowDays: dto.contextWindowDays,
      contextWindowUnit: dto.contextWindowUnit,
      updatedAt: dto.updatedAt.millisecondsSinceEpoch,
    );
  }

  AiSettingsDto toDto() {
    return AiSettingsDto(
      apiEndpoint: apiEndpoint,
      apiKey: apiKey,
      selectedPersona: selectedPersona,
      contextWindowDays: contextWindowDays,
      contextWindowUnit: contextWindowUnit,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt, isUtc: true),
    );
  }
}
