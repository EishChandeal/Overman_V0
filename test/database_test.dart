import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:objectbox/objectbox.dart';
import 'package:habit_tracker/data/database/app_database.dart';
import 'package:habit_tracker/data/database/habit_entity.dart';
import 'package:habit_tracker/data/database/habit_entry_entity.dart';
import 'package:habit_tracker/data/database/habit_limit_entity.dart';
import 'package:habit_tracker/data/database/habit_schedule_entity.dart';
import 'package:habit_tracker/data/database/day_note_entity.dart';
import 'package:habit_tracker/data/database/ai_settings_entity.dart';
import 'package:habit_tracker/data/database/quote_entity.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/domain/enums/enums.dart';

void main() {
  setUp(() async {
    // Open the store in a temporary directory for each test
    await AppDatabase.openStore();
  });

  tearDown(() {
    // Close and reset the store after each test
    AppDatabase.closeStore();
  });

  group('ObjectBox Entity Mapping & DB Operations', () {
    test('HabitEntity mapping and CRUD operations', () async {
      final store = AppDatabase.instance;
      final habitBox = store.box<HabitEntity>();

      final originalDto = HabitDto(
        id: 'habit-uuid-1',
        name: 'Drink Water',
        type: HabitType.numeric,
        unit: 'ml',
        targetValue: 2000,
        colorHex: '#FF00FF',
        iconName: 'water_drop',
        createdAt: DateTime.utc(2026, 6, 27, 10, 0, 0),
        isArchived: false,
      );

      // Map DTO to Entity
      final entity = HabitEntity.fromDto(originalDto);

      // Save to database
      habitBox.put(entity);
      expect(entity.obId, isPositive);

      // Retrieve from database
      final retrievedEntity = habitBox.get(entity.obId);
      expect(retrievedEntity, isNotNull);
      expect(retrievedEntity!.id, 'habit-uuid-1');
      expect(retrievedEntity.name, 'Drink Water');
      expect(retrievedEntity.type, 'numeric');
      expect(retrievedEntity.unit, 'ml');
      expect(retrievedEntity.targetValue, 2000.0);
      expect(retrievedEntity.colorHex, '#FF00FF');
      expect(retrievedEntity.iconName, 'water_drop');
      expect(retrievedEntity.createdAt, originalDto.createdAt.millisecondsSinceEpoch);
      expect(retrievedEntity.isArchived, false);

      // Map back to DTO
      final mappedDto = retrievedEntity.toDto();
      expect(mappedDto, originalDto);
    });

    test('HabitEntryEntity mapping, CRUD, and relationship', () async {
      final store = AppDatabase.instance;
      final habitBox = store.box<HabitEntity>();
      final entryBox = store.box<HabitEntryEntity>();

      // Create and save a HabitEntity
      final habitEntity = HabitEntity(
        id: 'habit-uuid-2',
        name: 'Read Book',
        type: 'boolean',
        colorHex: '#00FF00',
        iconName: 'book',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        isArchived: false,
      );
      habitBox.put(habitEntity);

      final originalEntryDto = HabitEntryDto(
        id: 'entry-uuid-1',
        habitId: 'habit-uuid-2',
        date: DateTime.utc(2026, 6, 27),
        value: 1.0,
        note: 'Finished 2 chapters',
        createdAt: DateTime.utc(2026, 6, 27, 12, 0, 0),
      );

      // Map DTO to Entity
      final entryEntity = HabitEntryEntity.fromDto(originalEntryDto);
      entryEntity.habitEntity.target = habitEntity; // Setup relation

      // Save to database
      entryBox.put(entryEntity);
      expect(entryEntity.obId, isPositive);

      // Retrieve entry and verify relation
      final retrievedEntry = entryBox.get(entryEntity.obId);
      expect(retrievedEntry, isNotNull);
      expect(retrievedEntry!.id, 'entry-uuid-1');
      expect(retrievedEntry.habitId, 'habit-uuid-2');
      expect(retrievedEntry.habitEntity.target, isNotNull);
      expect(retrievedEntry.habitEntity.target!.name, 'Read Book');

      // Map back to DTO
      final mappedEntryDto = retrievedEntry.toDto();
      expect(mappedEntryDto, originalEntryDto);
    });

    test('HabitLimitEntity mapping and CRUD', () async {
      final store = AppDatabase.instance;
      final limitBox = store.box<HabitLimitEntity>();

      final originalLimitDto = HabitLimitDto(
        id: 'limit-uuid-1',
        habitId: 'habit-uuid-2',
        minValue: 10,
        maxValue: 50,
        effectiveFrom: DateTime.utc(2026, 6, 27),
        effectiveTo: DateTime.utc(2026, 12, 31),
      );

      final limitEntity = HabitLimitEntity.fromDto(originalLimitDto);
      limitBox.put(limitEntity);
      expect(limitEntity.obId, isPositive);

      final retrievedLimit = limitBox.get(limitEntity.obId);
      expect(retrievedLimit, isNotNull);
      expect(retrievedLimit!.minValue, 10.0);
      expect(retrievedLimit.maxValue, 50.0);

      final mappedLimitDto = retrievedLimit.toDto();
      expect(mappedLimitDto, originalLimitDto);
    });

    test('HabitScheduleEntity mapping and CRUD', () async {
      final store = AppDatabase.instance;
      final scheduleBox = store.box<HabitScheduleEntity>();

      final originalScheduleDto = HabitScheduleDto(
        id: 'schedule-uuid-1',
        habitId: 'habit-uuid-2',
        scheduleType: ScheduleType.specificWeekdays,
        scheduledWeekdays: [Weekday.monday, Weekday.wednesday, Weekday.friday],
        targetCount: 3,
        effectiveFrom: DateTime.utc(2026, 6, 27),
        effectiveTo: null,
      );

      final scheduleEntity = HabitScheduleEntity.fromDto(originalScheduleDto);
      scheduleBox.put(scheduleEntity);
      expect(scheduleEntity.obId, isPositive);

      final retrievedSchedule = scheduleBox.get(scheduleEntity.obId);
      expect(retrievedSchedule, isNotNull);
      expect(retrievedSchedule!.scheduledWeekdays, containsAll(['monday', 'wednesday', 'friday']));

      final mappedScheduleDto = retrievedSchedule.toDto();
      expect(mappedScheduleDto, originalScheduleDto);
    });

    test('HabitEntity relations are persisted and retrieved', () async {
      final store = AppDatabase.instance;
      final habitBox = store.box<HabitEntity>();

      final habit = HabitEntity(
        id: 'habit-relation-uuid',
        name: 'Relation Test',
        type: 'boolean',
        colorHex: '#000000',
        iconName: 'star',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        isArchived: false,
      );

      final entry = HabitEntryEntity(
        id: 'entry-relation-uuid',
        habitId: 'habit-relation-uuid',
        date: DateTime.now().millisecondsSinceEpoch,
        value: 1.0,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final limit = HabitLimitEntity(
        id: 'limit-relation-uuid',
        habitId: 'habit-relation-uuid',
        effectiveFrom: DateTime.now().millisecondsSinceEpoch,
      );

      final schedule = HabitScheduleEntity(
        id: 'schedule-relation-uuid',
        habitId: 'habit-relation-uuid',
        scheduleType: 'daily',
        effectiveFrom: DateTime.now().millisecondsSinceEpoch,
      );

      // Add to relations
      habit.entries.add(entry);
      habit.limits.add(limit);
      habit.schedules.add(schedule);

      // Putting habit should cascade put relations
      habitBox.put(habit);

      // Fetch from DB
      final retrieved = habitBox.get(habit.obId);
      expect(retrieved, isNotNull);
      expect(retrieved!.entries, hasLength(1));
      expect(retrieved.limits, hasLength(1));
      expect(retrieved.schedules, hasLength(1));

      expect(retrieved.entries.first.id, 'entry-relation-uuid');
      expect(retrieved.limits.first.id, 'limit-relation-uuid');
      expect(retrieved.schedules.first.id, 'schedule-relation-uuid');
    });

    test('HabitLimitEntity and HabitScheduleEntity relation to HabitEntity', () async {
      final store = AppDatabase.instance;
      final habitBox = store.box<HabitEntity>();
      final limitBox = store.box<HabitLimitEntity>();
      final scheduleBox = store.box<HabitScheduleEntity>();

      final habit = HabitEntity(
        id: 'habit-toone-uuid',
        name: 'ToOne Test',
        type: 'boolean',
        colorHex: '#000000',
        iconName: 'star',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        isArchived: false,
      );
      habitBox.put(habit);

      final limit = HabitLimitEntity(
        id: 'limit-toone-uuid',
        habitId: 'habit-toone-uuid',
        effectiveFrom: DateTime.now().millisecondsSinceEpoch,
      );
      limit.habitEntity.target = habit;
      limitBox.put(limit);

      final schedule = HabitScheduleEntity(
        id: 'schedule-toone-uuid',
        habitId: 'habit-toone-uuid',
        scheduleType: 'daily',
        effectiveFrom: DateTime.now().millisecondsSinceEpoch,
      );
      schedule.habitEntity.target = habit;
      scheduleBox.put(schedule);

      // Retrieve and check ToOne target
      final retrievedLimit = limitBox.get(limit.obId);
      expect(retrievedLimit, isNotNull);
      expect(retrievedLimit!.habitEntity.target, isNotNull);
      expect(retrievedLimit.habitEntity.target!.id, 'habit-toone-uuid');

      final retrievedSchedule = scheduleBox.get(schedule.obId);
      expect(retrievedSchedule, isNotNull);
      expect(retrievedSchedule!.habitEntity.target, isNotNull);
      expect(retrievedSchedule.habitEntity.target!.id, 'habit-toone-uuid');
    });

    test('HabitScheduleEntity handles null scheduledWeekdays and effectiveTo', () {
      final dto = HabitScheduleDto(
        id: 'schedule-nulls-uuid',
        habitId: 'habit-nulls-uuid',
        scheduleType: ScheduleType.daily,
        scheduledWeekdays: null,
        targetCount: null,
        effectiveFrom: DateTime.utc(2026, 6, 29),
        effectiveTo: null,
      );

      final entity = HabitScheduleEntity.fromDto(dto);
      expect(entity.scheduledWeekdays, isNull);
      expect(entity.effectiveTo, isNull);

      final mappedDto = entity.toDto();
      expect(mappedDto.scheduledWeekdays, isNull);
      expect(mappedDto.effectiveTo, isNull);
    });

    test('HabitDto equality mapping field by field', () {
      final dto = HabitDto(
        id: 'habit-eq-uuid',
        name: 'Exercise',
        type: HabitType.boolean,
        unit: 'times',
        targetValue: 1,
        colorHex: '#123456',
        iconName: 'run',
        createdAt: DateTime.utc(2026, 6, 29, 8, 0, 0),
        isArchived: true,
      );

      final entity = HabitEntity.fromDto(dto);
      final mapped = entity.toDto();

      expect(mapped.id, dto.id);
      expect(mapped.name, dto.name);
      expect(mapped.type, dto.type);
      expect(mapped.unit, dto.unit);
      expect(mapped.targetValue, dto.targetValue);
      expect(mapped.colorHex, dto.colorHex);
      expect(mapped.iconName, dto.iconName);
      expect(mapped.createdAt, dto.createdAt);
      expect(mapped.isArchived, dto.isArchived);
    });

    test('Duplicate id throws UniqueViolationException', () async {
      final store = AppDatabase.instance;
      final habitBox = store.box<HabitEntity>();

      final originalDto1 = HabitDto(
        id: 'duplicate-uuid',
        name: 'Habit 1',
        type: HabitType.boolean,
        colorHex: '#000000',
        iconName: 'star',
        createdAt: DateTime.utc(2026, 6, 29),
        isArchived: false,
      );

      final originalDto2 = HabitDto(
        id: 'duplicate-uuid', // Same UUID business key
        name: 'Habit 2',
        type: HabitType.numeric,
        colorHex: '#FFFFFF',
        iconName: 'heart',
        createdAt: DateTime.utc(2026, 6, 29),
        isArchived: false,
      );

      final entity1 = HabitEntity.fromDto(originalDto1);
      final entity2 = HabitEntity.fromDto(originalDto2);

      // Insert first one - should succeed
      habitBox.put(entity1);

      // Insert second one - should throw UniqueViolationException because 'id' is annotated with @Unique()
      expect(() => habitBox.put(entity2), throwsA(isA<UniqueViolationException>()));
    });

    test('HabitDto and HabitEntity handle description, isOneTime, and completedAt', () {
      final store = AppDatabase.instance;
      final habitBox = store.box<HabitEntity>();

      final oneTimeDto = HabitDto(
        id: 'one-time-uuid-1',
        name: 'Finish Tax Forms',
        type: HabitType.boolean,
        colorHex: '#123456',
        iconName: 'receipt',
        description: 'Need to submit before midnight',
        isOneTime: true,
        completedAt: DateTime.utc(2026, 10, 20, 15, 30),
        createdAt: DateTime.utc(2026, 10, 20, 10, 0),
        isArchived: false,
      );

      final entity = HabitEntity.fromDto(oneTimeDto);
      habitBox.put(entity);

      final retrieved = habitBox.get(entity.obId);
      expect(retrieved, isNotNull);
      expect(retrieved!.description, 'Need to submit before midnight');
      expect(retrieved.isOneTime, isTrue);
      expect(retrieved.completedAt, oneTimeDto.completedAt!.millisecondsSinceEpoch);

      final dtoFromDb = retrieved.toDto();
      expect(dtoFromDb, equals(oneTimeDto));
      expect(dtoFromDb.description, 'Need to submit before midnight');
      expect(dtoFromDb.isOneTime, isTrue);
      expect(dtoFromDb.completedAt, oneTimeDto.completedAt);
    });

    test('DayNoteEntity mapping, CRUD, and DTO round-trip', () {
      final dayNoteBox = AppDatabase.dayNoteBox;

      final originalDto = DayNoteDto(
        id: 'note-uuid-1',
        habitId: 'habit-uuid-1',
        date: DateTime.utc(2026, 10, 20),
        note: 'Felt very energized today and finished early.',
        createdAt: DateTime.utc(2026, 10, 20, 18, 0),
        updatedAt: DateTime.utc(2026, 10, 20, 18, 5),
      );

      final entity = DayNoteEntity.fromDto(originalDto);
      dayNoteBox.put(entity);
      expect(entity.obId, isPositive);

      final retrieved = dayNoteBox.get(entity.obId);
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'note-uuid-1');
      expect(retrieved.habitId, 'habit-uuid-1');
      expect(retrieved.note, 'Felt very energized today and finished early.');
      expect(retrieved.date, originalDto.date.millisecondsSinceEpoch);

      final retrievedDto = retrieved.toDto();
      expect(retrievedDto, equals(originalDto));
      expect(retrievedDto.toJson()['note'], originalDto.note);
      expect(DayNoteDto.fromJson(retrievedDto.toJson()), equals(originalDto));
    });

    test('AiSettingsEntity mapping, CRUD, and DTO round-trip', () {
      final aiSettingsBox = AppDatabase.aiSettingsBox;

      final originalDto = AiSettingsDto(
        apiEndpoint: 'https://generativelanguage.googleapis.com/v1beta',
        apiKey: 'test-api-key-12345',
        selectedPersona: 'vegeta',
        updatedAt: DateTime.utc(2026, 10, 20, 12, 0),
      );

      final entity = AiSettingsEntity.fromDto(originalDto);
      aiSettingsBox.put(entity);
      expect(entity.obId, isPositive);

      final retrieved = aiSettingsBox.get(entity.obId);
      expect(retrieved, isNotNull);
      expect(retrieved!.apiEndpoint, 'https://generativelanguage.googleapis.com/v1beta');
      expect(retrieved.apiKey, 'test-api-key-12345');
      expect(retrieved.selectedPersona, 'vegeta');

      final retrievedDto = retrieved.toDto();
      expect(retrievedDto, equals(originalDto));
      expect(AiSettingsDto.fromJson(retrievedDto.toJson()), equals(originalDto));
    });

    test('QuoteEntity mapping, CRUD, and DTO round-trip', () {
      final quoteBox = AppDatabase.quoteBox;

      const originalDto = QuoteDto(
        id: 'quote-uuid-1',
        text: 'Become who you are.',
        author: 'Friedrich Nietzsche',
        dayOfYear: null,
        isActive: true,
      );

      final entity = QuoteEntity.fromDto(originalDto);
      quoteBox.put(entity);
      expect(entity.obId, isPositive);

      final retrieved = quoteBox.get(entity.obId);
      expect(retrieved, isNotNull);
      expect(retrieved!.text, 'Become who you are.');
      expect(retrieved.author, 'Friedrich Nietzsche');
      expect(retrieved.dayOfYear, isNull);
      expect(retrieved.isActive, isTrue);

      final retrievedDto = retrieved.toDto();
      expect(retrievedDto, equals(originalDto));
      expect(QuoteDto.fromJson(retrievedDto.toJson()), equals(originalDto));
    });
  });

  group('Database instance management', () {
    test('instance throws StateError if not opened first', () {
      AppDatabase.closeStore();
      expect(() => AppDatabase.instance, throwsA(isA<StateError>()));
    });
  });

  group('Database directory options', () {
    test('AppDatabase opens store in custom directory', () async {
      // Close the default store first to avoid concurrent store open issues
      AppDatabase.closeStore();

      final customDir = Directory.systemTemp.createTempSync('custom_objectbox_test');
      try {
        final store = await AppDatabase.openStore(directory: customDir.path);
        expect(store, isNotNull);

        // Check that DB files are created inside the custom directory
        final files = customDir.listSync();
        expect(files.isNotEmpty, isTrue);

        // Verify it contains a file with data.mdb or similar
        final fileNames = files.map((f) => f.path.split(Platform.pathSeparator).last);
        expect(fileNames.any((name) => name == 'data.mdb' || name == 'lock.mdb'), isTrue);
      } finally {
        AppDatabase.closeStore();
        if (customDir.existsSync()) {
          customDir.deleteSync(recursive: true);
        }
      }
    });
  });
}
