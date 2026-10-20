import 'dart:io';
import '../../objectbox.g.dart';
import 'habit_entity.dart';
import 'habit_entry_entity.dart';
import 'habit_limit_entity.dart';
import 'habit_schedule_entity.dart';
import 'day_note_entity.dart';
import 'ai_settings_entity.dart';
import 'quote_entity.dart';

class AppDatabase {
  static Store? _store;

  static Future<Store> openStore({String? directory}) async {
    if (_store != null) {
      return _store!;
    }

    final path = directory ??
        (await Directory.systemTemp.createTemp('objectbox_test')).path;

    _store = Store(
      getObjectBoxModel(),
      directory: path,
    );
    return _store!;
  }

  static Store get instance {
    final store = _store;
    if (store == null) {
      throw StateError('Store has not been opened. Call openStore() first.');
    }
    return store;
  }

  static void closeStore() {
    _store?.close();
    _store = null;
  }

  // Entity box accessors
  static Box<HabitEntity> get habitBox => instance.box<HabitEntity>();
  static Box<HabitEntryEntity> get habitEntryBox => instance.box<HabitEntryEntity>();
  static Box<HabitLimitEntity> get habitLimitBox => instance.box<HabitLimitEntity>();
  static Box<HabitScheduleEntity> get habitScheduleBox => instance.box<HabitScheduleEntity>();
  static Box<DayNoteEntity> get dayNoteBox => instance.box<DayNoteEntity>();
  static Box<AiSettingsEntity> get aiSettingsBox => instance.box<AiSettingsEntity>();
  static Box<QuoteEntity> get quoteBox => instance.box<QuoteEntity>();
}
