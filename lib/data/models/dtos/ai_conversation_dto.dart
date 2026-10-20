import 'dart:core';

class AiConversationDto {
  final String id;
  final String? personaId;
  final int contextWindowDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AiConversationDto({
    required this.id,
    this.personaId,
    required this.contextWindowDays,
    required this.createdAt,
    required this.updatedAt,
  });

  AiConversationDto copyWith({
    String? id,
    String? personaId,
    int? contextWindowDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AiConversationDto(
      id: id ?? this.id,
      personaId: personaId ?? this.personaId,
      contextWindowDays: contextWindowDays ?? this.contextWindowDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'personaId': personaId,
      'contextWindowDays': contextWindowDays,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AiConversationDto.fromJson(Map<String, dynamic> json) {
    return AiConversationDto(
      id: json['id'] as String,
      personaId: json['personaId'] as String?,
      contextWindowDays: json['contextWindowDays'] as int? ?? 30,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiConversationDto &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          personaId == other.personaId &&
          contextWindowDays == other.contextWindowDays &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      personaId.hashCode ^
      contextWindowDays.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'AiConversationDto(id: $id, personaId: $personaId, contextWindowDays: $contextWindowDays, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
