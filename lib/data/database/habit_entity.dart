import 'package:objectbox/objectbox.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/domain/enums/enums.dart';
import 'habit_entry_entity.dart';
import 'habit_limit_entity.dart';
import 'habit_schedule_entity.dart';

// 6.  Defines the ObjectBox table scheme (HabitEntity) and the conversion methods (fromDto/toDto).
// lib/objectbox.g.dart
// – Generated database mapping code (defines static query properties like HabitEntity_.isArchived).
@Entity()
class HabitEntity {
  @Id()
  int obId;

  @Unique()
  @Index()
  String id;

  String name;
  String type;
  String? unit;
  double? targetValue;
  String colorHex;
  String iconName;
  String? description;
  bool isOneTime;
  int? completedAt;
  int createdAt;
  bool isArchived;

  final ToMany<HabitEntryEntity> entries = ToMany<HabitEntryEntity>();
  final ToMany<HabitLimitEntity> limits = ToMany<HabitLimitEntity>();
  final ToMany<HabitScheduleEntity> schedules = ToMany<HabitScheduleEntity>();

  HabitEntity({
    this.obId = 0,
    required this.id,
    required this.name,
    required this.type,
    this.unit,
    this.targetValue,
    required this.colorHex,
    required this.iconName,
    this.description,
    this.isOneTime = false,
    this.completedAt,
    required this.createdAt,
    required this.isArchived,
  });

  factory HabitEntity.fromDto(HabitDto dto) {
    return HabitEntity(
      id: dto.id,
      name: dto.name,
      type: dto.type.name,
      unit: dto.unit,
      targetValue: dto.targetValue,
      colorHex: dto.colorHex,
      iconName: dto.iconName,
      description: dto.description,
      isOneTime: dto.isOneTime,
      completedAt: dto.completedAt?.millisecondsSinceEpoch,
      createdAt: dto.createdAt.millisecondsSinceEpoch,
      isArchived: dto.isArchived,
    );
  }

  HabitDto toDto() {
    return HabitDto(
      id: id,
      name: name,
      type: HabitType.fromString(type),
      unit: unit,
      targetValue: targetValue,
      colorHex: colorHex,
      iconName: iconName,
      description: description,
      isOneTime: isOneTime,
      completedAt: completedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(completedAt!, isUtc: true)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt, isUtc: true),
      isArchived: isArchived,
    );
  }
}
