import 'package:uuid/uuid.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/data/database/habit_entity.dart';
import 'package:habit_tracker/data/database/habit_entry_entity.dart';
import 'package:habit_tracker/objectbox.g.dart';

class HabitEntryRepository {
  final Store _store;
  late final Box<HabitEntryEntity> _box;

  HabitEntryRepository(this._store) {
    _box = _store.box<HabitEntryEntity>();
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  Future<HabitEntryDto> upsertEntry({
    required String habitId,
    required DateTime date,
    required double value,
    String? note,
  }) async {
    final normalizedDate = _normalizeDate(date);
    
    // Intentional: reject future dates but allow past dates for backfilling.
    // The user's "today" corresponds to their local calendar day.
    final localNow = DateTime.now();
    final todayMidnightUtc = DateTime.utc(
      localNow.year,
      localNow.month,
      localNow.day,
    );
    if (normalizedDate.isAfter(todayMidnightUtc)) {
      throw ArgumentError('Cannot create entry for future date.');
    }

    final dateMillis = normalizedDate.millisecondsSinceEpoch;

    // Query for an existing entry where habitId matches AND date matches
    final query = _box
        .query(
          HabitEntryEntity_.habitId.equals(habitId).and(
            HabitEntryEntity_.date.equals(dateMillis),
          ),
        )
        .build();
    final existing = query.findFirst();
    query.close();

    if (existing != null) {
      existing.value = value;
      existing.note = note;
      _box.put(existing);
      return existing.toDto();
    }

    // Find corresponding HabitEntity to set ToOne relation
    final habitBox = _store.box<HabitEntity>();
    final habitQuery = habitBox.query(HabitEntity_.id.equals(habitId)).build();
    final habit = habitQuery.findFirst();
    habitQuery.close();
    if (habit == null) {
      throw StateError('Habit not found with id: $habitId');
    }

    final newEntry = HabitEntryEntity(
      id: const Uuid().v4(),
      habitId: habitId,
      date: dateMillis,
      value: value,
      note: note,
      createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
    );
    newEntry.habitEntity.target = habit;
    _box.put(newEntry);

    return newEntry.toDto();
  }

  Future<List<HabitEntryDto>> getEntriesForHabit(
    String habitId,
    DateTime from,
    DateTime to,
  ) async {
    final normalizedFrom = _normalizeDate(from);
    final normalizedTo = _normalizeDate(to);

    final query = _box
        .query(
          HabitEntryEntity_.habitId.equals(habitId).and(
            HabitEntryEntity_.date.between(
              normalizedFrom.millisecondsSinceEpoch,
              normalizedTo.millisecondsSinceEpoch,
            ),
          ),
        )
        .build();
    final results = query.find();
    query.close();

    // Sort ascending by date
    results.sort((a, b) => a.date.compareTo(b.date));
    return results.map((e) => e.toDto()).toList();
  }

  Stream<List<HabitEntryDto>> watchEntriesForHabit(String habitId) {
    return _box
        .query(HabitEntryEntity_.habitId.equals(habitId))
        .watch(triggerImmediately: true)
        .map((query) {
          final list = query.find();
          // Sort ascending by date
          list.sort((a, b) => a.date.compareTo(b.date));
          return list.map((e) => e.toDto()).toList();
        });
  }

  Future<List<HabitEntryDto>> getEntriesForDate(DateTime date) async {
    final normalizedDate = _normalizeDate(date);
    final query = _box
        .query(HabitEntryEntity_.date.equals(normalizedDate.millisecondsSinceEpoch))
        .build();
    final results = query.find();
    query.close();

    return results.map((e) => e.toDto()).toList();
  }

  Future<Map<String, HabitEntryDto?>> getEntryStatusForDate(
    DateTime date,
    List<String> habitIds,
  ) async {
    final normalizedDate = _normalizeDate(date);
    final query = _box
        .query(HabitEntryEntity_.date.equals(normalizedDate.millisecondsSinceEpoch))
        .build();
    final results = query.find();
    query.close();

    final map = <String, HabitEntryDto?>{};
    for (final habitId in habitIds) {
      map[habitId] = null;
    }

    for (final entryEntity in results) {
      if (map.containsKey(entryEntity.habitId)) {
        map[entryEntity.habitId] = entryEntity.toDto();
      }
    }
    return map;
  }

  Future<DateTime?> getLastEntryDateForHabit(String habitId) async {
    final query = _box.query(HabitEntryEntity_.habitId.equals(habitId)).build();
    final results = query.find();
    query.close();

    if (results.isEmpty) return null;

    // Sort descending by date
    results.sort((a, b) => b.date.compareTo(a.date));
    return DateTime.fromMillisecondsSinceEpoch(results.first.date, isUtc: true);
  }

  Future<HabitEntryDto?> getEntryForDate(String habitId, DateTime date) async {
    final normalizedDate = _normalizeDate(date);
    final query = _box
        .query(
          HabitEntryEntity_.habitId.equals(habitId).and(
            HabitEntryEntity_.date.equals(
              normalizedDate.millisecondsSinceEpoch,
            ),
          ),
        )
        .build();
    final result = query.findFirst();
    query.close();
    return result?.toDto();
  }

  Future<void> deleteEntry(String id) async {
    final query = _box.query(HabitEntryEntity_.id.equals(id)).build();
    final ids = query.findIds();
    query.close();
    if (ids.isNotEmpty) {
      _box.removeMany(ids);
    }
  }

  Stream<List<HabitEntryDto>> watchEntriesForDate(DateTime date) {
    final normalizedDate = _normalizeDate(date);
    return _box
        .query(
          HabitEntryEntity_.date.equals(normalizedDate.millisecondsSinceEpoch),
        )
        .watch(triggerImmediately: true)
        .map((query) {
          final list = query.find();
          list.sort((a, b) => a.date.compareTo(b.date));
          return list.map((e) => e.toDto()).toList();
        });
  }
}
