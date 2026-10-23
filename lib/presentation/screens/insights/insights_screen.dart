import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/providers/providers.dart';
import '../../../application/services/habit_stats_calculator.dart';
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
    final regularHabits = habits.where((h) => !h.isOneTime).toList();
    final tasks = habits.where((h) => h.isOneTime).toList();
    final tasksCreated = tasks.length;
    final tasksCompleted = tasks.where((t) => t.completedAt != null).length;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // 0. User Rank & App Consistency Section
        _buildUserRankSection(context, ref),

        const SizedBox(height: 20),

        // 1. High-level Overview Cards Grid
        _buildOverviewCards(context, ref, regularHabits),

        const SizedBox(height: 20),

        // 2. Weekly Consistency Trend Section
        _buildWeeklyTrendSection(context, ref, regularHabits),

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

        if (regularHabits.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No recurring habits created yet.',
              style: TextStyle(
                color: AppColors.mutedGrey,
                fontSize: 13,
                fontFamily: AppTheme.fontPrimary,
              ),
            ),
          )
        else
          ...regularHabits.map((habit) => _buildHabitPerformanceCard(context, ref, habit)),

        const SizedBox(height: 20),

        // 4. One-Time Tasks Summary Section
        const Text(
          'TASKS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppColors.mutedGrey,
            fontFamily: AppTheme.fontPrimary,
          ),
        ),
        const SizedBox(height: 10),

        _buildTasksSummarySection(
          context,
          tasksCreated: tasksCreated,
          tasksCompleted: tasksCompleted,
        ),
      ],
    );
  }

  Widget _buildUserRankSection(BuildContext context, WidgetRef ref) {
    final rankAsync = ref.watch(userRankProvider);
    final totalDaysAsync = ref.watch(totalDaysOpenedProvider);
    final streakAsync = ref.watch(currentOpenStreakProvider);
    final habitStatsAsync = ref.watch(allHabitCompletionStatsProvider);

    final rank = rankAsync.value ?? UserRank.commonMan;
    final totalDays = totalDaysAsync.value ?? 1;
    final openStreak = streakAsync.value ?? 1;
    final habitStats = habitStatsAsync.value ?? [];

    final rankColor = UserRankService.rankColor(rank);

    return Column(
      children: [
        _UserRankCard(
          rank: rank,
          totalDays: totalDays,
          habitStats: habitStats,
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 16, color: rankColor),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '$totalDays days total',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                          fontFamily: AppTheme.fontPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 18,
                color: AppColors.mutedGrey.withValues(alpha: 0.2),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department, size: 16, color: AppColors.orange),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '$openStreak day streak',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.orange,
                          fontFamily: AppTheme.fontPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                    fontFamily: AppTheme.fontPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
              Flexible(
                child: Text(
                  'Weekly Activity',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                    fontFamily: AppTheme.fontPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
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
    final entriesAsync = ref.watch(habitEntriesProvider(habit.id));
    final scheduleAsync = ref.watch(activeScheduleProvider(habit.id));

    final entries = entriesAsync.value ?? [];
    final activeSchedule = scheduleAsync.value;
    final scheduledWeekdays = activeSchedule?.scheduledWeekdays
            ?.map((w) => w.name)
            .toList() ??
        [];

    final completionRate = HabitStatsCalculator.computeCompletionRate(
      habit,
      entries,
      scheduledWeekdays,
      DateTime.now(),
    );
    final completionFraction = (completionRate / 100.0).clamp(0.0, 1.0);
    final percentText = '${completionRate.toStringAsFixed(0)}% completion';

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
                Text(
                  percentText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: habitColor,
                    fontFamily: AppTheme.fontPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: completionFraction,
                backgroundColor: AppColors.background,
                color: habitColor,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksSummarySection(
    BuildContext context, {
    required int tasksCreated,
    required int tasksCompleted,
  }) {
    final completionRate = tasksCreated > 0
        ? ((tasksCompleted / tasksCreated) * 100).round()
        : 0;

    return Container(
      key: const Key('insights_tasks_summary_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Tasks Created
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.blue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.playlist_add_check,
                          size: 20,
                          color: AppColors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Created',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.mutedGrey,
                                fontFamily: AppTheme.fontPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$tasksCreated',
                              style: const TextStyle(
                                fontSize: 18,
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
              const SizedBox(width: 10),
              // Tasks Completed
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.task_alt,
                          size: 20,
                          color: AppColors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Completed',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.mutedGrey,
                                fontFamily: AppTheme.fontPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$tasksCompleted',
                              style: const TextStyle(
                                fontSize: 18,
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
            ],
          ),
          if (tasksCreated > 0) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Completion Rate',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedGrey,
                    fontFamily: AppTheme.fontPrimary,
                  ),
                ),
                Text(
                  '$completionRate%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                    fontFamily: AppTheme.fontPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (tasksCompleted / tasksCreated).clamp(0.0, 1.0),
                backgroundColor: AppColors.background,
                color: AppColors.orange,
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UserRankCard extends StatefulWidget {
  final UserRank rank;
  final int totalDays;
  final List<HabitCompletionStat> habitStats;

  const _UserRankCard({
    required this.rank,
    required this.totalDays,
    required this.habitStats,
  });

  @override
  State<_UserRankCard> createState() => _UserRankCardState();
}

class _UserRankCardState extends State<_UserRankCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final rank = widget.rank;
    final totalDays = widget.totalDays;
    final rankLabel = UserRankService.rankLabel(rank);
    final rankColor = UserRankService.rankColor(rank);

    final next = UserRankService.nextRank(rank);
    final daysRemaining = UserRankService.daysUntilNextRank(rank, totalDays);
    final nextLabel = next != null ? UserRankService.rankLabel(next) : null;
    final nextColor = next != null ? UserRankService.rankColor(next) : null;

    final targetDays = next != null ? UserRankService.rankTargetDays(next) : 100;
    final prevTarget = UserRankService.rankTargetDays(rank);
    final tierSpan = targetDays - prevTarget;
    final daysInTier = (totalDays - prevTarget).clamp(0, tierSpan);
    final tierProgress = tierSpan > 0 ? (daysInTier / tierSpan).clamp(0.0, 1.0) : 1.0;

    final matureHabits = widget.habitStats.where((s) => s.activeDays >= 7).toList();
    final matureCount = matureHabits.length;
    final qualifyingCount = matureHabits.where((s) => s.completionRate >= 0.95).length;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        key: const Key('insights_user_rank_card'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: rankColor, width: 3),
          ),
        ),
        child: Column(
          children: [
            // Header Row: Rank Label + Expand/Collapse Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 24), // Balance chevron on the right
                Expanded(
                  child: Text(
                    rankLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: rankColor,
                      fontFamily: AppTheme.fontPrimary,
                    ),
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.mutedGrey,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "You've opened the app $totalDays days",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.mutedGrey,
                fontFamily: AppTheme.fontPrimary,
              ),
            ),
            if (rank == UserRank.uebermensch) ...[
              const SizedBox(height: 6),
              Text(
                'All habits followed with excellence',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: rankColor,
                  fontFamily: AppTheme.fontPrimary,
                ),
              ),
            ],
            if (!_isExpanded) ...[
              const SizedBox(height: 8),
              Text(
                'Tap to see next category progress',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.mutedGrey.withValues(alpha: 0.6),
                  fontFamily: AppTheme.fontPrimary,
                ),
              ),
            ],

            // Expanded Details Section
            if (_isExpanded) ...[
              const SizedBox(height: 16),
              Divider(
                color: AppColors.mutedGrey.withValues(alpha: 0.2),
                height: 1,
              ),
              const SizedBox(height: 16),
              Container(
                key: const Key('user_rank_expanded_content'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Next Level Block
                    if (next != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'NEXT CATEGORY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: AppColors.mutedGrey,
                              fontFamily: AppTheme.fontPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: nextColor!.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              nextLabel!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: nextColor,
                                fontFamily: AppTheme.fontPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        daysRemaining > 0
                            ? '$daysRemaining days remaining to reach $nextLabel'
                            : '100+ days milestone met! Complete habits to advance.',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                          fontFamily: AppTheme.fontPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: tierProgress,
                          backgroundColor: AppColors.background,
                          color: nextColor,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$totalDays / $targetDays days opened',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.mutedGrey,
                              fontFamily: AppTheme.fontPrimary,
                            ),
                          ),
                          Text(
                            '${(tierProgress * 100).round()}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: nextColor,
                              fontFamily: AppTheme.fontPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Special Title: Übermensch Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          left: BorderSide(
                            color: UserRankService.rankColor(UserRank.uebermensch),
                            width: 3,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.workspace_premium,
                                size: 16,
                                color: UserRankService.rankColor(UserRank.uebermensch),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  rank == UserRank.uebermensch
                                      ? 'PINNACLE ATTAINED: ÜBERMENSCH'
                                      : 'SPECIAL TITLE: ÜBERMENSCH',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                    color: UserRankService.rankColor(UserRank.uebermensch),
                                    fontFamily: AppTheme.fontPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Criteria: 100+ days opened and >95% completion rate across all active habits.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedGrey,
                              fontFamily: AppTheme.fontPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                totalDays >= 100
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                size: 14,
                                color: totalDays >= 100
                                    ? const Color(0xFF4CAF50)
                                    : AppColors.mutedGrey,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'App Consistency: $totalDays/100 days',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: totalDays >= 100
                                        ? AppColors.primaryText
                                        : AppColors.mutedGrey,
                                    fontWeight: totalDays >= 100
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    fontFamily: AppTheme.fontPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                matureCount > 0 && qualifyingCount == matureCount
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                size: 14,
                                color: matureCount > 0 && qualifyingCount == matureCount
                                    ? const Color(0xFF4CAF50)
                                    : AppColors.mutedGrey,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  matureCount > 0
                                      ? 'Habit Performance: $qualifyingCount/$matureCount mature habits ≥ 95%'
                                      : 'Habit Performance: Requires mature habits (7+ days active)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: matureCount > 0 && qualifyingCount == matureCount
                                        ? AppColors.primaryText
                                        : AppColors.mutedGrey,
                                    fontWeight: matureCount > 0 && qualifyingCount == matureCount
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    fontFamily: AppTheme.fontPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
