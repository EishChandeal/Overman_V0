import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/application/providers/providers.dart';
import 'package:habit_tracker/application/services/habit_stats_calculator.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/domain/enums/enums.dart';
import 'package:habit_tracker/domain/services/statistics_service.dart';
import 'package:habit_tracker/presentation/theme/app_theme.dart';

/// Panel displaying computed statistics for a habit.
class StatisticsPanel extends ConsumerWidget {
  final HabitDto habit;

  const StatisticsPanel({super.key, required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final oneYearAgo = todayUtc.subtract(const Duration(days: 365));
    final range = DateRange(start: oneYearAgo, end: todayUtc);

    final statsAsync = ref.watch(habitStatisticsProvider(habit.id, range));
    final entriesAsync = ref.watch(habitEntriesProvider(habit.id));
    final scheduleAsync = ref.watch(activeScheduleProvider(habit.id));

    return statsAsync.when(
      data: (stats) {
        final entries = entriesAsync.value ?? [];
        final activeSchedule = scheduleAsync.value;
        final scheduledWeekdays = activeSchedule?.scheduledWeekdays
                ?.map((w) => w.name)
                .toList() ??
            [];

        final activeDays = HabitStatsCalculator.computeActiveDays(
          habit,
          scheduledWeekdays,
          now,
        );
        final completedDays = HabitStatsCalculator.computeCompletedDays(
          entries,
          habit,
        );
        final missedDays = (activeDays - completedDays).clamp(0, activeDays);
        final completionRate = HabitStatsCalculator.computeCompletionRate(
          habit,
          entries,
          scheduledWeekdays,
          now,
        );

        return _buildContent(
          context,
          stats: stats,
          completionRate: completionRate,
          completedDays: completedDays,
          missedDays: missedDays,
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.blue,
          ),
        ),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Failed to load statistics: $err',
            style: const TextStyle(color: AppColors.mutedGrey, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required StatisticsResult stats,
    required double completionRate,
    required int completedDays,
    required int missedDays,
  }) {
    final habitColor = HabitVisuals.parseColor(habit.colorHex);
    final ratePercent = completionRate.toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top row: Completion rate & Total days tracked
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                title: 'Completion Rate',
                value: '$ratePercent%',
                icon: Icons.pie_chart_outline,
                accentColor: habitColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatTile(
                title: 'Completed Days',
                value: '$completedDays',
                icon: Icons.check_circle_outline,
                accentColor: habitColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Second row: Missed days & Total recorded / average
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                title: 'Missed Days',
                value: '$missedDays',
                icon: Icons.cancel_outlined,
                accentColor: AppColors.mutedGrey,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: habit.type == HabitType.numeric
                  ? _buildStatTile(
                      title: 'Daily Average',
                      value: _formatVal(stats.average),
                      subtitle: habit.unit,
                      icon: Icons.analytics_outlined,
                      accentColor: habitColor,
                    )
                  : _buildStatTile(
                      title: 'Consistency',
                      value: completedDays > 0 ? 'Active' : 'New',
                      icon: Icons.trending_up,
                      accentColor: habitColor,
                    ),
            ),
          ],
        ),

        // Third row for Numeric habits: Best day & Total sum
        if (habit.type == HabitType.numeric) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  title: 'Best Record',
                  value: _formatVal(stats.bestValue),
                  subtitle: habit.unit,
                  icon: Icons.star_border,
                  accentColor: habitColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatTile(
                  title: 'Total Logged',
                  value: _formatVal(stats.sum),
                  subtitle: habit.unit,
                  icon: Icons.functions,
                  accentColor: habitColor,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedGrey,
                    fontFamily: AppTheme.fontPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                  fontFamily: AppTheme.fontPrimary,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedGrey,
                    fontFamily: AppTheme.fontPrimary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatVal(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
  }
}
