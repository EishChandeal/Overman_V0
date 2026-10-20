import 'package:objectbox/objectbox.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';

@Entity()
class DayNoteEntity {
  @Id()
  int obId;

  @Unique()
  @Index()
  String id;

  @Index()
  String habitId;

  @Index()
  int date;

  String note;
  int createdAt;
  int updatedAt;

  DayNoteEntity({
    this.obId = 0,
    required this.id,
    required this.habitId,
    required this.date,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DayNoteEntity.fromDto(DayNoteDto dto) {
    return DayNoteEntity(
      id: dto.id,
      habitId: dto.habitId,
      date: dto.date.millisecondsSinceEpoch,
      note: dto.note,
      createdAt: dto.createdAt.millisecondsSinceEpoch,
      updatedAt: dto.updatedAt.millisecondsSinceEpoch,
    );
  }

  DayNoteDto toDto() {
    return DayNoteDto(
      id: id,
      habitId: habitId,
      date: DateTime.fromMillisecondsSinceEpoch(date, isUtc: true),
      note: note,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt, isUtc: true),
    );
  }
}
