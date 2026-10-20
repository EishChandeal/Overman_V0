import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/database/app_database.dart';
import 'package:habit_tracker/data/repositories/repositories.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/domain/enums/enums.dart';
import 'package:habit_tracker/application/services/ai_data_formatter.dart';

void main() {
  test('AI Data Preview Generator', () async {
    // 1. Open ObjectBox store
    final store = await AppDatabase.openStore();

    final scheduleRepo = HabitScheduleRepository(store);
    final habitRepo = HabitRepository(store, scheduleRepo);
    final entryRepo = HabitEntryRepository(store);
    final noteRepo = DayNoteRepository(store);

    // 2. Fetch habits
    var habits = await habitRepo.getAllHabits();

    final today = DateTime.utc(2026, 10, 20);
    const windowDays = 7;
    final fromDate = today.subtract(const Duration(days: windowDays - 1));

    // If store is empty, seed realistic sample data to demonstrate preview formatting
    if (habits.isEmpty) {
      // 1. Morning Run (boolean)
      final h1 = await habitRepo.createHabit(
        name: 'Morning Run',
        type: HabitType.boolean,
        colorHex: '#216CCF',
        iconName: 'directions_run',
        scheduleType: ScheduleType.daily,
        description: 'Run at least 3 km each morning to build cardiovascular endurance.',
      );
      await entryRepo.upsertEntry(habitId: h1.id, date: DateTime.utc(2026, 10, 14), value: 1);
      await entryRepo.upsertEntry(habitId: h1.id, date: DateTime.utc(2026, 10, 15), value: 1);
      await entryRepo.upsertEntry(habitId: h1.id, date: DateTime.utc(2026, 10, 16), value: 0);
      await entryRepo.upsertEntry(habitId: h1.id, date: DateTime.utc(2026, 10, 17), value: 1);
      await entryRepo.upsertEntry(habitId: h1.id, date: DateTime.utc(2026, 10, 18), value: 1);
      await entryRepo.upsertEntry(habitId: h1.id, date: DateTime.utc(2026, 10, 19), value: 1);
      // Sun 20 Oct — not tracked (no entry)

      await noteRepo.upsertNote(
        DayNoteDto(
          id: 'note-1',
          habitId: h1.id,
          date: DateTime.utc(2026, 10, 14),
          note: 'Felt strong today, hit 4 km.',
          createdAt: DateTime.utc(2026, 10, 14),
          updatedAt: DateTime.utc(2026, 10, 14),
        ),
      );
      await noteRepo.upsertNote(
        DayNoteDto(
          id: 'note-2',
          habitId: h1.id,
          date: DateTime.utc(2026, 10, 16),
          note: 'Skipped due to rain.',
          createdAt: DateTime.utc(2026, 10, 16),
          updatedAt: DateTime.utc(2026, 10, 16),
        ),
      );

      // 2. Water Intake (numeric)
      final h2 = await habitRepo.createHabit(
        name: 'Water Intake',
        type: HabitType.numeric,
        targetValue: 8,
        unit: 'glasses',
        colorHex: '#33B3FF',
        iconName: 'water_drop',
        scheduleType: ScheduleType.daily,
      );
      await entryRepo.upsertEntry(habitId: h2.id, date: DateTime.utc(2026, 10, 14), value: 7);
      await entryRepo.upsertEntry(habitId: h2.id, date: DateTime.utc(2026, 10, 15), value: 8);
      await entryRepo.upsertEntry(habitId: h2.id, date: DateTime.utc(2026, 10, 16), value: 5);
      await entryRepo.upsertEntry(habitId: h2.id, date: DateTime.utc(2026, 10, 17), value: 8);
      await entryRepo.upsertEntry(habitId: h2.id, date: DateTime.utc(2026, 10, 18), value: 8);
      await entryRepo.upsertEntry(habitId: h2.id, date: DateTime.utc(2026, 10, 19), value: 6);

      // 3. One-time Task: Read 50 Pages (completed)
      await habitRepo.createHabit(
        name: 'Read 50 Pages',
        type: HabitType.boolean,
        colorHex: '#FF9500',
        iconName: 'book',
        scheduleType: ScheduleType.daily,
        isOneTime: true,
        description: 'Finish chapter 3 of Atomic Habits.',
      );
      final allH = await habitRepo.getAllHabits();
      final task1 = allH.firstWhere((h) => h.name == 'Read 50 Pages');
      await habitRepo.updateHabit(
        task1.copyWith(completedAt: DateTime.utc(2026, 10, 14)),
      );

      // 4. One-time Task: File Taxes (pending)
      await habitRepo.createHabit(
        name: 'File Taxes',
        type: HabitType.boolean,
        colorHex: '#AF52DE',
        iconName: 'task_alt',
        scheduleType: ScheduleType.daily,
        isOneTime: true,
      );

      habits = await habitRepo.getAllHabits();
    }

    // 3. Fetch entries for each habit for the window
    final entriesByHabitId = <String, List<HabitEntryDto>>{};
    final dayNotesByHabitId = <String, List<DayNoteDto>>{};
    final schedulesByHabitId = <String, HabitScheduleDto>{};

    for (final habit in habits) {
      final entries = await entryRepo.getEntriesForHabit(habit.id, fromDate, today);
      entriesByHabitId[habit.id] = entries;

      final notes = await noteRepo.getNotesForHabit(habit.id, limit: 30);
      dayNotesByHabitId[habit.id] = notes;

      final sched = await scheduleRepo.getActiveScheduleForHabit(habit.id);
      if (sched != null) {
        schedulesByHabitId[habit.id] = sched;
      }
    }

    // 4. Call AiDataFormatter.format(...)
    final formattedOutput = AiDataFormatter.format(
      habits: habits,
      entriesByHabitId: entriesByHabitId,
      dayNotesByHabitId: dayNotesByHabitId,
      schedulesByHabitId: schedulesByHabitId,
      windowDays: windowDays,
      today: today,
    );

    // 5. Print to stdout
    stdout.write('\n$formattedOutput\n');

    // 6. Write to test/tools/ai_data_preview_output.txt
    final outputFile = File('test/tools/ai_data_preview_output.txt');
    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsString(formattedOutput);

    // 7. Cleanup
    AppDatabase.closeStore();
  });
}
