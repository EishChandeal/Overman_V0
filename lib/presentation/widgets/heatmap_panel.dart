import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/application/providers/providers.dart';
import 'package:habit_tracker/domain/enums/enums.dart';
import 'package:habit_tracker/domain/services/streak_engine.dart';
import 'package:habit_tracker/presentation/theme/app_theme.dart';

/// Panel displaying the heatmap grid and streak summary for a habit.
class HeatmapPanel extends ConsumerWidget {
  final String habitId;
  final Color? habitColor;

  const HeatmapPanel({
    super.key,
    required this.habitId,
    this.habitColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(habitStreakProvider(habitId));

    return streakAsync.when(
      data: (streakResult) => _buildContent(context, streakResult),
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
            'Failed to load heatmap: $err',
            style: const TextStyle(color: AppColors.mutedGrey, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, StreakResult streak) {
    final palette = context.palette;
    final now = DateTime.now();
    final todayMidnightUtc = DateTime.utc(now.year, now.month, now.day);

    // Align grid to calendar weeks (Monday through Sunday)
    // todayMidnightUtc.weekday: Monday is 1, Sunday is 7
    final currentMonday = todayMidnightUtc.subtract(Duration(days: todayMidnightUtc.weekday - 1));
    // Display 4 full 7-day weeks (28 days), ending with the current week (Sunday)
    final startMonday = currentMonday.subtract(const Duration(days: 21));

    final List<DateTime> days = [];
    for (int i = 0; i < 28; i++) {
      days.add(startMonday.add(Duration(days: i)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Streak counter badges
        Row(
          children: [
            Expanded(
              child: _buildBadge(
                context: context,
                icon: Icons.local_fire_department,
                iconColor: habitColor ?? (palette.isDark ? AppColors.orange : palette.interactiveAccent),
                label: 'Current Streak',
                value: '${streak.currentStreak} ${streak.currentStreak == 1 ? 'day' : 'days'}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildBadge(
                context: context,
                icon: Icons.emoji_events_outlined,
                iconColor: habitColor ?? palette.interactiveAccent,
                label: 'Best Streak',
                value: '${streak.longestStreak} ${streak.longestStreak == 1 ? 'day' : 'days'}',
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Heatmap Calendar Grid (7 columns: Mon to Sun)
        _buildCalendarGrid(context, days, streak.heatmap, todayMidnightUtc),

        const SizedBox(height: 12),

        // Legend
        _buildLegend(context),
      ],
    );
  }

  Widget _buildBadge({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.innerTileBackground,
        borderRadius: BorderRadius.circular(10),
        border: palette.isDark ? null : Border.all(color: palette.innerTileBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: palette.accessibleSecondaryText,
                    fontFamily: AppTheme.fontPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: palette.primaryText,
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
    );
  }

  Widget _buildCalendarGrid(
    BuildContext context,
    List<DateTime> days,
    Map<DateTime, DayStatus> heatmap,
    DateTime todayMidnight,
  ) {
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final palette = context.palette;

    return Column(
      children: [
        // Weekday header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weekdays.map((w) {
            return Expanded(
              child: Center(
                child: Text(
                  w,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: palette.accessibleSecondaryText,
                    fontFamily: AppTheme.fontPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 6),

        // Grid of days (chunks of 7)
        ...List.generate((days.length / 7).ceil(), (weekIndex) {
          final weekDays = days.sublist(
            weekIndex * 7,
            (weekIndex + 1) * 7 > days.length ? days.length : (weekIndex + 1) * 7,
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: weekDays.map((day) {
                final status = heatmap[day] ?? DayStatus.notTracked;
                final isToday = day == todayMidnight;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: _buildDayCell(context, day, status, isToday),
                  ),
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime day, DayStatus status, bool isToday) {
    final palette = context.palette;
    Color cellColor;
    Border? border;
    final activeColor = habitColor ?? palette.interactiveAccent;
    final onActiveColor = HabitVisuals.getOnColor(activeColor);

    switch (status) {
      case DayStatus.met:
      case DayStatus.exceeded:
        cellColor = activeColor;
        break;
      case DayStatus.partiallyMet:
        cellColor = activeColor.withValues(alpha: 0.5);
        break;
      case DayStatus.missed:
        cellColor = palette.isDark
            ? const Color(0xFF232732)
            : palette.cardBorder.withValues(alpha: 0.65);
        border = Border.all(
          color: palette.isDark
              ? AppColors.mutedGrey.withValues(alpha: 0.25)
              : palette.cardBorder,
          width: 1,
        );
        break;
      case DayStatus.notScheduled:
        cellColor = palette.isDark
            ? AppColors.background
            : palette.cardBorder.withValues(alpha: 0.35);
        break;
      case DayStatus.notTracked:
        cellColor = palette.isDark
            ? AppColors.background.withValues(alpha: 0.5)
            : palette.cardBorder.withValues(alpha: 0.20);
        break;
    }

    if (isToday) {
      border = Border.all(
        color: palette.isDark ? AppColors.orange : palette.interactiveAccent,
        width: 1.5,
      );
    }

    return Tooltip(
      message: '${day.day}/${day.month}: ${status.displayName}',
      child: Container(
        height: 28,
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(6),
          border: border,
        ),
        child: Center(
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: status == DayStatus.met || status == DayStatus.exceeded
                  ? onActiveColor
                  : palette.accessibleSecondaryText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final palette = context.palette;
    final activeColor = habitColor ?? palette.interactiveAccent;
    final missedColor = palette.isDark
        ? const Color(0xFF232732)
        : palette.cardBorder.withValues(alpha: 0.65);
    final restColor = palette.isDark
        ? AppColors.background
        : palette.cardBorder.withValues(alpha: 0.35);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(context, activeColor, 'Met'),
        const SizedBox(width: 14),
        _buildLegendItem(context, missedColor, 'Missed', hasBorder: true),
        const SizedBox(width: 14),
        _buildLegendItem(context, restColor, 'Rest / Off'),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label, {bool hasBorder = false}) {
    final palette = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: hasBorder
                ? Border.all(
                    color: palette.isDark
                        ? AppColors.mutedGrey.withValues(alpha: 0.3)
                        : palette.cardBorder,
                    width: 1,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: palette.accessibleSecondaryText,
            fontFamily: AppTheme.fontPrimary,
          ),
        ),
      ],
    );
  }
}
