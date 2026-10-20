import 'package:uuid/uuid.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/domain/enums/enums.dart';
import 'package:habit_tracker/data/database/habit_entity.dart';
import 'package:habit_tracker/data/database/habit_entry_entity.dart';
import 'package:habit_tracker/data/database/habit_schedule_entity.dart';
import 'package:habit_tracker/data/database/habit_limit_entity.dart';
import 'package:habit_tracker/objectbox.g.dart';
import 'habit_schedule_repository.dart';

class HabitRepository {
  final Store _store;
  final HabitScheduleRepository _scheduleRepository;
  late final Box<HabitEntity> _box;

  HabitRepository(this._store, this._scheduleRepository) {
    _box = _store.box<HabitEntity>();
  }

  Future<HabitDto> createHabit({
    required String name,
    required HabitType type,
    String? unit,
    double? targetValue,
    required String colorHex,
    required String iconName,
    required ScheduleType scheduleType,
    List<Weekday>? scheduledWeekdays,
    int? targetCount,
    String? description,
    bool isOneTime = false,
  }) async {
    final id = const Uuid().v4();
    final createdAt = DateTime.now().toUtc();

    final dto = HabitDto(
      id: id,
      name: name,
      type: type,
      unit: unit,
      targetValue: targetValue,
      colorHex: colorHex,
      iconName: iconName,
      description: description,
      isOneTime: isOneTime,
      createdAt: createdAt,
      isArchived: false,
    );

    final entity = HabitEntity.fromDto(dto);
    _box.put(entity);

    // Add schedule covering its lifetime
    await _scheduleRepository.setSchedule(
      habitId: id,
      scheduleType: scheduleType,
      scheduledWeekdays: scheduledWeekdays,
      targetCount: targetCount,
      effectiveFrom: createdAt,
    );

    return dto;
  }

  Future<HabitDto> updateHabit(HabitDto updated) async {
    final query = _box.query(HabitEntity_.id.equals(updated.id)).build();
    final entity = query.findFirst();
    query.close();

    if (entity == null) {
      throw StateError('Habit not found with id: ${updated.id}');
    }

    // Update all mutable fields
    entity.name = updated.name;
    entity.type = updated.type.name;
    entity.unit = updated.unit;
    entity.targetValue = updated.targetValue;
    entity.colorHex = updated.colorHex;
    entity.iconName = updated.iconName;
    entity.description = updated.description;
    entity.isOneTime = updated.isOneTime;
    entity.completedAt = updated.completedAt?.millisecondsSinceEpoch;
    entity.isArchived = updated.isArchived;

    _box.put(entity);

    return updated;
  }

  Future<void> archiveHabit(String id) async {
    final query = _box.query(HabitEntity_.id.equals(id)).build();
    final entity = query.findFirst();
    query.close();

    if (entity == null) {
      throw StateError('Habit not found with id: $id');
    }

    entity.isArchived = true;
    _box.put(entity);
  }

  Future<HabitDto> unarchiveHabit(String id) async {
    final query = _box.query(HabitEntity_.id.equals(id)).build();
    final entity = query.findFirst();
    query.close();

    if (entity == null) {
      throw StateError('Habit not found with id: $id');
    }

    entity.isArchived = false;
    _box.put(entity);
    return entity.toDto();
  }

  Future<void> deleteHabit(String id) async {
    // Cascade delete related entries
    final entryBox = _store.box<HabitEntryEntity>();
    final entryQuery = entryBox.query(HabitEntryEntity_.habitId.equals(id)).build();
    final entryIds = entryQuery.findIds();
    entryQuery.close();
    if (entryIds.isNotEmpty) {
      entryBox.removeMany(entryIds);
    }

    // Cascade delete related schedules
    final scheduleBox = _store.box<HabitScheduleEntity>();
    final scheduleQuery = scheduleBox.query(HabitScheduleEntity_.habitId.equals(id)).build();
    final scheduleIds = scheduleQuery.findIds();
    scheduleQuery.close();
    if (scheduleIds.isNotEmpty) {
      scheduleBox.removeMany(scheduleIds);
    }

    // Cascade delete related limits
    final limitBox = _store.box<HabitLimitEntity>();
    final limitQuery = limitBox.query(HabitLimitEntity_.habitId.equals(id)).build();
    final limitIds = limitQuery.findIds();
    limitQuery.close();
    if (limitIds.isNotEmpty) {
      limitBox.removeMany(limitIds);
    }

    // Delete the habit entity itself
    final query = _box.query(HabitEntity_.id.equals(id)).build();
    final habitIds = query.findIds();
    query.close();
    if (habitIds.isNotEmpty) {
      _box.removeMany(habitIds);
    }
  }

  // 4.  Implements watchAllHabits(), runs the DB query, and converts entities to DTOs.
  Stream<List<HabitDto>> watchAllHabits() {
    return _box
        .query(HabitEntity_.isArchived.equals(false))
        .watch(triggerImmediately: true)
        .map((query) => query.find().map((e) => e.toDto()).toList());
  }

  Stream<List<HabitDto>> watchArchivedHabits() {
    return _box
        .query(HabitEntity_.isArchived.equals(true))
        .watch(triggerImmediately: true)
        .map((query) => query.find().map((e) => e.toDto()).toList());
  }

  Future<HabitDto?> getHabitById(String id) async {
    final query = _box.query(HabitEntity_.id.equals(id)).build();
    final entity = query.findFirst();
    query.close();

    return entity?.toDto();
  }
}
