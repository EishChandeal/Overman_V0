import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:habit_tracker/data/database/day_note_entity.dart';
import 'package:habit_tracker/data/database/habit_entity.dart';
import 'package:habit_tracker/data/database/habit_entry_entity.dart';
import 'package:habit_tracker/data/database/habit_limit_entity.dart';
import 'package:habit_tracker/data/database/habit_schedule_entity.dart';
import 'package:habit_tracker/objectbox.g.dart';

/// Service responsible for exporting local habit data into CSV (zipped), JSON, and XLSX formats.
class DataExportService {
  final Store _store;
  final Future<Directory> Function()? _directoryProvider;
  final Future<void> Function(String filePath, String mimeType)? _shareHandler;

  DataExportService(
    this._store, {
    Future<Directory> Function()? directoryProvider,
    Future<void> Function(String filePath, String mimeType)? shareHandler,
  })  : _directoryProvider = directoryProvider,
        _shareHandler = shareHandler;

  bool get _isTestEnvironment {
    return Platform.script.path.contains('test') ||
        Platform.environment.containsKey('FLUTTER_TEST');
  }

  /// Resolves target directory for exported files (Downloads if available, fallback to App Documents).
  Future<Directory> _getTargetDirectory() async {
    if (_directoryProvider != null) {
      return await _directoryProvider();
    }

    // In automated test environments, avoid native channels
    if (_isTestEnvironment) {
      return Directory.systemTemp.createTempSync('overman_export_test');
    }

    try {
      final downloadsDir = await getDownloadsDirectory().timeout(
        const Duration(milliseconds: 600),
      );
      if (downloadsDir != null && await downloadsDir.exists()) {
        return downloadsDir;
      }
    } catch (_) {
      // Ignore platform-specific failure and fallback
    }

    try {
      return await getApplicationDocumentsDirectory().timeout(
        const Duration(milliseconds: 600),
      );
    } catch (_) {
      return Directory.systemTemp;
    }
  }

  /// Triggers device share sheet if supported on platform.
  Future<void> _share(File file, String mimeType) async {
    if (_shareHandler != null) {
      await _shareHandler(file.path, mimeType);
      return;
    }

    if (_isTestEnvironment) {
      return; // Skip platform channel during tests
    }

    try {
      await SharePlus.instance
          .share(
            ShareParams(
              files: [XFile(file.path, mimeType: mimeType)],
              text: 'Overman Habit Data Export',
            ),
          )
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // Ignored if platform doesn't have native sharing support (e.g. desktop headless)
    }
  }

  /// Exports all habits and entries into two CSV files zipped together (`habits.csv` + `entries.csv`).
  Future<File> exportCsv({String? customDirectory}) async {
    final habits = _store.box<HabitEntity>().getAll().map((e) => e.toDto()).toList();
    final entries = _store.box<HabitEntryEntity>().getAll().map((e) => e.toDto()).toList();

    // 1. Generate habits.csv
    final habitsCsvBuffer = StringBuffer();
    habitsCsvBuffer.writeln(
      'id,name,type,unit,targetValue,colorHex,iconName,description,isOneTime,completedAt,createdAt,isArchived',
    );
    for (final h in habits) {
      habitsCsvBuffer.writeln([
        _escapeCsv(h.id),
        _escapeCsv(h.name),
        _escapeCsv(h.type.name),
        _escapeCsv(h.unit),
        _escapeCsv(h.targetValue),
        _escapeCsv(h.colorHex),
        _escapeCsv(h.iconName),
        _escapeCsv(h.description),
        _escapeCsv(h.isOneTime),
        _escapeCsv(h.completedAt?.toIso8601String()),
        _escapeCsv(h.createdAt.toIso8601String()),
        _escapeCsv(h.isArchived),
      ].join(','));
    }

    // 2. Generate entries.csv
    final entriesCsvBuffer = StringBuffer();
    entriesCsvBuffer.writeln('id,habitId,date,value,note,createdAt');
    for (final e in entries) {
      entriesCsvBuffer.writeln([
        _escapeCsv(e.id),
        _escapeCsv(e.habitId),
        _escapeCsv(e.date.toIso8601String()),
        _escapeCsv(e.value),
        _escapeCsv(e.note),
        _escapeCsv(e.createdAt.toIso8601String()),
      ].join(','));
    }

    // 3. Compress into zip
    final archive = Archive();
    final habitsBytes = utf8.encode(habitsCsvBuffer.toString());
    archive.addFile(ArchiveFile('habits.csv', habitsBytes.length, habitsBytes));

    final entriesBytes = utf8.encode(entriesCsvBuffer.toString());
    archive.addFile(ArchiveFile('entries.csv', entriesBytes.length, entriesBytes));

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) {
      throw StateError('Failed to encode zip archive.');
    }

    final targetDir = customDirectory != null
        ? Directory(customDirectory)
        : await _getTargetDirectory();
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(p.join(targetDir.path, 'overman_export_$timestamp.zip'));
    file.writeAsBytesSync(zipBytes);

    await _share(file, 'application/zip');
    return file;
  }

  /// Exports the full data graph into a single JSON file.
  Future<File> exportJson({String? customDirectory}) async {
    final habits = _store.box<HabitEntity>().getAll().map((e) => e.toDto().toJson()).toList();
    final entries = _store.box<HabitEntryEntity>().getAll().map((e) => e.toDto().toJson()).toList();
    final schedules =
        _store.box<HabitScheduleEntity>().getAll().map((e) => e.toDto().toJson()).toList();
    final limits = _store.box<HabitLimitEntity>().getAll().map((e) => e.toDto().toJson()).toList();
    final dayNotes = _store.box<DayNoteEntity>().getAll().map((e) => e.toDto().toJson()).toList();

    final exportData = {
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'habits': habits,
      'entries': entries,
      'schedules': schedules,
      'limits': limits,
      'dayNotes': dayNotes,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

    final targetDir = customDirectory != null
        ? Directory(customDirectory)
        : await _getTargetDirectory();
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(p.join(targetDir.path, 'overman_export_$timestamp.json'));
    file.writeAsStringSync(jsonString);

    await _share(file, 'application/json');
    return file;
  }

  /// Exports habits and entries into an XLSX spreadsheet with two sheets (`Habits` and `Entries`).
  Future<File> exportXlsx({String? customDirectory}) async {
    final habits = _store.box<HabitEntity>().getAll().map((e) => e.toDto()).toList();
    final entries = _store.box<HabitEntryEntity>().getAll().map((e) => e.toDto()).toList();

    final excel = Excel.createExcel();

    // 1. Sheet "Habits"
    final habitsSheet = excel['Habits'];
    habitsSheet.appendRow([
      TextCellValue('id'),
      TextCellValue('name'),
      TextCellValue('type'),
      TextCellValue('unit'),
      TextCellValue('targetValue'),
      TextCellValue('colorHex'),
      TextCellValue('iconName'),
      TextCellValue('description'),
      TextCellValue('isOneTime'),
      TextCellValue('completedAt'),
      TextCellValue('createdAt'),
      TextCellValue('isArchived'),
    ]);

    for (final h in habits) {
      habitsSheet.appendRow([
        TextCellValue(h.id),
        TextCellValue(h.name),
        TextCellValue(h.type.name),
        h.unit != null ? TextCellValue(h.unit!) : null,
        h.targetValue != null ? DoubleCellValue(h.targetValue!) : null,
        TextCellValue(h.colorHex),
        TextCellValue(h.iconName),
        h.description != null ? TextCellValue(h.description!) : null,
        BoolCellValue(h.isOneTime),
        h.completedAt != null ? TextCellValue(h.completedAt!.toIso8601String()) : null,
        TextCellValue(h.createdAt.toIso8601String()),
        BoolCellValue(h.isArchived),
      ]);
    }

    // 2. Sheet "Entries"
    final entriesSheet = excel['Entries'];
    entriesSheet.appendRow([
      TextCellValue('id'),
      TextCellValue('habitId'),
      TextCellValue('date'),
      TextCellValue('value'),
      TextCellValue('note'),
      TextCellValue('createdAt'),
    ]);

    for (final e in entries) {
      entriesSheet.appendRow([
        TextCellValue(e.id),
        TextCellValue(e.habitId),
        TextCellValue(e.date.toIso8601String()),
        DoubleCellValue(e.value),
        e.note != null ? TextCellValue(e.note!) : null,
        TextCellValue(e.createdAt.toIso8601String()),
      ]);
    }

    // Remove default Sheet1 if created
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.save();
    if (bytes == null) {
      throw StateError('Failed to generate Excel file.');
    }

    final targetDir = customDirectory != null
        ? Directory(customDirectory)
        : await _getTargetDirectory();
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(p.join(targetDir.path, 'overman_export_$timestamp.xlsx'));
    file.writeAsBytesSync(bytes);

    await _share(
      file,
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    return file;
  }

  /// Escapes CSV values conforming to RFC 4180 standard.
  String _escapeCsv(dynamic value) {
    if (value == null) return '';
    final str = value.toString();
    if (str.contains(',') || str.contains('"') || str.contains('\n') || str.contains('\r')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }
}
