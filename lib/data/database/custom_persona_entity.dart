import 'package:objectbox/objectbox.dart';
import '../models/dtos/custom_persona_dto.dart';

@Entity()
class CustomPersonaEntity {
  @Id()
  int obId;

  @Unique()
  @Index()
  String id;

  String name;
  String tagline;
  String systemPrompt;
  String? imagePath;
  int createdAt;

  CustomPersonaEntity({
    this.obId = 0,
    required this.id,
    required this.name,
    required this.tagline,
    required this.systemPrompt,
    this.imagePath,
    required this.createdAt,
  });

  factory CustomPersonaEntity.fromDto(CustomPersonaDto dto) {
    return CustomPersonaEntity(
      id: dto.id,
      name: dto.name,
      tagline: dto.tagline,
      systemPrompt: dto.systemPrompt,
      imagePath: dto.imagePath,
      createdAt: dto.createdAt.millisecondsSinceEpoch,
    );
  }

  CustomPersonaDto toDto() {
    return CustomPersonaDto(
      id: id,
      name: name,
      tagline: tagline,
      systemPrompt: systemPrompt,
      imagePath: imagePath,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt, isUtc: true),
    );
  }
}
