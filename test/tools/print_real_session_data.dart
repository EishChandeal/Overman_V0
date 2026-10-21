import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:habit_tracker/data/repositories/repositories.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/application/services/ai_data_formatter.dart';
import 'package:habit_tracker/objectbox.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Print Real In-App ObjectBox Session Data', () async {
    // 1. Resolve real app documents directory (where main.dart stores the ObjectBox database)
    String realDirPath;
    if (Platform.isWindows) {
      realDirPath = p.join(Platform.environment['USERPROFILE'] ?? '', 'Documents');
    } else {
      realDirPath = p.join(Platform.environment['HOME'] ?? '', 'Documents');
    }

    // Verify data.mdb exists
    final mdbFile = File(p.join(realDirPath, 'data.mdb'));
    if (!mdbFile.existsSync()) {
      print('\n[ERROR] No data.mdb found at: $realDirPath');
      print('Please run the app at least once so ObjectBox initializes the database.');
      return;
    }

    // 2. Open store (with snapshot copy fallback if the app is currently open and holding the lock)
    Store store;
    String openedFrom = realDirPath;
    Directory? tempCopyDir;

    try {
      store = Store(getObjectBoxModel(), directory: realDirPath);
    } catch (_) {
      // If locked by a currently running app instance, copy to a temp directory and open the live snapshot
      tempCopyDir = await Directory.systemTemp.createTemp('overman_real_snapshot_');
      await mdbFile.copy(p.join(tempCopyDir.path, 'data.mdb'));
      final lockFile = File(p.join(realDirPath, 'lock.mdb'));
      if (lockFile.existsSync()) {
        try {
          await lockFile.copy(p.join(tempCopyDir.path, 'lock.mdb'));
        } catch (_) {}
      }
      openedFrom = '${tempCopyDir.path} (snapshot copy of $realDirPath)';
      store = Store(getObjectBoxModel(), directory: tempCopyDir.path);
    }

    try {
      final scheduleRepo = HabitScheduleRepository(store);
      final habitRepo = HabitRepository(store, scheduleRepo);
      final entryRepo = HabitEntryRepository(store);
      final noteRepo = DayNoteRepository(store);

      // Fetch all real habits created by user in app
      final habits = await habitRepo.getAllHabits();

      final now = DateTime.now();
      final today = DateTime.utc(now.year, now.month, now.day);
      const windowDays = 7;
      final fromDate = today.subtract(const Duration(days: windowDays - 1));

      // Fetch entries, notes, schedules for each real habit
      final entriesByHabitId = <String, List<HabitEntryDto>>{};
      final dayNotesByHabitId = <String, List<DayNoteDto>>{};
      final schedulesByHabitId = <String, HabitScheduleDto>{};

      int totalEntriesCount = 0;
      int totalNotesCount = 0;

      for (final habit in habits) {
        final entries = await entryRepo.getEntriesForHabit(habit.id, fromDate, today);
        entriesByHabitId[habit.id] = entries;
        totalEntriesCount += entries.length;

        final notes = await noteRepo.getNotesForHabit(habit.id, limit: 30);
        dayNotesByHabitId[habit.id] = notes;
        totalNotesCount += notes.length;

        final sched = await scheduleRepo.getActiveScheduleForHabit(habit.id);
        if (sched != null) {
          schedulesByHabitId[habit.id] = sched;
        }
      }

      final formattedOutput = AiDataFormatter.format(
        habits: habits,
        entriesByHabitId: entriesByHabitId,
        dayNotesByHabitId: dayNotesByHabitId,
        schedulesByHabitId: schedulesByHabitId,
        windowDays: windowDays,
        today: today,
      );

      print('\n' + '=' * 68);
      print('       REAL IN-APP OBJECTBOX DATABASE SESSION — 7-DAY RETRIEVAL');
      print('=' * 68);
      print('\n[DATABASE SOURCE]');
      print('• Database location:   $openedFrom');
      print('• File size:           ${(mdbFile.lengthSync() / 1024).toStringAsFixed(1)} KB');
      print('• Last modified:       ${mdbFile.lastModifiedSync()}');
      print('\n[RETRIEVAL METRICS]');
      print('• Real habits/tasks:   ${habits.length}');
      print('• Entries (last 7d):   $totalEntriesCount');
      print('• Day notes logged:    $totalNotesCount');
      print('• Query date range:    ${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')} to ${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')} ($windowDays days)');

      if (habits.isEmpty) {
        print('\n[STATUS] Database currently contains 0 habits or tasks.');
        print('Add a habit or task in the app, and run this script again!');
      } else {
        print('\n[IN-APP HABITS & TASKS FOUND IN OBJECTBOX]');
        for (final h in habits) {
          final kind = h.isOneTime ? 'One-time Task' : 'Habit (${h.type.name})';
          final status = h.isOneTime
              ? (h.completedAt != null ? 'Completed (${h.completedAt!.toLocal()})' : 'Pending')
              : (h.isArchived ? 'Archived' : 'Active');
          final desc = h.description != null ? ' | Reason: "${h.description}"' : '';
          print('• "${h.name}" [$kind] — $status$desc');
        }

        print('\n' + '-' * 68);
        print('PART 1: REAL USER HABIT DATA FORMATTED FOR AI');
        print('-' * 68 + '\n');
        print(formattedOutput);

        print('-' * 68);
        print('PART 2: HOW THIS REAL DATA IS ASSEMBLED FOR THE AI (e.g. Friedrich Nietzsche)');
        print('-' * 68);
        print('''
[YOUR PERSONA]
Name: Friedrich Nietzsche
Role: The philosopher of the "overman" (Übermensch).
System Prompt:
"The man himself, and whom this app is named after. He will guide the user
with his philosophical ideas of the 'overman' (Übermensch), the ideal MAN,
and with his wit and heavy words that carry weight, sharp insights, and ruthless
presentation of truth without appeasing the user. In a tough, unapologetic way,
he will help them become the best version of themselves."

[USER'S PAST DATA]
$formattedOutput

[USER'S MESSAGE]
"Review my progress this week and tell me what I need to improve."
''');
      }
      print('=' * 68 + '\n');

      // Also save to test/tools/real_session_preview_output.txt
      final out = File('test/tools/real_session_preview_output.txt');
      await out.writeAsString(formattedOutput);

    } finally {
      store.close();
      if (tempCopyDir != null) {
        try {
          await tempCopyDir.delete(recursive: true);
        } catch (_) {}
      }
    }
  });
}
