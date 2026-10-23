import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../application/services/streak_calculator.dart';
import '../../data/models/dtos/dtos.dart';
import '../theme/app_theme.dart';

/// Widget rendering comprehensive streak analytics:
/// Current Streak, All-Time Best, and Top 5 Streaks in a specific year.
class StreakAnalyticsWidget extends StatelessWidget {
  final HabitDto habit;
  final List<HabitEntryDto> entries;
  final HabitScheduleDto? schedule;
  final int selectedYear;

  const StreakAnalyticsWidget({
    super.key,
    required this.habit,
    required this.entries,
    this.schedule,
    required this.selectedYear,
  });

  @override
  Widget build(BuildContext context) {
    final curStreak = StreakCalculator.currentStreak(
      entries,
      habitType: habit.type,
      target: habit.targetValue,
      schedule: schedule,
    );

    final bestStreak = StreakCalculator.allTimeGreatestStreak(
      entries,
      habitType: habit.type,
      target: habit.targetValue,
      schedule: schedule,
    );

    final topStreaks = StreakCalculator.topStreaksInYear(
      entries,
      year: selectedYear,
      topN: 5,
      habitType: habit.type,
      target: habit.targetValue,
      schedule: schedule,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Current streak card
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                '$curStreak ${curStreak == 1 ? "day" : "days"}',
                key: const Key('streak_current_number'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.orange,
                  fontFamily: AppTheme.fontPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Current Streak',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedGrey,
                  fontFamily: AppTheme.fontPrimary,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14.0),
                child: Divider(
                  color: Color(0x1FFFFFFF),
                  thickness: 0.8,
                ),
              ),
              Text(
                '$bestStreak ${bestStreak == 1 ? "day" : "days"}',
                key: const Key('streak_all_time_best_number'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                  fontFamily: AppTheme.fontPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'All-Time Best',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedGrey,
                  fontFamily: AppTheme.fontPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Top 5 Streaks Section
        Text(
          'Top 5 Streaks ($selectedYear)',
          key: const Key('streak_top_header'),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
            fontFamily: AppTheme.fontPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: topStreaks.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Center(
                    child: Text(
                      'No streaks yet — start your first one today!',
                      key: Key('no_streaks_placeholder'),
                      style: TextStyle(
                        color: AppColors.mutedGrey,
                        fontSize: 13,
                        fontFamily: AppTheme.fontPrimary,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topStreaks.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: Color(0x14FFFFFF),
                    height: 16,
                  ),
                  itemBuilder: (context, index) {
                    final item = topStreaks[index];
                    final startStr = DateFormat('MMM d').format(item.start);
                    final endStr = DateFormat('MMM d').format(item.end);
                    final isFirst = index == 0;

                    return Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isFirst
                                ? AppColors.orange.withValues(alpha: 0.15)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isFirst
                                  ? AppColors.orange
                                  : AppColors.mutedGrey.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isFirst
                                  ? AppColors.orange
                                  : AppColors.mutedGrey,
                              fontFamily: AppTheme.fontPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${item.length} ${item.length == 1 ? "day" : "days"}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                            fontFamily: AppTheme.fontPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$startStr → $endStr',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedGrey,
                            fontFamily: AppTheme.fontPrimary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}
