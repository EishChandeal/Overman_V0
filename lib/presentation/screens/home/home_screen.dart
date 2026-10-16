import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:habit_tracker/application/providers/providers.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/domain/enums/enums.dart';
import 'package:habit_tracker/presentation/theme/app_theme.dart';
import 'package:habit_tracker/presentation/widgets/habit_card.dart';
import 'package:habit_tracker/presentation/screens/add/add_habit_screen.dart';
import 'package:habit_tracker/presentation/screens/history/history_screen.dart';
import 'package:habit_tracker/presentation/screens/settings/settings_screen.dart';
import 'package:habit_tracker/presentation/navigation/app_router.dart';

/// Main Home screen displaying the date/progress header and today's habits.
/// Corresponds to Section 48-84 of PROJECT_BRIEF.md and DESIGN.md.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  HabitDayStatus? _selectedHabitStatus;

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(todayDashboardProvider);

    final selectedStatus = _selectedHabitStatus == null
        ? null
        : (dashboardAsync.valueOrNull ?? [])
            .where((h) => h.habit.id == _selectedHabitStatus!.habit.id)
            .firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (_selectedHabitStatus != null) {
              setState(() => _selectedHabitStatus = null);
            }
          },
          child: Column(
            children: [
              // Top action & date header OR selection header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: selectedStatus != null
                    ? _buildSelectionHeaderRow(selectedStatus)
                    : _buildHeaderRow(context, dashboardAsync.valueOrNull ?? []),
              ),

              // Habit list / Content area
              Expanded(
                child: dashboardAsync.when(
                  data: (habits) {
                    if (habits.isEmpty) {
                      return _buildEmptyState(context);
                    }
                    return _buildHabitList(habits, selectedStatus);
                  },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.blue,
                  ),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.orange,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Failed to load habits',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          err.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedGrey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ref.invalidate(todayDashboardProvider),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  /// Header row containing:
  /// 1. History / Date button (approx 171 x 88)
  /// 2. Add button (approx 92 x 88)
  /// 3. Settings button (approx 92 x 88)
  Widget _buildHeaderRow(BuildContext context, List<HabitDayStatus> habits) {
    final today = DateTime.now();
    final formattedDate = DateFormat('d MMM').format(today);

    // Calculate completion count for habits scheduled today
    final scheduledHabits = habits.where((h) => h.isScheduledToday).toList();
    final completedCount = scheduledHabits
        .where((h) => h.status == DayStatus.met || h.status == DayStatus.exceeded)
        .length;
    final totalScheduled = scheduledHabits.length;

    const double headerHeight = 88;

    return Row(
      children: [
        // 1. History / Date button
        Expanded(
          flex: 2,
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                appNavigateTo(context, AppRoutes.history, const HistoryScreen());
              },
              child: Container(
                height: headerHeight,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                        fontFamily: AppTheme.fontPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$completedCount / $totalScheduled completed',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedGrey,
                        fontFamily: AppTheme.fontPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // 2. Add button
        Expanded(
          flex: 1,
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                appNavigateTo(context, AppRoutes.add, const AddHabitScreen());
              },
              child: const SizedBox(
                height: headerHeight,
                child: Center(
                  child: Icon(
                    Icons.add,
                    size: 28,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // 3. Settings button
        Expanded(
          flex: 1,
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                appNavigateTo(context, AppRoutes.settings, const SettingsScreen());
              },
              child: const SizedBox(
                height: headerHeight,
                child: Center(
                  child: Icon(
                    Icons.settings_outlined,
                    size: 28,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Selection header row exposing:
  /// 1. Close/Selected habit name (approx 171 x 88)
  /// 2. Edit button (approx 92 x 88)
  /// 3. Delete button (approx 92 x 88)
  Widget _buildSelectionHeaderRow(
    HabitDayStatus selectedItem,
  ) {
    const double headerHeight = 88;
    final habit = selectedItem.habit;

    return Row(
      children: [
        // 1. Cancel / Selected info button (flex 2)
        Expanded(
          flex: 2,
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                setState(() => _selectedHabitStatus = null);
              },
              child: Container(
                height: headerHeight,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.close,
                      color: AppColors.mutedGrey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '1 selected',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedGrey,
                              fontFamily: AppTheme.fontPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            habit.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                              fontFamily: AppTheme.fontPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // 2. Edit button (flex 1)
        Expanded(
          flex: 1,
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _editHabit(selectedItem),
              child: const SizedBox(
                height: headerHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 26,
                      color: AppColors.primaryText,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                        fontFamily: AppTheme.fontPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // 3. Delete button (flex 1)
        Expanded(
          flex: 1,
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _confirmDelete(habit),
              child: const SizedBox(
                height: headerHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 26,
                      color: Colors.redAccent,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent,
                        fontFamily: AppTheme.fontPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHabitList(
    List<HabitDayStatus> habits,
    HabitDayStatus? selectedStatus,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: habits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = habits[index];
        final isSelected = selectedStatus?.habit.id == item.habit.id;

        return HabitCard(
          item: item,
          isSelected: isSelected,
          onTap: () {
            if (_selectedHabitStatus != null) {
              setState(() => _selectedHabitStatus = null);
            }
          },
          onCompletionTap: () => _handleCompletionTap(context, ref, item),
          onLongPress: () {
            setState(() {
              _selectedHabitStatus = item;
            });
          },
          onEdit: () => _editHabit(item),
          onDelete: () => _confirmDelete(item.habit),
        );
      },
    );
  }

  Future<void> _editHabit(HabitDayStatus item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddHabitScreen(
          habitToEdit: item.habit,
          scheduleToEdit: item.activeSchedule,
        ),
      ),
    );
    if (mounted) {
      setState(() => _selectedHabitStatus = null);
    }
  }

  Future<void> _confirmDelete(
    HabitDto habit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Habit',
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.fontPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${habit.name}"? This will permanently delete all its logged entries and history.',
            style: const TextStyle(
              color: AppColors.mutedGrey,
              fontFamily: AppTheme.fontPrimary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.mutedGrey),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        final repo = await ref.read(habitRepositoryProvider.future);
        await repo.deleteHabit(habit.id);

        ref.invalidate(todayDashboardProvider);
        ref.invalidate(habitListProvider);
        ref.invalidate(habitStreakProvider(habit.id));

        if (mounted) {
          setState(() {
            if (_selectedHabitStatus?.habit.id == habit.id) {
              _selectedHabitStatus = null;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted habit "${habit.name}"'),
              backgroundColor: AppColors.surface,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete habit: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  void _handleCompletionTap(
    BuildContext context,
    WidgetRef ref,
    HabitDayStatus item,
  ) {
    final now = DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final actions = ref.read(entryActionsProvider.notifier);

    if (item.habit.type == HabitType.boolean) {
      final isCompleted =
          item.status == DayStatus.met || item.status == DayStatus.exceeded;
      if (isCompleted && item.entry != null) {
        // Toggle off
        actions.deleteEntry(
          entryId: item.entry!.id,
          habitId: item.habit.id,
        );
      } else {
        // Mark complete
        actions.logEntry(
          habitId: item.habit.id,
          date: todayUtc,
          value: 1.0,
        );
      }
    } else {
      // Numeric entry dialog / bottom sheet
      _showNumericEntrySheet(context, ref, item, todayUtc);
    }
  }

  void _showNumericEntrySheet(
    BuildContext context,
    WidgetRef ref,
    HabitDayStatus item,
    DateTime date,
  ) {
    final controller = TextEditingController(
      text: item.entry != null
          ? (item.entry!.value == item.entry!.value.roundToDouble()
              ? item.entry!.value.toInt().toString()
              : item.entry!.value.toString())
          : (item.habit.targetValue != null
              ? (item.habit.targetValue == item.habit.targetValue!.roundToDouble()
                  ? item.habit.targetValue!.toInt().toString()
                  : item.habit.targetValue.toString())
              : ''),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log ${item.habit.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: const TextStyle(color: AppColors.primaryText, fontSize: 18),
                decoration: InputDecoration(
                  labelText: item.habit.unit != null && item.habit.unit!.isNotEmpty
                      ? 'Value (${item.habit.unit})'
                      : 'Value',
                  suffixText: item.habit.unit,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (item.entry != null)
                    TextButton(
                      onPressed: () {
                        ref.read(entryActionsProvider.notifier).deleteEntry(
                              entryId: item.entry!.id,
                              habitId: item.habit.id,
                            );
                        Navigator.pop(sheetContext);
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: AppColors.orange),
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.mutedGrey),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final val = double.tryParse(controller.text.trim());
                      if (val != null) {
                        ref.read(entryActionsProvider.notifier).logEntry(
                              habitId: item.habit.id,
                              date: date,
                              value: val,
                            );
                      }
                      Navigator.pop(sheetContext);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.mutedGrey.withValues(alpha: 0.2),
                ),
              ),
              child: const Icon(
                Icons.track_changes,
                size: 48,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No habits yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
                fontFamily: AppTheme.fontPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the orange + button above to create your first habit or task.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.mutedGrey,
                fontFamily: AppTheme.fontPrimary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
