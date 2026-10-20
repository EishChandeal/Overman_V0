import 'dart:core';

class DayNoteDto {
  final String id;
  final String habitId;
  final DateTime date;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DayNoteDto({
    required this.id,
    required this.habitId,
    required this.date,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  DayNoteDto copyWith({
    String? id,
    String? habitId,
    DateTime? date,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DayNoteDto(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'date': date.toIso8601String(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DayNoteDto.fromJson(Map<String, dynamic> json) {
    return DayNoteDto(
      id: json['id'] as String,
      habitId: json['habitId'] as String,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayNoteDto &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          habitId == other.habitId &&
          date == other.date &&
          note == other.note &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      habitId.hashCode ^
      date.hashCode ^
      note.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'DayNoteDto(id: $id, habitId: $habitId, date: $date, note: $note, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
