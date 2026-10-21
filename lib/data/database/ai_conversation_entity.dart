import 'package:objectbox/objectbox.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';

@Entity()
class AiConversationEntity {
  @Id()
  int obId;

  @Unique()
  String id;

  String? personaId;
  int contextWindowDays;
  int createdAt;
  int updatedAt;

  AiConversationEntity({
    this.obId = 0,
    required this.id,
    this.personaId,
    required this.contextWindowDays,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AiConversationEntity.fromDto(AiConversationDto dto) {
    return AiConversationEntity(
      id: dto.id,
      personaId: dto.personaId,
      contextWindowDays: dto.contextWindowDays,
      createdAt: dto.createdAt.millisecondsSinceEpoch,
      updatedAt: dto.updatedAt.millisecondsSinceEpoch,
    );
  }

  AiConversationDto toDto() {
    return AiConversationDto(
      id: id,
      personaId: personaId,
      contextWindowDays: contextWindowDays,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt, isUtc: true),
    );
  }
}
