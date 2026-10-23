import 'package:uuid/uuid.dart';
import '../../objectbox.g.dart';
import '../database/app_session_entity.dart';
import '../models/dtos/app_session_dto.dart';

/// Repository managing app-open session tracking in ObjectBox.
class AppSessionRepository {
  final Store _store;
  late final Box<AppSessionEntity> _box;

  AppSessionRepository(this._store) {
    _box = _store.box<AppSessionEntity>();
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  /// Called on every app open; records an entry for today if not already present.
  Future<void> recordTodayIfAbsent({DateTime? now}) async {
    final effectiveNow = now ?? DateTime.now();
    final normalized = _normalizeDate(effectiveNow);
    final dateMillis = normalized.millisecondsSinceEpoch;

    final query = _box.query(AppSessionEntity_.date.equals(dateMillis)).build();
    final existing = query.findFirst();
    query.close();

    if (existing == null) {
      final entity = AppSessionEntity(
        id: const Uuid().v4(),
        date: dateMillis,
        createdAt: effectiveNow.millisecondsSinceEpoch,
      );
      _box.put(entity);
    }
  }

  /// Returns total number of unique calendar days the app was opened.
  Future<int> totalDaysOpened() async {
    return _box.count();
  }

  /// Returns the current consecutive streak of days the user opened the app.
  /// Consecutive days ending on [today] (or yesterday if not yet recorded today).
  Future<int> currentOpenStreak({DateTime? today}) async {
    final query = _box.query().build();
    final allEntities = query.find();
    query.close();

    if (allEntities.isEmpty) return 0;

    final recordedDates = allEntities.map((e) => e.date).toSet();

    final refDate = _normalizeDate(today ?? DateTime.now());
    final todayMillis = refDate.millisecondsSinceEpoch;
    final yesterdayMillis =
        refDate.subtract(const Duration(days: 1)).millisecondsSinceEpoch;

    DateTime checkDate;
    if (recordedDates.contains(todayMillis)) {
      checkDate = refDate;
    } else if (recordedDates.contains(yesterdayMillis)) {
      checkDate = refDate.subtract(const Duration(days: 1));
    } else {
      return 0;
    }

    int streak = 0;
    while (recordedDates.contains(checkDate.millisecondsSinceEpoch)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Watches all sessions ordered by date descending.
  Stream<List<AppSessionDto>> watchAll() {
    return _box
        .query()
        .order(AppSessionEntity_.date, flags: Order.descending)
        .watch(triggerImmediately: true)
        .map((query) => query.find().map((e) => e.toDto()).toList());
  }
}
