import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/application/services/data_export_service.dart';
import 'package:habit_tracker/data/database/app_database.dart';
import 'package:habit_tracker/data/database/day_note_entity.dart';
import 'package:habit_tracker/data/database/habit_entity.dart';
import 'package:habit_tracker/data/database/habit_entry_entity.dart';
import 'package:habit_tracker/data/database/habit_limit_entity.dart';
import 'package:habit_tracker/data/database/habit_schedule_entity.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/data/repositories/repositories.dart';
import 'package:habit_tracker/domain/enums/enums.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    await AppDatabase.openStore();
    tempDir = await Directory.systemTemp.createTemp('export_test_');
  });

  tearDown(() async {
    AppDatabase.closeStore();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('DataExportService & HabitRepository import tests', () {
    test('HabitRepository.importHabits merges new habits into store', () async {
      final store = AppDatabase.instance;
      final scheduleRepo = HabitScheduleRepository(store);
      final habitRepo = HabitRepository(store, scheduleRepo);

      final habit1 = HabitDto(
        id: 'h-import-1',
        name: 'Morning Pushups',
        type: HabitType.numeric,
        unit: 'reps',
        targetValue: 50,
        colorHex: '#216CCF',
        iconName: 'fitness_center',
        description: 'Build upper body strength',
        isOneTime: false,
        createdAt: DateTime.utc(2026, 1, 1),
        isArchived: false,
      );

      final habit2 = HabitDto(
        id: 'h-import-2',
        name: 'Pay Insurance',
        type: HabitType.boolean,
        colorHex: '#38A169',
        iconName: 'receipt',
        isOneTime: true,
        completedAt: DateTime.utc(2026, 10, 15),
        createdAt: DateTime.utc(2026, 10, 14),
        isArchived: false,
      );

      await habitRepo.importHabits([habit1, habit2]);

      final fetched1 = await habitRepo.getHabitById('h-import-1');
      expect(fetched1, isNotNull);
      expect(fetched1!.name, 'Morning Pushups');
      expect(fetched1.targetValue, 50);

      final fetched2 = await habitRepo.getHabitById('h-import-2');
      expect(fetched2, isNotNull);
      expect(fetched2!.isOneTime, isTrue);
      expect(fetched2.completedAt, DateTime.utc(2026, 10, 15));

      // Calling again is idempotent (does not duplicate)
      await habitRepo.importHabits([habit1, habit2]);
      final all = await habitRepo.getAllHabits();
      expect(all.length, 2);
    });

    test('exportCsv produces a valid zip file containing habits.csv and entries.csv', () async {
      final store = AppDatabase.instance;

      // Seed 1 habit and 1 entry with commas/quotes to verify CSV escaping
      final habit = HabitEntity(
        id: 'h-csv-1',
        name: 'Read "Deep Work", daily',
        type: 'boolean',
        colorHex: '#216CCF',
        iconName: 'menu_book',
        description: 'Cal Newport, focus book',
        isOneTime: false,
        createdAt: DateTime.utc(2026, 1, 1).millisecondsSinceEpoch,
        isArchived: false,
      );
      store.box<HabitEntity>().put(habit);

      final entry = HabitEntryEntity(
        id: 'e-csv-1',
        habitId: 'h-csv-1',
        date: DateTime.utc(2026, 10, 20).millisecondsSinceEpoch,
        value: 1.0,
        note: 'Read chapter 1, great stuff',
        createdAt: DateTime.utc(2026, 10, 20, 10, 0).millisecondsSinceEpoch,
      );
      store.box<HabitEntryEntity>().put(entry);

      String? sharedPath;
      String? sharedMime;
      final service = DataExportService(
        store,
        directoryProvider: () async => tempDir,
        shareHandler: (path, mime) async {
          sharedPath = path;
          sharedMime = mime;
        },
      );

      final file = await service.exportCsv();
      expect(await file.exists(), isTrue);
      expect(sharedPath, file.path);
      expect(sharedMime, 'application/zip');

      // Unzip and inspect contents
      final zipBytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      final habitsFile = archive.findFile('habits.csv');
      expect(habitsFile, isNotNull);
      final habitsContent = utf8.decode(habitsFile!.content as List<int>);
      expect(habitsContent, contains('id,name,type'));
      expect(habitsContent, contains('"Read ""Deep Work"", daily"'));
      expect(habitsContent, contains('"Cal Newport, focus book"'));

      final entriesFile = archive.findFile('entries.csv');
      expect(entriesFile, isNotNull);
      final entriesContent = utf8.decode(entriesFile!.content as List<int>);
      expect(entriesContent, contains('id,habitId,date,value,note,createdAt'));
      expect(entriesContent, contains('h-csv-1'));
      expect(entriesContent, contains('"Read chapter 1, great stuff"'));
    });

    test('exportJson produces a valid JSON file with full data graph', () async {
      final store = AppDatabase.instance;

      final habit = HabitEntity(
        id: 'h-json-1',
        name: 'Hydration',
        type: 'numeric',
        unit: 'ml',
        targetValue: 2000,
        colorHex: '#216CCF',
        iconName: 'water_drop',
        createdAt: DateTime.utc(2026, 2, 1).millisecondsSinceEpoch,
        isArchived: false,
      );
      store.box<HabitEntity>().put(habit);

      final entry = HabitEntryEntity(
        id: 'e-json-1',
        habitId: 'h-json-1',
        date: DateTime.utc(2026, 10, 21).millisecondsSinceEpoch,
        value: 1500,
        createdAt: DateTime.utc(2026, 10, 21).millisecondsSinceEpoch,
      );
      store.box<HabitEntryEntity>().put(entry);

      final schedule = HabitScheduleEntity(
        id: 's-json-1',
        habitId: 'h-json-1',
        scheduleType: 'daily',
        effectiveFrom: DateTime.utc(2026, 2, 1).millisecondsSinceEpoch,
      );
      store.box<HabitScheduleEntity>().put(schedule);

      final limit = HabitLimitEntity(
        id: 'l-json-1',
        habitId: 'h-json-1',
        minValue: 500,
        maxValue: 5000,
        effectiveFrom: DateTime.utc(2026, 2, 1).millisecondsSinceEpoch,
      );
      store.box<HabitLimitEntity>().put(limit);

      final note = DayNoteEntity(
        id: 'n-json-1',
        habitId: 'h-json-1',
        date: DateTime.utc(2026, 10, 21).millisecondsSinceEpoch,
        note: 'Drank lemon water',
        createdAt: DateTime.utc(2026, 10, 21).millisecondsSinceEpoch,
        updatedAt: DateTime.utc(2026, 10, 21).millisecondsSinceEpoch,
      );
      store.box<DayNoteEntity>().put(note);

      String? sharedMime;
      final service = DataExportService(
        store,
        directoryProvider: () async => tempDir,
        shareHandler: (_, mime) async => sharedMime = mime,
      );

      final file = await service.exportJson();
      expect(await file.exists(), isTrue);
      expect(sharedMime, 'application/json');

      final content = await file.readAsString();
      final decoded = jsonDecode(content) as Map<String, dynamic>;

      expect(decoded['version'], 1);
      expect(decoded['exportedAt'], isNotNull);
      expect(decoded['habits'], isA<List>());
      expect((decoded['habits'] as List).length, 1);
      expect((decoded['habits'] as List).first['name'], 'Hydration');

      expect((decoded['entries'] as List).length, 1);
      expect((decoded['entries'] as List).first['value'], 1500.0);

      expect((decoded['schedules'] as List).length, 1);
      expect((decoded['limits'] as List).length, 1);
      expect((decoded['dayNotes'] as List).length, 1);
    });

    test('exportXlsx produces a valid Excel workbook with Habits and Entries sheets', () async {
      final store = AppDatabase.instance;

      final habit = HabitEntity(
        id: 'h-xlsx-1',
        name: 'Stretching',
        type: 'boolean',
        colorHex: '#E53E3E',
        iconName: 'self_improvement',
        description: 'Morning mobility',
        createdAt: DateTime.utc(2026, 3, 1).millisecondsSinceEpoch,
        isArchived: false,
      );
      store.box<HabitEntity>().put(habit);

      final entry = HabitEntryEntity(
        id: 'e-xlsx-1',
        habitId: 'h-xlsx-1',
        date: DateTime.utc(2026, 10, 21).millisecondsSinceEpoch,
        value: 1.0,
        note: '15 mins routine',
        createdAt: DateTime.utc(2026, 10, 21).millisecondsSinceEpoch,
      );
      store.box<HabitEntryEntity>().put(entry);

      String? sharedMime;
      final service = DataExportService(
        store,
        directoryProvider: () async => tempDir,
        shareHandler: (_, mime) async => sharedMime = mime,
      );

      final file = await service.exportXlsx();
      expect(await file.exists(), isTrue);
      expect(sharedMime, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      expect(excel.sheets.containsKey('Habits'), isTrue);
      expect(excel.sheets.containsKey('Entries'), isTrue);

      final habitsSheet = excel.sheets['Habits']!;
      expect(habitsSheet.maxRows, greaterThanOrEqualTo(2)); // Header + 1 row
      final habitsHeaderRow = habitsSheet.rows.first;
      expect(habitsHeaderRow[0]?.value.toString(), 'id');
      expect(habitsHeaderRow[1]?.value.toString(), 'name');

      final habitsDataRow = habitsSheet.rows[1];
      expect(habitsDataRow[0]?.value.toString(), 'h-xlsx-1');
      expect(habitsDataRow[1]?.value.toString(), 'Stretching');

      final entriesSheet = excel.sheets['Entries']!;
      expect(entriesSheet.maxRows, greaterThanOrEqualTo(2));
      final entriesDataRow = entriesSheet.rows[1];
      expect(entriesDataRow[0]?.value.toString(), 'e-xlsx-1');
      expect(entriesDataRow[1]?.value.toString(), 'h-xlsx-1');
    });
  });
}
