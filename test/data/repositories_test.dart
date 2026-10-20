import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/database/app_database.dart';
import 'package:habit_tracker/data/repositories/repositories.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/domain/enums/enums.dart';

void main() {
  setUp(() async {
    await AppDatabase.openStore();
  });

  tearDown(() {
    AppDatabase.closeStore();
  });

  group('HabitRepository & HabitScheduleRepository transactional flow', () {
    test('createHabit initializes both habit and initial daily schedule', () async {
      final store = AppDatabase.instance;
      final scheduleRepo = HabitScheduleRepository(store);
      final habitRepo = HabitRepository(store, scheduleRepo);

      final created = await habitRepo.createHabit(
        name: 'Test Habit',
        type: HabitType.boolean,
        colorHex: '#FFFFFF',
        iconName: 'check',
        scheduleType: ScheduleType.daily,
      );

      expect(created.name, 'Test Habit');
      expect(created.isArchived, false);

      final fetchedHabit = await habitRepo.getHabitById(created.id);
      expect(fetchedHabit, isNotNull);
      expect(fetchedHabit!.name, 'Test Habit');

      final activeSchedule = await scheduleRepo.getActiveScheduleForHabit(created.id);
      expect(activeSchedule, isNotNull);
      expect(activeSchedule!.scheduleType, ScheduleType.daily);
      expect(activeSchedule.effectiveTo, isNull);
    });

    test('setSchedule closes old schedule and creates new active schedule', () async {
      final store = AppDatabase.instance;
      final scheduleRepo = HabitScheduleRepository(store);
      final habitRepo = HabitRepository(store, scheduleRepo);

      final created = await habitRepo.createHabit(
        name: 'Test Habit',
        type: HabitType.boolean,
        colorHex: '#FFFFFF',
        iconName: 'check',
        scheduleType: ScheduleType.daily,
      );

      final secondDate = DateTime.utc(2026, 2, 1);
      await scheduleRepo.setSchedule(
        habitId: created.id,
        scheduleType: ScheduleType.specificWeekdays,
        scheduledWeekdays: [Weekday.monday, Weekday.friday],
        effectiveFrom: secondDate,
      );

      final history = await scheduleRepo.getScheduleHistoryForHabit(created.id);
      expect(history.length, 2);

      final oldSchedule = history.firstWhere((s) => s.effectiveTo != null);
      expect(oldSchedule.effectiveTo, secondDate);

      final activeSchedule = await scheduleRepo.getActiveScheduleForHabit(created.id);
      expect(activeSchedule, isNotNull);
      expect(activeSchedule!.scheduleType, ScheduleType.specificWeekdays);
      expect(activeSchedule.effectiveTo, isNull);
    });
  });

  group('HabitLimitRepository history & closing', () {
    test('setLimit closes old limit and creates new active limit', () async {
      final store = AppDatabase.instance;
      final scheduleRepo = HabitScheduleRepository(store);
      final habitRepo = HabitRepository(store, scheduleRepo);
      final limitRepo = HabitLimitRepository(store);

      final created = await habitRepo.createHabit(
        name: 'Test Habit',
        type: HabitType.numeric,
        colorHex: '#FFFFFF',
        iconName: 'check',
        scheduleType: ScheduleType.daily,
      );

      final firstDate = DateTime.utc(2026, 1, 1);
      await limitRepo.setLimit(
        habitId: created.id,
        minValue: 0,
        maxValue: 5,
        effectiveFrom: firstDate,
      );

      var activeLimit = await limitRepo.getActiveLimitForHabit(created.id);
      expect(activeLimit, isNotNull);
      expect(activeLimit!.maxValue, 5);
      expect(activeLimit.effectiveTo, isNull);

      final secondDate = DateTime.utc(2026, 2, 1);
      await limitRepo.setLimit(
        habitId: created.id,
        minValue: 0,
        maxValue: 10,
        effectiveFrom: secondDate,
      );

      final history = await limitRepo.getLimitHistoryForHabit(created.id);
      expect(history.length, 2);

      activeLimit = await limitRepo.getActiveLimitForHabit(created.id);
      expect(activeLimit!.maxValue, 10);
      expect(activeLimit.effectiveTo, isNull);
    });
  });

  group('HabitEntryRepository upsert & error paths', () {
    test('upsertEntry creates new entry then updates existing entry on same date', () async {
      final store = AppDatabase.instance;
      final scheduleRepo = HabitScheduleRepository(store);
      final habitRepo = HabitRepository(store, scheduleRepo);
      final entryRepo = HabitEntryRepository(store);

      final created = await habitRepo.createHabit(
        name: 'Test Habit',
        type: HabitType.boolean,
        colorHex: '#FFFFFF',
        iconName: 'check',
        scheduleType: ScheduleType.daily,
      );

      final date = DateTime.utc(2026, 3, 10);
      final firstUpsert = await entryRepo.upsertEntry(
        habitId: created.id,
        date: date,
        value: 1.0,
        note: 'First log',
      );
      expect(firstUpsert.value, 1.0);
      expect(firstUpsert.note, 'First log');

      final secondUpsert = await entryRepo.upsertEntry(
        habitId: created.id,
        date: date,
        value: 2.0,
        note: 'Updated log',
      );
      expect(secondUpsert.id, firstUpsert.id); // Same ID updated
      expect(secondUpsert.value, 2.0);
      expect(secondUpsert.note, 'Updated log');

      final entries = await entryRepo.getEntriesForHabit(
        created.id,
        date.subtract(const Duration(days: 1)),
        date.add(const Duration(days: 1)),
      );
      expect(entries.length, 1);
      expect(entries.first.value, 2.0);
    });

    test('upsertEntry rejects future dates with ArgumentError', () async {
      final store = AppDatabase.instance;
      final scheduleRepo = HabitScheduleRepository(store);
      final habitRepo = HabitRepository(store, scheduleRepo);
      final entryRepo = HabitEntryRepository(store);

      final created = await habitRepo.createHabit(
        name: 'Test Habit',
        type: HabitType.boolean,
        colorHex: '#FFFFFF',
        iconName: 'check',
        scheduleType: ScheduleType.daily,
      );

      final futureDate = DateTime.now().add(const Duration(days: 5));
      expect(
        () => entryRepo.upsertEntry(
          habitId: created.id,
          date: futureDate,
          value: 1.0,
        ),
        throwsArgumentError,
      );
    });

    test('upsertEntry allows creating entry for today in user local timezone', () async {
      final store = AppDatabase.instance;
      final scheduleRepo = HabitScheduleRepository(store);
      final habitRepo = HabitRepository(store, scheduleRepo);
      final entryRepo = HabitEntryRepository(store);

      final created = await habitRepo.createHabit(
        name: 'Today Habit',
        type: HabitType.boolean,
        colorHex: '#FFFFFF',
        iconName: 'check',
        scheduleType: ScheduleType.daily,
      );

      final now = DateTime.now();
      final todayUtc = DateTime.utc(now.year, now.month, now.day);
      final entry = await entryRepo.upsertEntry(
        habitId: created.id,
        date: todayUtc,
        value: 1.0,
      );

      expect(entry.value, 1.0);
      expect(entry.date, todayUtc);
    });

    test('upsertEntry throws StateError when habit does not exist', () async {
      final store = AppDatabase.instance;
      final entryRepo = HabitEntryRepository(store);

      final date = DateTime.utc(2026, 3, 10);
      expect(
        () => entryRepo.upsertEntry(
          habitId: 'non-existent-id',
          date: date,
          value: 1.0,
        ),
        throwsStateError,
      );
    });
  });

  group('HabitRepository archive & stream behavior', () {
    test('archiveHabit hides habit from active watchAllHabits stream', () async {
      final store = AppDatabase.instance;
      final scheduleRepo = HabitScheduleRepository(store);
      final habitRepo = HabitRepository(store, scheduleRepo);

      final created = await habitRepo.createHabit(
        name: 'Test Habit',
        type: HabitType.boolean,
        colorHex: '#FFFFFF',
        iconName: 'check',
        scheduleType: ScheduleType.daily,
      );

      var activeHabits = await habitRepo.watchAllHabits().first;
      expect(activeHabits.length, 1);
      expect(activeHabits.first.id, created.id);

      await habitRepo.archiveHabit(created.id);

      activeHabits = await habitRepo.watchAllHabits().first;
      expect(activeHabits.isEmpty, true);
    });

    test('watchEntriesForHabit emits updated entries when new entry is upserted', () async {
      final store = AppDatabase.instance;
      final scheduleRepo = HabitScheduleRepository(store);
      final habitRepo = HabitRepository(store, scheduleRepo);
      final entryRepo = HabitEntryRepository(store);

      final created = await habitRepo.createHabit(
        name: 'Test Habit',
        type: HabitType.boolean,
        colorHex: '#FFFFFF',
        iconName: 'check',
        scheduleType: ScheduleType.daily,
      );

      expect(await entryRepo.watchEntriesForHabit(created.id).first, isEmpty);

      await entryRepo.upsertEntry(
        habitId: created.id,
        date: DateTime.utc(2026, 3, 10),
        value: 1.0,
      );

      final emitted = await entryRepo.watchEntriesForHabit(created.id).first;
      expect(emitted.length, 1);
      expect(emitted.first.value, 1.0);
    });
  });

  group('UI CRUD operations & Cascade Deletes (Moderate Issue Fixes)', () {
    test('unarchiveHabit restores habit and watchArchivedHabits tracks archived habits', () async {
      final store = AppDatabase.instance;
      final scheduleRepo = HabitScheduleRepository(store);
      final habitRepo = HabitRepository(store, scheduleRepo);

      final created = await habitRepo.createHabit(
        name: 'Archive Test Habit',
        type: HabitType.boolean,
        colorHex: '#FFFFFF',
        iconName: 'check',
        scheduleType: ScheduleType.daily,
      );

      await habitRepo.archiveHabit(created.id);
      expect((await habitRepo.watchArchivedHabits().first).length, 1);
      expect((await habitRepo.watchAllHabits().first).isEmpty, true);

      final unarchived = await habitRepo.unarchiveHabit(created.id);
      expect(unarchived.isArchived, false);
      expect((await habitRepo.watchArchivedHabits().first).isEmpty, true);
      expect((await habitRepo.watchAllHabits().first).length, 1);
    });

    test('deleteHabit cascades deletion to entries, schedules, and limits', () async {
      final store = AppDatabase.instance;
      final scheduleRepo = HabitScheduleRepository(store);
      final habitRepo = HabitRepository(store, scheduleRepo);
      final entryRepo = HabitEntryRepository(store);
      final limitRepo = HabitLimitRepository(store);

      final created = await habitRepo.createHabit(
        name: 'Cascade Delete Habit',
        type: HabitType.numeric,
        colorHex: '#FFFFFF',
        iconName: 'check',
        scheduleType: ScheduleType.daily,
      );

      await limitRepo.setLimit(
        habitId: created.id,
        minValue: 1.0,
        maxValue: 10.0,
        effectiveFrom: DateTime.utc(2026, 1, 1),
      );

      await entryRepo.upsertEntry(
        habitId: created.id,
        date: DateTime.utc(2026, 3, 15),
        value: 5.0,
      );

      expect((await scheduleRepo.getScheduleHistoryForHabit(created.id)).length, 1);
      expect((await limitRepo.getLimitHistoryForHabit(created.id)).length, 1);
      expect((await entryRepo.getEntriesForHabit(created.id, DateTime.utc(2026, 1, 1), DateTime.utc(2026, 12, 31))).length, 1);

      // Perform cascade delete
      await habitRepo.deleteHabit(created.id);

      expect(await habitRepo.getHabitById(created.id), isNull);
      expect((await scheduleRepo.getScheduleHistoryForHabit(created.id)).isEmpty, true);
      expect((await limitRepo.getLimitHistoryForHabit(created.id)).isEmpty, true);
      expect((await entryRepo.getEntriesForHabit(created.id, DateTime.utc(2026, 1, 1), DateTime.utc(2026, 12, 31))).isEmpty, true);
    });

    test('deleteEntry, getEntryForDate, and watchEntriesForDate work correctly', () async {
      final store = AppDatabase.instance;
      final scheduleRepo = HabitScheduleRepository(store);
      final habitRepo = HabitRepository(store, scheduleRepo);
      final entryRepo = HabitEntryRepository(store);

      final created = await habitRepo.createHabit(
        name: 'Entry CRUD Habit',
        type: HabitType.numeric,
        colorHex: '#FFFFFF',
        iconName: 'check',
        scheduleType: ScheduleType.daily,
      );

      final targetDate = DateTime.utc(2026, 4, 1);
      final entry = await entryRepo.upsertEntry(
        habitId: created.id,
        date: targetDate,
        value: 3.0,
      );

      final fetched = await entryRepo.getEntryForDate(created.id, targetDate);
      expect(fetched?.id, entry.id);

      final streamList = await entryRepo.watchEntriesForDate(targetDate).first;
      expect(streamList.length, 1);

      await entryRepo.deleteEntry(entry.id);
      expect(await entryRepo.getEntryForDate(created.id, targetDate), isNull);
    });

    test('removeLimit closes active limit and watchActiveLimitForHabit emits null', () async {
      final store = AppDatabase.instance;
      final scheduleRepo = HabitScheduleRepository(store);
      final habitRepo = HabitRepository(store, scheduleRepo);
      final limitRepo = HabitLimitRepository(store);

      final created = await habitRepo.createHabit(
        name: 'Limit Remove Habit',
        type: HabitType.numeric,
        colorHex: '#FFFFFF',
        iconName: 'check',
        scheduleType: ScheduleType.daily,
      );

      await limitRepo.setLimit(
        habitId: created.id,
        minValue: 0.0,
        maxValue: 5.0,
        effectiveFrom: DateTime.utc(2026, 1, 1),
      );

      expect(await limitRepo.watchActiveLimitForHabit(created.id).first, isNotNull);

      await limitRepo.removeLimit(created.id);
      expect(await limitRepo.getActiveLimitForHabit(created.id), isNull);
    });

    test('watchActiveScheduleForHabit emits current active schedule', () async {
      final store = AppDatabase.instance;
      final scheduleRepo = HabitScheduleRepository(store);
      final habitRepo = HabitRepository(store, scheduleRepo);

      final created = await habitRepo.createHabit(
        name: 'Schedule Watch Habit',
        type: HabitType.boolean,
        colorHex: '#FFFFFF',
        iconName: 'check',
        scheduleType: ScheduleType.daily,
      );

      final active = await scheduleRepo.watchActiveScheduleForHabit(created.id).first;
      expect(active?.scheduleType, ScheduleType.daily);
    });
  });

  group('DayNoteRepository CRUD and query operations', () {
    test('upsertNote creates new note and updates existing note on same date', () async {
      final store = AppDatabase.instance;
      final noteRepo = DayNoteRepository(store);
      final date = DateTime.utc(2026, 10, 20);

      final noteDto = DayNoteDto(
        id: 'note-1',
        habitId: 'habit-101',
        date: date,
        note: 'Feeling energized and finished habit early!',
        createdAt: DateTime.utc(2026, 10, 20, 8, 0),
        updatedAt: DateTime.utc(2026, 10, 20, 8, 0),
      );

      await noteRepo.upsertNote(noteDto);

      final fetched = await noteRepo.getNoteForDate('habit-101', date);
      expect(fetched, isNotNull);
      expect(fetched!.note, 'Feeling energized and finished habit early!');
      expect(fetched.habitId, 'habit-101');

      // Update the same date
      final updatedDto = noteDto.copyWith(note: 'Updated: Actually did 2 sessions today.');
      await noteRepo.upsertNote(updatedDto);

      final updatedFetched = await noteRepo.getNoteForDate('habit-101', date);
      expect(updatedFetched, isNotNull);
      expect(updatedFetched!.note, 'Updated: Actually did 2 sessions today.');
    });

    test('getNotesForHabit returns most recent notes limited to limit', () async {
      final store = AppDatabase.instance;
      final noteRepo = DayNoteRepository(store);

      for (int i = 1; i <= 10; i++) {
        await noteRepo.upsertNote(
          DayNoteDto(
            id: 'note-day-$i',
            habitId: 'habit-history',
            date: DateTime.utc(2026, 10, i),
            note: 'Note for day $i',
            createdAt: DateTime.utc(2026, 10, i, 12, 0),
            updatedAt: DateTime.utc(2026, 10, i, 12, 0),
          ),
        );
      }

      final notes = await noteRepo.getNotesForHabit('habit-history', limit: 7);
      expect(notes.length, 7);
      // Newest first (day 10 at top, day 4 at bottom)
      expect(notes.first.note, 'Note for day 10');
      expect(notes.last.note, 'Note for day 4');
    });

    test('deleteNote removes the note from database', () async {
      final store = AppDatabase.instance;
      final noteRepo = DayNoteRepository(store);
      final date = DateTime.utc(2026, 10, 15);

      await noteRepo.upsertNote(
        DayNoteDto(
          id: 'note-to-delete',
          habitId: 'habit-delete',
          date: date,
          note: 'Temporary note',
          createdAt: DateTime.utc(2026, 10, 15),
          updatedAt: DateTime.utc(2026, 10, 15),
        ),
      );

      expect(await noteRepo.getNoteForDate('habit-delete', date), isNotNull);

      await noteRepo.deleteNote('note-to-delete');
      expect(await noteRepo.getNoteForDate('habit-delete', date), isNull);
    });

    test('HabitRepository.deleteHabit cascade deletes day notes', () async {
      final store = AppDatabase.instance;
      final scheduleRepo = HabitScheduleRepository(store);
      final habitRepo = HabitRepository(store, scheduleRepo);
      final noteRepo = DayNoteRepository(store);

      final habit = await habitRepo.createHabit(
        name: 'Cascade Note Habit',
        type: HabitType.boolean,
        colorHex: '#216CCF',
        iconName: 'check',
        scheduleType: ScheduleType.daily,
      );

      await noteRepo.upsertNote(
        DayNoteDto(
          id: 'note-cascade',
          habitId: habit.id,
          date: DateTime.utc(2026, 10, 20),
          note: 'Note that should be cascaded',
          createdAt: DateTime.utc(2026, 10, 20),
          updatedAt: DateTime.utc(2026, 10, 20),
        ),
      );

      expect(await noteRepo.getNotesForHabit(habit.id), hasLength(1));

      await habitRepo.deleteHabit(habit.id);

      expect(await noteRepo.getNotesForHabit(habit.id), isEmpty);
    });
  });
}
