import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/providers/providers.dart';
import '../../../data/models/dtos/dtos.dart';
import '../../theme/app_theme.dart';
import '../../widgets/year_heatmap_widget.dart';

/// Dedicated screen displaying comprehensive analytics, yearly heatmap,
/// charts, and streaks for a single habit.
class HabitDetailScreen extends ConsumerStatefulWidget {
  final String habitId;
  final HabitDto? initialHabit;

  const HabitDetailScreen({
    super.key,
    required this.habitId,
    this.initialHabit,
  });

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
  }

  Color _parseColor(String hex) {
    try {
      final cleanHex = hex.replaceAll('#', '');
      if (cleanHex.length == 6) {
        return Color(int.parse('0xFF$cleanHex'));
      } else if (cleanHex.length == 8) {
        return Color(int.parse('0x$cleanHex'));
      }
    } catch (_) {}
    return AppColors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final habitListAsync = ref.watch(habitListProvider);
    final habitFromList = habitListAsync.valueOrNull
        ?.where((h) => h.id == widget.habitId)
        .firstOrNull;
    final habitByIdAsync = ref.watch(habitByIdProvider(widget.habitId));

    final habit =
        habitFromList ?? habitByIdAsync.valueOrNull ?? widget.initialHabit;

    if (habit == null) {
      if (habitListAsync.isLoading && habitByIdAsync.isLoading) {
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: CircularProgressIndicator(
              key: Key('habit_detail_loading'),
              color: AppColors.orange,
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: const Text(
            'Habit Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
              fontFamily: AppTheme.fontPrimary,
            ),
          ),
        ),
        body: const Center(
          child: Text(
            'Habit not found',
            key: Key('habit_detail_not_found'),
            style: TextStyle(
              color: AppColors.mutedGrey,
              fontSize: 16,
              fontFamily: AppTheme.fontPrimary,
            ),
          ),
        ),
      );
    }

    final entriesAsync = ref.watch(habitEntriesProvider(habit.id));
    final entries = entriesAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          habit.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
            fontFamily: AppTheme.fontPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!habit.isOneTime) ...[
              // Yearly Heatmap Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedYear == DateTime.now().year
                        ? 'This Year'
                        : 'Year $_selectedYear',
                    key: const Key('heatmap_year_title'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                      fontFamily: AppTheme.fontPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        key: const Key('heatmap_prev_year_btn'),
                        icon: const Icon(Icons.chevron_left,
                            color: AppColors.primaryText),
                        onPressed: () {
                          setState(() {
                            _selectedYear--;
                          });
                        },
                      ),
                      Text(
                        '$_selectedYear',
                        key: const Key('heatmap_year_label'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                          fontFamily: AppTheme.fontPrimary,
                        ),
                      ),
                      IconButton(
                        key: const Key('heatmap_next_year_btn'),
                        icon: Icon(
                          Icons.chevron_right,
                          color: _selectedYear < DateTime.now().year
                              ? AppColors.primaryText
                              : AppColors.mutedGrey.withValues(alpha: 0.3),
                        ),
                        onPressed: _selectedYear < DateTime.now().year
                            ? () {
                                setState(() {
                                  _selectedYear++;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: YearHeatmapWidget(
                  key: ValueKey('year_heatmap_$_selectedYear'),
                  year: _selectedYear,
                  entries: entries,
                  habitColor: _parseColor(habit.colorHex),
                  habitType: habit.type,
                  target: habit.targetValue,
                  unit: habit.unit,
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'Content coming soon',
              key: Key('habit_detail_content'),
              style: TextStyle(
                color: AppColors.mutedGrey,
                fontSize: 14,
                fontFamily: AppTheme.fontPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
