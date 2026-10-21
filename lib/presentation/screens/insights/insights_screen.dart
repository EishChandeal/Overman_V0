import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/providers/providers.dart';
import '../../../data/models/dtos/dtos.dart';
import '../../../domain/enums/enums.dart';
import '../../theme/app_theme.dart';

/// Screen displaying behavioral analytics, completion trends, and aggregated habit insights.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitListProvider);

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
          'Insights & Analytics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
            fontFamily: AppTheme.fontPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: habitsAsync.when(
          data: (habits) {
            final activeHabits = habits.where((h) => !h.isArchived).toList();
            if (activeHabits.isEmpty) {
              return const Center(
                child: Text(
                  'No habits created yet. Start tracking to see insights.',
                  style: TextStyle(color: AppColors.mutedGrey),
                ),
              );
            }
            return _buildInsightsContent(context, ref, activeHabits);
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: AppColors.blue,
              strokeWidth: 2.5,
            ),
          ),
          error: (err, _) => Center(
            child: Text(
              'Error loading insights: $err',
              style: const TextStyle(color: AppColors.mutedGrey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsightsContent(
    BuildContext context,
    WidgetRef ref,
    List<HabitDto> habits,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // 1. High-level Overview Cards Grid
        _buildOverviewCards(context, ref, habits),

        const SizedBox(height: 20),

        // 2. Weekly Consistency Trend Section
        _buildWeeklyTrendSection(context, ref, habits),

        const SizedBox(height: 20),

        // 3. Per-Habit Performance Breakdown Section
        const Text(
          'HABIT PERFORMANCE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppColors.mutedGrey,
            fontFamily: AppTheme.fontPrimary,
          ),
        ),
        const SizedBox(height: 10),

        ...habits.map((habit) => _buildHabitPerformanceCard(context, ref, habit)),
      ],
    );
  }

  Widget _buildOverviewCards(
    BuildContext context,
    WidgetRef ref,
    List<HabitDto> habits,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Active Habits',
                value: '${habits.length}',
                icon: Icons.track_changes,
                accentColor: AppColors.blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                title: 'Data Engine',
                value: 'ObjectBox',
                subtitle: 'Offline-First',
                icon: Icons.storage_outlined,
                accentColor: AppColors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Target Frame',
                value: '412 × 917',
                subtitle: 'Design Spec',
                icon: Icons.phone_android,
                accentColor: AppColors.blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                title: 'Status',
                value: 'Active',
                subtitle: 'Prototype V0',
                icon: Icons.check_circle_outline,
                accentColor: AppColors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
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
              if (subtitle != null) ...[
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.mutedGrey,
                      fontFamily: AppTheme.fontPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrendSection(
    BuildContext context,
    WidgetRef ref,
    List<HabitDto> habits,
  ) {
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();
    final todayWeekdayIndex = now.weekday - 1; // 0=Mon, 6=Sun

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Activity',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                  fontFamily: AppTheme.fontPrimary,
                ),
              ),
              Text(
                'Current Week',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedGrey,
                  fontFamily: AppTheme.fontPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final isToday = index == todayWeekdayIndex;
              final isPastOrToday = index <= todayWeekdayIndex;
              final barHeight = isPastOrToday ? (isToday ? 60.0 : 40.0) : 12.0;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.blue
                          : (isPastOrToday
                              ? AppColors.blue.withValues(alpha: 0.4)
                              : AppColors.background),
                      borderRadius: BorderRadius.circular(6),
                      border: isToday
                          ? Border.all(color: AppColors.orange, width: 1.5)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    weekdays[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? AppColors.orange : AppColors.mutedGrey,
                      fontFamily: AppTheme.fontPrimary,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitPerformanceCard(
    BuildContext context,
    WidgetRef ref,
    HabitDto habit,
  ) {
    final habitColor = HabitVisuals.parseColor(habit.colorHex);
    final streakAsync = ref.watch(habitStreakProvider(habit.id));
    final now = DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final oneYearAgo = todayUtc.subtract(const Duration(days: 365));
    final range = DateRange(start: oneYearAgo, end: todayUtc);
    final statsAsync = ref.watch(habitStatisticsProvider(habit.id, range));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Color.alphaBlend(habitColor.withValues(alpha: 0.04), AppColors.surface),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: habitColor.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Habit header: icon, title & tracking type
            Row(
              children: [
                Icon(
                  HabitVisuals.getIcon(habit.iconName),
                  size: 18,
                  color: habitColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
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
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    habit.type == HabitType.numeric
                        ? 'Numeric (${habit.unit ?? 'units'})'
                        : 'Checkmark',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.mutedGrey,
                      fontFamily: AppTheme.fontPrimary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Streak and stats metrics
            Row(
              children: [
                // Current streak badge
                streakAsync.when(
                  data: (s) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, size: 16, color: AppColors.orange),
                      const SizedBox(width: 4),
                      Text(
                        '${s.currentStreak}d streak',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.orange,
                          fontFamily: AppTheme.fontPrimary,
                        ),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const Spacer(),

                // Completion rate
                statsAsync.when(
                  data: (s) {
                    final percent = (s.completionRate * 100).toStringAsFixed(0);
                    return Text(
                      '$percent% completion',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: habitColor,
                        fontFamily: AppTheme.fontPrimary,
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Progress bar
            statsAsync.when(
              data: (s) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: s.completionRate.clamp(0.0, 1.0),
                    backgroundColor: AppColors.background,
                    color: habitColor,
                    minHeight: 6,
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
