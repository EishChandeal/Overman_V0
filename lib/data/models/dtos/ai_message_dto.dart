import 'dart:core';

class AiMessageDto {
  final String id;
  final String conversationId;
  final String role; // "system", "user", "assistant"
  final String content;
  final DateTime createdAt;

  const AiMessageDto({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  AiMessageDto copyWith({
    String? id,
    String? conversationId,
    String? role,
    String? content,
    DateTime? createdAt,
  }) {
    return AiMessageDto(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'role': role,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AiMessageDto.fromJson(Map<String, dynamic> json) {
    return AiMessageDto(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiMessageDto &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          conversationId == other.conversationId &&
          role == other.role &&
          content == other.content &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      conversationId.hashCode ^
      role.hashCode ^
      content.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'AiMessageDto(id: $id, conversationId: $conversationId, role: $role, content: $content, createdAt: $createdAt)';
  }
}
