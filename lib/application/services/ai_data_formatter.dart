import 'package:intl/intl.dart';
import '../../data/models/dtos/dtos.dart';
import '../../domain/enums/enums.dart';

class AiDataFormatter {
  /// Formats [habits] and their [entriesByHabitId] (only entries within
  /// [windowDays] calendar days back from [today]) into a plain-text block
  /// suitable for sending to an LLM as part of a system prompt.
  ///
  /// [dayNotesByHabitId] is optional — include if not null/empty.
  static String format({
    required List<HabitDto> habits,
    required Map<String, List<HabitEntryDto>> entriesByHabitId,
    Map<String, List<DayNoteDto>>? dayNotesByHabitId,
    Map<String, HabitScheduleDto>? schedulesByHabitId,
    Map<String, int>? streaksByHabitId,
    required int windowDays,
    DateTime? today,
  }) {
    if (habits.isEmpty) {
      return 'No habit data available.';
    }

    final effectiveToday = today ?? DateTime.now();
    final todayNormalized = DateTime(effectiveToday.year, effectiveToday.month, effectiveToday.day);
    final effectiveWindow = windowDays <= 0 ? 1 : windowDays;

    final generatedStr = DateFormat('E, d MMM yyyy').format(effectiveToday);
    final buffer = StringBuffer();
    buffer.writeln('=== User Habit Data (last $effectiveWindow days) ===');
    buffer.writeln('Generated: $generatedStr');

    // List of calendar days in window, oldest first:
    // [today - (effectiveWindow - 1) days, ..., today]
    final days = <DateTime>[];
    for (int i = effectiveWindow - 1; i >= 0; i--) {
      days.add(todayNormalized.subtract(Duration(days: i)));
    }

    for (final habit in habits) {
      buffer.writeln();
      if (habit.isOneTime) {
        buffer.writeln('--- One-time Task: "${habit.name}" ---');
        if (habit.completedAt != null) {
          final completedStr = DateFormat('E d MMM yyyy').format(habit.completedAt!.toLocal());
          buffer.writeln('Status: ✅ Completed on $completedStr');
        } else {
          buffer.writeln('Status: ⏳ Pending');
        }
        if (habit.description != null && habit.description!.trim().isNotEmpty) {
          buffer.writeln('Description: ${habit.description!.trim()}');
        }

        // Show notes for task if any in window
        final allNotes = dayNotesByHabitId?[habit.id] ?? const [];
        final windowStart = days.first;
        final notesInWindow = allNotes.where((n) {
          final nDate = DateTime(n.date.year, n.date.month, n.date.day);
          return !nDate.isBefore(windowStart) && !nDate.isAfter(todayNormalized);
        }).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        if (notesInWindow.isNotEmpty) {
          buffer.writeln('  Notes:');
          for (final note in notesInWindow) {
            final noteDateStr = DateFormat('E d MMM').format(note.date);
            buffer.writeln('    [$noteDateStr] "${note.note.trim()}"');
          }
        }
      } else {
        buffer.writeln('--- Habit: "${habit.name}" ---');

        final metaParts = <String>[];
        metaParts.add('Type: Habit (${habit.type.name})');
        if (habit.type == HabitType.numeric) {
          if (habit.unit != null && habit.unit!.trim().isNotEmpty) {
            metaParts.add('Unit: ${habit.unit!.trim()}');
          }
          if (habit.targetValue != null) {
            metaParts.add('Target: ${_formatNumber(habit.targetValue!)}');
          }
        }

        final schedule = schedulesByHabitId?[habit.id];
        final scheduleStr = schedule?.scheduleType.displayName ?? 'Daily';
        metaParts.add('Schedule: $scheduleStr');

        final habitEntries = entriesByHabitId[habit.id] ?? const [];
        final streak = streaksByHabitId?[habit.id] ??
            _calculateStreak(habitEntries, habit.type, habit.targetValue, todayNormalized);
        metaParts.add('Streak: $streak days');

        final startedStr = DateFormat('d MMM yyyy').format(habit.createdAt.toLocal());
        metaParts.add('Started: $startedStr');

        buffer.writeln(metaParts.join(' | '));

        if (habit.description != null && habit.description!.trim().isNotEmpty) {
          buffer.writeln('Description: ${habit.description!.trim()}');
        }

        final entriesByDateKey = <String, HabitEntryDto>{};
        for (final entry in habitEntries) {
          final key = _dateKey(entry.date);
          entriesByDateKey[key] = entry;
        }

        final dayStrings = <String>[];
        for (final d in days) {
          final dateHeader = DateFormat('E d MMM').format(d);
          final key = _dateKey(d);
          final entry = entriesByDateKey[key];

          String statusStr;
          if (entry == null) {
            statusStr = '—';
          } else if (habit.type == HabitType.boolean) {
            statusStr = entry.value > 0 ? '✅' : '❌';
          } else {
            final valStr = _formatNumber(entry.value);
            final target = habit.targetValue ?? 0;
            statusStr = entry.value >= target ? '$valStr ✅' : valStr;
          }

          dayStrings.add('$dateHeader $statusStr');
        }

        // Format dayStrings into lines of up to 5 items:
        for (int i = 0; i < dayStrings.length; i += 5) {
          final chunk = dayStrings.sublist(i, (i + 5).clamp(0, dayStrings.length));
          buffer.writeln('  ${chunk.join('   ')}');
        }

        // Day Notes under habit:
        final allNotes = dayNotesByHabitId?[habit.id] ?? const [];
        final windowStart = days.first;
        final notesInWindow = allNotes.where((n) {
          final nDate = DateTime(n.date.year, n.date.month, n.date.day);
          return !nDate.isBefore(windowStart) && !nDate.isAfter(todayNormalized);
        }).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        if (notesInWindow.isNotEmpty) {
          buffer.writeln('  Notes:');
          for (final note in notesInWindow) {
            final noteDateStr = DateFormat('E d MMM').format(note.date);
            buffer.writeln('    [$noteDateStr] "${note.note.trim()}"');
          }
        }
      }
    }

    buffer.writeln();
    buffer.writeln('===');
    return buffer.toString();
  }

  static int _calculateStreak(
    List<HabitEntryDto> entries,
    HabitType type,
    double? target,
    DateTime todayNormalized,
  ) {
    final metDays = <String>{};
    for (final e in entries) {
      final isMet = type == HabitType.boolean ? e.value > 0 : e.value >= (target ?? 0);
      if (isMet) {
        metDays.add(_dateKey(e.date));
      }
    }

    int streak = 0;
    DateTime check = todayNormalized;
    if (!metDays.contains(_dateKey(check))) {
      check = check.subtract(const Duration(days: 1));
    }
    while (metDays.contains(_dateKey(check))) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static String _dateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  static String _formatNumber(double n) {
    if (n == n.roundToDouble()) {
      return n.toInt().toString();
    }
    return n.toStringAsFixed(1);
  }
}
