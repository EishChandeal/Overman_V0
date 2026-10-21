import 'package:objectbox/objectbox.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';

@Entity()
class AiMessageEntity {
  @Id()
  int obId;

  @Unique()
  String id;

  @Index()
  String conversationId;

  String role;
  String content;
  int createdAt;

  AiMessageEntity({
    this.obId = 0,
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory AiMessageEntity.fromDto(AiMessageDto dto) {
    return AiMessageEntity(
      id: dto.id,
      conversationId: dto.conversationId,
      role: dto.role,
      content: dto.content,
      createdAt: dto.createdAt.millisecondsSinceEpoch,
    );
  }

  AiMessageDto toDto() {
    return AiMessageDto(
      id: id,
      conversationId: conversationId,
      role: role,
      content: content,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt, isUtc: true),
    );
  }
}
