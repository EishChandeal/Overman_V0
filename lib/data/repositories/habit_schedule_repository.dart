import 'package:uuid/uuid.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/domain/enums/enums.dart';
import 'package:habit_tracker/data/database/habit_entity.dart';
import 'package:habit_tracker/data/database/habit_schedule_entity.dart';
import 'package:habit_tracker/objectbox.g.dart';

class HabitScheduleRepository {
  final Store _store;
  late final Box<HabitScheduleEntity> _box;

  HabitScheduleRepository(this._store) {
    _box = _store.box<HabitScheduleEntity>();
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  Future<HabitScheduleDto> setSchedule({
    required String habitId,
    required ScheduleType scheduleType,
    List<Weekday>? scheduledWeekdays,
    int? targetCount,
    required DateTime effectiveFrom,
  }) async {
    final normalizedFrom = _normalizeDate(effectiveFrom);
    // Find any existing schedule for habitId where effectiveTo is null
    final query = _box.query(HabitScheduleEntity_.habitId.equals(habitId)).build();
    final activeSchedules = query.find().where((e) => e.effectiveTo == null).toList();
    query.close();

    final effectiveFromMillis = normalizedFrom.millisecondsSinceEpoch;

    // Set its effectiveTo to effectiveFrom
    for (final schedule in activeSchedules) {
      schedule.effectiveTo = effectiveFromMillis;
      _box.put(schedule);
    }

    // Find corresponding HabitEntity to set ToOne relation
    final habitBox = _store.box<HabitEntity>();
    final habitQuery = habitBox.query(HabitEntity_.id.equals(habitId)).build();
    final habit = habitQuery.findFirst();
    habitQuery.close();
    if (habit == null) {
      throw StateError('Habit not found with id: $habitId');
    }

    // Create and insert the new schedule with effectiveTo null
    final newSchedule = HabitScheduleEntity(
      id: const Uuid().v4(),
      habitId: habitId,
      scheduleType: scheduleType.name,
      scheduledWeekdays: scheduledWeekdays?.map((e) => e.name).toList(),
      targetCount: targetCount,
      effectiveFrom: effectiveFromMillis,
      effectiveTo: null,
    );
    newSchedule.habitEntity.target = habit;
    _box.put(newSchedule);

    return newSchedule.toDto();
  }

  Future<HabitScheduleDto?> getActiveScheduleForHabit(String habitId) async {
    final query = _box.query(HabitScheduleEntity_.habitId.equals(habitId)).build();
    final results = query.find();
    query.close();

    final activeList = results.where((e) => e.effectiveTo == null).toList();
    if (activeList.isEmpty) return null;
    return activeList.first.toDto();
  }

  Future<List<HabitScheduleDto>> getScheduleHistoryForHabit(String habitId) async {
    final query = _box.query(HabitScheduleEntity_.habitId.equals(habitId)).build();
    final results = query.find();
    query.close();

    // Sort by effectiveFrom ascending
    results.sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));
    return results.map((e) => e.toDto()).toList();
  }

  Stream<HabitScheduleDto?> watchActiveScheduleForHabit(String habitId) {
    return _box
        .query(HabitScheduleEntity_.habitId.equals(habitId))
        .watch(triggerImmediately: true)
        .map((query) {
          final results = query.find();
          final activeList =
              results.where((e) => e.effectiveTo == null).toList();
          if (activeList.isEmpty) return null;
          return activeList.first.toDto();
        });
  }
}
