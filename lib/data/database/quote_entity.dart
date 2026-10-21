import 'package:objectbox/objectbox.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';

@Entity()
class QuoteEntity {
  @Id()
  int obId;

  @Unique()
  String id;

  String text;
  String? author;
  int? dayOfYear;
  bool isActive;

  QuoteEntity({
    this.obId = 0,
    required this.id,
    required this.text,
    this.author,
    this.dayOfYear,
    this.isActive = true,
  });

  factory QuoteEntity.fromDto(QuoteDto dto) {
    return QuoteEntity(
      id: dto.id,
      text: dto.text,
      author: dto.author,
      dayOfYear: dto.dayOfYear,
      isActive: dto.isActive,
    );
  }

  QuoteDto toDto() {
    return QuoteDto(
      id: id,
      text: text,
      author: author,
      dayOfYear: dayOfYear,
      isActive: isActive,
    );
  }
}
