import 'package:objectbox/objectbox.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';

@Entity()
class AppSessionEntity {
  @Id()
  int obId;

  @Unique()
  String id;

  @Unique()
  @Index()
  int date; // midnight UTC epoch ms of the day

  int createdAt; // epoch ms — first open time of the day

  AppSessionEntity({
    this.obId = 0,
    required this.id,
    required this.date,
    required this.createdAt,
  });

  factory AppSessionEntity.fromDto(AppSessionDto dto) {
    final normalizedDate = DateTime.utc(dto.date.year, dto.date.month, dto.date.day);
    return AppSessionEntity(
      id: dto.id,
      date: normalizedDate.millisecondsSinceEpoch,
      createdAt: dto.createdAt.millisecondsSinceEpoch,
    );
  }

  AppSessionDto toDto() {
    return AppSessionDto(
      id: id,
      date: DateTime.fromMillisecondsSinceEpoch(date, isUtc: true),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt, isUtc: true),
    );
  }
}
