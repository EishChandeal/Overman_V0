import 'package:uuid/uuid.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/data/database/day_note_entity.dart';
import 'package:habit_tracker/objectbox.g.dart';

class DayNoteRepository {
  final Store _store;
  late final Box<DayNoteEntity> _box;

  DayNoteRepository(this._store) {
    _box = _store.box<DayNoteEntity>();
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  Future<void> upsertNote(DayNoteDto dto) async {
    final normalizedDate = _normalizeDate(dto.date);
    final dateMillis = normalizedDate.millisecondsSinceEpoch;

    final query = _box
        .query(
          DayNoteEntity_.habitId.equals(dto.habitId).and(
            DayNoteEntity_.date.equals(dateMillis),
          ),
        )
        .build();
    final existing = query.findFirst();
    query.close();

    final nowUtc = DateTime.now().toUtc().millisecondsSinceEpoch;

    if (existing != null) {
      existing.note = dto.note;
      existing.updatedAt = nowUtc;
      _box.put(existing);
    } else {
      final entity = DayNoteEntity(
        id: dto.id.isEmpty ? const Uuid().v4() : dto.id,
        habitId: dto.habitId,
        date: dateMillis,
        note: dto.note,
        createdAt: dto.createdAt.millisecondsSinceEpoch == 0
            ? nowUtc
            : dto.createdAt.millisecondsSinceEpoch,
        updatedAt: nowUtc,
      );
      _box.put(entity);
    }
  }

  Future<DayNoteDto?> getNoteForDate(String habitId, DateTime date) async {
    final normalizedDate = _normalizeDate(date);
    final query = _box
        .query(
          DayNoteEntity_.habitId.equals(habitId).and(
            DayNoteEntity_.date.equals(normalizedDate.millisecondsSinceEpoch),
          ),
        )
        .build();
    final entity = query.findFirst();
    query.close();
    return entity?.toDto();
  }

  Future<List<DayNoteDto>> getNotesForHabit(
    String habitId, {
    int limit = 7,
  }) async {
    final query = _box.query(DayNoteEntity_.habitId.equals(habitId)).build();
    final results = query.find();
    query.close();

    // Sort descending by date (most recent first)
    results.sort((a, b) => b.date.compareTo(a.date));
    return results.take(limit).map((e) => e.toDto()).toList();
  }

  Stream<List<DayNoteDto>> watchNotesForHabit(
    String habitId, {
    int limit = 7,
  }) {
    return _box
        .query(DayNoteEntity_.habitId.equals(habitId))
        .watch(triggerImmediately: true)
        .map((query) {
          final results = query.find();
          // Sort descending by date (most recent first)
          results.sort((a, b) => b.date.compareTo(a.date));
          return results.take(limit).map((e) => e.toDto()).toList();
        });
  }

  Future<void> deleteNote(String noteId) async {
    final query = _box.query(DayNoteEntity_.id.equals(noteId)).build();
    final ids = query.findIds();
    query.close();
    if (ids.isNotEmpty) {
      _box.removeMany(ids);
    }
  }
}
