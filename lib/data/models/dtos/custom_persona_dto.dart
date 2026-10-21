import '../../../presentation/screens/ai/ai_personas.dart';

/// DTO representing a user-defined custom AI persona.
class CustomPersonaDto {
  final String id;
  final String name;
  final String tagline;
  final String systemPrompt;
  final String? imagePath;
  final DateTime createdAt;

  const CustomPersonaDto({
    required this.id,
    required this.name,
    required this.tagline,
    required this.systemPrompt,
    this.imagePath,
    required this.createdAt,
  });

  AiPersona toAiPersona() {
    return AiPersona.custom(
      id: id,
      name: name,
      tagline: tagline,
      systemPrompt: systemPrompt,
      imagePath: imagePath,
    );
  }

  CustomPersonaDto copyWith({
    String? id,
    String? name,
    String? tagline,
    String? systemPrompt,
    String? imagePath,
    DateTime? createdAt,
  }) {
    return CustomPersonaDto(
      id: id ?? this.id,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tagline': tagline,
      'systemPrompt': systemPrompt,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CustomPersonaDto.fromJson(Map<String, dynamic> json) {
    return CustomPersonaDto(
      id: json['id'] as String,
      name: json['name'] as String,
      tagline: json['tagline'] as String? ?? '',
      systemPrompt: json['systemPrompt'] as String? ?? '',
      imagePath: json['imagePath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomPersonaDto &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          tagline == other.tagline &&
          systemPrompt == other.systemPrompt &&
          imagePath == other.imagePath &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      tagline.hashCode ^
      systemPrompt.hashCode ^
      imagePath.hashCode ^
      createdAt.hashCode;
}
