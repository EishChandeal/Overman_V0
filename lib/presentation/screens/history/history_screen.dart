import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../application/providers/providers.dart';
import '../../../data/models/dtos/dtos.dart';
import '../../../domain/enums/enums.dart';
import '../../navigation/app_router.dart';
import '../../screens/insights/insights_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/day_note_bottom_sheet.dart';

/// Screen displaying historical dates in reverse chronological order,
/// allowing inspection and editing of habit entries on earlier dates.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late DateTime _selectedDate;
  late final List<DateTime> _pastDays;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime.utc(now.year, now.month, now.day);

    // Build the last 30 days in reverse chronological order (Today, Yesterday, ...)
    _pastDays = List.generate(30, (index) {
      final d = now.subtract(Duration(days: index));
      return DateTime.utc(d.year, d.month, d.day);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitListProvider);
    final entriesAsync = ref.watch(entriesForDateProvider(_selectedDate));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: const Text(
          'History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
            fontFamily: AppTheme.fontPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_outlined, color: AppColors.blue),
            tooltip: 'View Insights',
            onPressed: () {
              appNavigateTo(context, AppRoutes.insights, const InsightsScreen());
            },
          ),
          IconButton(
            icon: const Icon(Icons.today_outlined, color: AppColors.primaryText),
            tooltip: 'Jump to today',
            onPressed: () {
              final now = DateTime.now();
              _selectDate(DateTime.utc(now.year, now.month, now.day));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Horizontal Date Strip (Last 30 days in reverse chronological order)
            _buildDateSelectorStrip(),

            const Divider(color: AppColors.surface, height: 1),

            // Main Content: Habit list for the selected date
            Expanded(
              child: habitsAsync.when(
                data: (habits) => entriesAsync.when(
                  data: (entries) => _buildHabitHistoryList(context, habits, entries),
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.blue,
                      strokeWidth: 2.5,
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Text(
                      'Error loading entries: $err',
                      style: const TextStyle(color: AppColors.mutedGrey),
                    ),
                  ),
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.blue,
                    strokeWidth: 2.5,
                  ),
                ),
                error: (err, _) => Center(
                  child: Text(
                    'Error loading habits: $err',
                    style: const TextStyle(color: AppColors.mutedGrey),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelectorStrip() {
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _pastDays.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = _pastDays[index];
          final isSelected = date == _selectedDate;
          final now = DateTime.now();
          final isToday = date == DateTime.utc(now.year, now.month, now.day);
          final weekdayStr = DateFormat('E').format(date); // Mon, Tue...
          final dayStr = DateFormat('d').format(date); // 14, 13...

          return Material(
            color: isSelected
                ? AppColors.blue
                : (isToday ? AppColors.surface : AppColors.surface.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => _selectDate(date),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: isToday && !isSelected
                      ? Border.all(color: AppColors.orange, width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      weekdayStr.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.controlText : AppColors.mutedGrey,
                        fontFamily: AppTheme.fontPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dayStr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.controlText : AppColors.primaryText,
                        fontFamily: AppTheme.fontPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHabitHistoryList(
    BuildContext context,
    List<HabitDto> allHabits,
    List<HabitEntryDto> entries,
  ) {
    final activeHabits = allHabits.where((h) => !h.isArchived).toList();

    if (activeHabits.isEmpty) {
      return const Center(
        child: Text(
          'No habits found. Create a habit on Home.',
          style: TextStyle(color: AppColors.mutedGrey),
        ),
      );
    }

    final entryMap = {for (final e in entries) e.habitId: e};
    final now = DateTime.now();
    final isToday = _selectedDate == DateTime.utc(now.year, now.month, now.day);
    final selectedCalendarDate =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    // Filter habits/tasks visible on this selected date:
    // 1. Habit/task must NOT be visible before its creation date.
    // 2. One-time tasks: if completed, disappear after completion day.
    final visibleHabits = activeHabits.where((habit) {
      final createdLocal = habit.createdAt.toLocal();
      final createdCalendarDate =
          DateTime(createdLocal.year, createdLocal.month, createdLocal.day);
      if (selectedCalendarDate.isBefore(createdCalendarDate)) {
        return false;
      }

      if (habit.isOneTime && habit.completedAt != null) {
        final completedLocal = habit.completedAt!.toLocal();
        final completedCalendarDate = DateTime(
          completedLocal.year,
          completedLocal.month,
          completedLocal.day,
        );
        if (selectedCalendarDate.isAfter(completedCalendarDate)) {
          return false;
        }
      }

      return true;
    }).toList();

    int completedCount = 0;
    for (final h in visibleHabits) {
      final entry = entryMap[h.id];
      if (_isCompletedOnDate(h, entry, _selectedDate)) {
        completedCount++;
      }
    }

    final dateFormatted = isToday
        ? 'Today (${DateFormat('d MMMM yyyy').format(_selectedDate)})'
        : DateFormat('EEEE, d MMMM yyyy').format(_selectedDate);

    if (visibleHabits.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildDateSummaryBanner(dateFormatted, 0, 0),
          const SizedBox(height: 60),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_busy_outlined,
                  size: 48,
                  color: AppColors.mutedGrey.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No habits found for this date.',
                  style: TextStyle(
                    color: AppColors.mutedGrey,
                    fontSize: 14,
                    fontFamily: AppTheme.fontPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _buildDateSummaryBanner(
          dateFormatted,
          completedCount,
          visibleHabits.length,
        ),
        const SizedBox(height: 12),
        ...visibleHabits.map((habit) {
          final entry = entryMap[habit.id];
          final isCompleted = _isCompletedOnDate(habit, entry, _selectedDate);

          return _HistoryHabitRow(
            key: ValueKey('history_${habit.id}_${_selectedDate.toIso8601String()}'),
            habit: habit,
            entry: entry,
            selectedDate: _selectedDate,
            isCompleted: isCompleted,
            onTap: () => _openDayNoteSheet(context, habit),
            onToggle: () => _handleEntryTap(context, habit, entry, isCompleted),
          );
        }),
      ],
    );
  }

  Widget _buildDateSummaryBanner(
    String dateFormatted,
    int completedCount,
    int totalCount,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFormatted,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                    fontFamily: AppTheme.fontPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$completedCount of $totalCount habits recorded',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedGrey,
                    fontFamily: AppTheme.fontPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: completedCount > 0
                  ? AppColors.blue.withValues(alpha: 0.2)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$completedCount / $totalCount',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: completedCount > 0 ? AppColors.blue : AppColors.mutedGrey,
                fontFamily: AppTheme.fontPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isCompletedOnDate(
    HabitDto habit,
    HabitEntryDto? entry,
    DateTime selectedDate,
  ) {
    if (habit.isOneTime) {
      if (entry != null && entry.value > 0) return true;
      if (habit.completedAt != null) {
        final compLocal = habit.completedAt!.toLocal();
        return DateTime(compLocal.year, compLocal.month, compLocal.day) ==
            DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      }
      return false;
    }
    if (habit.type == HabitType.numeric && habit.targetValue != null) {
      return entry != null && entry.value >= habit.targetValue!;
    }
    return entry != null && entry.value > 0;
  }

  void _openDayNoteSheet(BuildContext context, HabitDto habit) {
    final habitColor = HabitVisuals.parseColor(habit.colorHex);
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DayNoteBottomSheet(
        habitId: habit.id,
        habitColor: habitColor,
        date: _selectedDate,
      ),
    );
  }

  Future<void> _handleEntryTap(
    BuildContext context,
    HabitDto habit,
    HabitEntryDto? entry,
    bool isCompletedOnDate,
  ) async {
    if (habit.isOneTime) {
      final repo = await ref.read(habitRepositoryProvider.future);
      final actions = ref.read(entryActionsProvider.notifier);

      if (isCompletedOnDate) {
        final updated = habit.copyWith(completedAt: null);
        await repo.updateHabit(updated);
        if (entry != null) {
          await actions.deleteEntry(
            entryId: entry.id,
            habitId: habit.id,
          );
        }
      } else {
        final updated = habit.copyWith(completedAt: _selectedDate);
        await repo.updateHabit(updated);
        await actions.logEntry(
          habitId: habit.id,
          date: _selectedDate,
          value: habit.targetValue ?? 1.0,
        );
      }
      ref.invalidate(todayDashboardProvider);
      ref.invalidate(habitListProvider);
      ref.invalidate(entriesForDateProvider(_selectedDate));
      return;
    }

    if (habit.type == HabitType.boolean) {
      if (entry != null && entry.value > 0) {
        ref.read(entryActionsProvider.notifier).deleteEntry(
          entryId: entry.id,
          habitId: habit.id,
        );
      } else {
        ref.read(entryActionsProvider.notifier).logEntry(
          habitId: habit.id,
          date: _selectedDate,
          value: 1.0,
        );
      }
      ref.invalidate(todayDashboardProvider);
      ref.invalidate(entriesForDateProvider(_selectedDate));
    } else {
      _showNumericInputDialog(context, habit, entry);
    }
  }

  void _showNumericInputDialog(
    BuildContext context,
    HabitDto habit,
    HabitEntryDto? entry,
  ) {
    final controller = TextEditingController(
      text: entry != null && entry.value > 0 ? _formatVal(entry.value) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Log ${habit.name} (${DateFormat('d MMM').format(_selectedDate)})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                  fontFamily: AppTheme.fontPrimary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: const TextStyle(color: AppColors.primaryText),
                decoration: InputDecoration(
                  labelText: 'Value (${habit.unit ?? 'units'})',
                  labelStyle: const TextStyle(color: AppColors.mutedGrey),
                  hintText: 'e.g. 500',
                  hintStyle: TextStyle(color: AppColors.mutedGrey.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (entry != null)
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          ref.read(entryActionsProvider.notifier).deleteEntry(
                            entryId: entry.id,
                            habitId: habit.id,
                          );
                          ref.invalidate(todayDashboardProvider);
                          ref.invalidate(entriesForDateProvider(_selectedDate));
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Clear'),
                      ),
                    ),
                  if (entry != null) const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        foregroundColor: AppColors.controlText,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final val = double.tryParse(controller.text.trim()) ?? 0.0;
                        if (val > 0) {
                          ref.read(entryActionsProvider.notifier).logEntry(
                            habitId: habit.id,
                            date: _selectedDate,
                            value: val,
                          );
                          ref.invalidate(todayDashboardProvider);
                          ref.invalidate(entriesForDateProvider(_selectedDate));
                        }
                        Navigator.of(ctx).pop();
                      },
                      child: const Text(
                        'Save Entry',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatVal(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
  }
}

/// Individual habit row inside History screen.
/// Tapping the card opens DayNoteBottomSheet for [selectedDate].
/// Tapping the right-side button toggles or logs habit entry.
class _HistoryHabitRow extends ConsumerWidget {
  final HabitDto habit;
  final HabitEntryDto? entry;
  final DateTime selectedDate;
  final bool isCompleted;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _HistoryHabitRow({
    super.key,
    required this.habit,
    required this.entry,
    required this.selectedDate,
    required this.isCompleted,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitColor = HabitVisuals.parseColor(habit.colorHex);
    final onHabitColor = HabitVisuals.getOnColor(habitColor);
    final isNumeric = habit.type == HabitType.numeric;

    // Check if a day note exists for this habit on [selectedDate]
    final notesAsync = ref.watch(habitDayNotesProvider(habit.id));
    final selectedUtc = DateTime.utc(selectedDate.year, selectedDate.month, selectedDate.day);
    final noteForDay = notesAsync.whenOrNull(
      data: (notes) => notes.cast<DayNoteDto?>().firstWhere(
        (n) =>
            n != null &&
            n.date.year == selectedUtc.year &&
            n.date.month == selectedUtc.month &&
            n.date.day == selectedUtc.day,
        orElse: () => null,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Color.alphaBlend(habitColor.withValues(alpha: 0.04), AppColors.surface),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Color accent strip
                Container(
                  width: 4,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isCompleted ? habitColor : habitColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),

                // Habit icon badge
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: habitColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    HabitVisuals.getIcon(habit.iconName),
                    color: habitColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Habit details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              habit.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText,
                                fontFamily: AppTheme.fontPrimary,
                                decoration: (habit.isOneTime && isCompleted)
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: AppColors.mutedGrey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (habit.isOneTime) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.blue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'One-time',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.blue,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isNumeric
                            ? 'Logged: ${_HistoryScreenState._formatVal(entry?.value ?? 0)} / ${_HistoryScreenState._formatVal(habit.targetValue ?? 0)} ${habit.unit ?? ''}'
                            : (isCompleted ? 'Completed' : 'Not logged'),
                        style: TextStyle(
                          fontSize: 12,
                          color: isCompleted ? habitColor : AppColors.mutedGrey,
                          fontFamily: AppTheme.fontPrimary,
                        ),
                      ),
                      if (noteForDay != null && noteForDay.note.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.background.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.note_alt_outlined,
                                size: 12,
                                color: habitColor,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  noteForDay.note,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.mutedGrey,
                                    fontStyle: FontStyle.italic,
                                    fontFamily: AppTheme.fontPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Interactive Completion Control for this past date
                Material(
                  color: isCompleted ? habitColor : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onToggle,
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: isNumeric
                          ? Text(
                              _HistoryScreenState._formatVal(entry?.value ?? 0),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isCompleted
                                    ? onHabitColor
                                    : AppColors.mutedGrey,
                              ),
                            )
                          : Icon(
                              isCompleted ? Icons.check : Icons.remove,
                              color: isCompleted
                                  ? onHabitColor
                                  : AppColors.mutedGrey,
                              size: 22,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
