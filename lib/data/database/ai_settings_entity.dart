import 'package:objectbox/objectbox.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';

@Entity()
class AiSettingsEntity {
  @Id()
  int obId;

  String apiEndpoint;
  String apiKey;
  String? selectedPersona;
  int updatedAt;

  AiSettingsEntity({
    this.obId = 0,
    required this.apiEndpoint,
    required this.apiKey,
    this.selectedPersona,
    required this.updatedAt,
  });

  factory AiSettingsEntity.fromDto(AiSettingsDto dto) {
    return AiSettingsEntity(
      apiEndpoint: dto.apiEndpoint,
      apiKey: dto.apiKey,
      selectedPersona: dto.selectedPersona,
      updatedAt: dto.updatedAt.millisecondsSinceEpoch,
    );
  }

  AiSettingsDto toDto() {
    return AiSettingsDto(
      apiEndpoint: apiEndpoint,
      apiKey: apiKey,
      selectedPersona: selectedPersona,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt, isUtc: true),
    );
  }
}
