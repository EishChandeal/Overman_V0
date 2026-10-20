import 'dart:core';

class QuoteDto {
  final String id;
  final String text;
  final String? author;
  final int? dayOfYear;
  final bool isActive;

  const QuoteDto({
    required this.id,
    required this.text,
    this.author,
    this.dayOfYear,
    this.isActive = true,
  });

  static const Object _sentinel = Object();

  QuoteDto copyWith({
    String? id,
    String? text,
    Object? author = _sentinel,
    Object? dayOfYear = _sentinel,
    bool? isActive,
  }) {
    return QuoteDto(
      id: id ?? this.id,
      text: text ?? this.text,
      author: author == _sentinel ? this.author : author as String?,
      dayOfYear: dayOfYear == _sentinel ? this.dayOfYear : dayOfYear as int?,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'author': author,
      'dayOfYear': dayOfYear,
      'isActive': isActive,
    };
  }

  factory QuoteDto.fromJson(Map<String, dynamic> json) {
    return QuoteDto(
      id: json['id'] as String,
      text: json['text'] as String,
      author: json['author'] as String?,
      dayOfYear: json['dayOfYear'] as int?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuoteDto &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          text == other.text &&
          author == other.author &&
          dayOfYear == other.dayOfYear &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      text.hashCode ^
      author.hashCode ^
      dayOfYear.hashCode ^
      isActive.hashCode;

  @override
  String toString() {
    return 'QuoteDto(id: $id, text: $text, author: $author, dayOfYear: $dayOfYear, isActive: $isActive)';
  }
}
