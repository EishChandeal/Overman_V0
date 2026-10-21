import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/dtos/dtos.dart';
import '../../domain/enums/enums.dart';
import '../theme/app_theme.dart';

/// Performance chart widget for HabitDetailScreen.
/// Displays a WeeklyCompletionBarChart for boolean habits and
/// a NumericProgressLineChart for numeric habits.
class HabitDetailChart extends StatelessWidget {
  final HabitDto habit;
  final List<HabitEntryDto> entries;
  final HabitScheduleDto? schedule;

  const HabitDetailChart({
    super.key,
    required this.habit,
    required this.entries,
    this.schedule,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Not enough data yet — keep going!',
          key: Key('chart_not_enough_data'),
          style: TextStyle(
            color: AppColors.mutedGrey,
            fontSize: 14,
            fontFamily: AppTheme.fontPrimary,
          ),
        ),
      );
    }

    final habitColor = HabitVisuals.parseColor(habit.colorHex);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height: 180,
        child: habit.type == HabitType.boolean
            ? WeeklyCompletionBarChart(
                entries: entries,
                habitColor: habitColor,
                schedule: schedule,
              )
            : NumericProgressLineChart(
                habit: habit,
                entries: entries,
                habitColor: habitColor,
              ),
      ),
    );
  }
}

/// Bar chart showing completed days per week for the last 12 weeks.
class WeeklyCompletionBarChart extends StatelessWidget {
  final List<HabitEntryDto> entries;
  final Color habitColor;
  final HabitScheduleDto? schedule;

  const WeeklyCompletionBarChart({
    super.key,
    required this.entries,
    required this.habitColor,
    this.schedule,
  });

  int _getScheduledDaysPerWeek() {
    if (schedule != null) {
      if (schedule!.scheduleType == ScheduleType.specificWeekdays &&
          schedule!.scheduledWeekdays != null &&
          schedule!.scheduledWeekdays!.isNotEmpty) {
        return schedule!.scheduledWeekdays!.length;
      } else if (schedule!.scheduleType == ScheduleType.timesPerWeek &&
          schedule!.targetCount != null &&
          schedule!.targetCount! > 0) {
        return schedule!.targetCount!;
      }
    }
    return 7;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final currentMonday =
        todayUtc.subtract(Duration(days: todayUtc.weekday - 1));

    // Entry date map (normalized to midnight UTC)
    final completedDateSet = <DateTime>{};
    for (final e in entries) {
      if (e.value >= 1.0) {
        completedDateSet.add(DateTime.utc(e.date.year, e.date.month, e.date.day));
      }
    }

    final scheduledDays = _getScheduledDaysPerWeek();
    final weekStarts = <DateTime>[];
    final weekCompletions = <int>[];

    for (int i = 11; i >= 0; i--) {
      final monday = currentMonday.subtract(Duration(days: i * 7));
      weekStarts.add(monday);

      int count = 0;
      for (int d = 0; d < 7; d++) {
        final day = monday.add(Duration(days: d));
        if (completedDateSet.contains(day)) {
          count++;
        }
      }
      weekCompletions.add(min(count, scheduledDays));
    }

    final maxY = max(scheduledDays, 1).toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.surface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final weekStart = weekStarts[group.x.toInt()];
              final dateStr = DateFormat('d MMM').format(weekStart);
              return BarTooltipItem(
                'Week of $dateStr\n${rod.toY.toInt()}/$scheduledDays days',
                const TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  fontFamily: AppTheme.fontPrimary,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: max(1, (scheduledDays / 3).floor()).toDouble(),
              getTitlesWidget: (value, meta) {
                if (value == value.roundToDouble() &&
                    value >= 0 &&
                    value <= maxY) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: AppColors.mutedGrey,
                      fontSize: 10,
                      fontFamily: AppTheme.fontPrimary,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < weekStarts.length && idx % 3 == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      DateFormat('d MMM').format(weekStarts[idx]),
                      style: const TextStyle(
                        color: AppColors.mutedGrey,
                        fontSize: 9,
                        fontFamily: AppTheme.fontPrimary,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            if (value == scheduledDays) {
              return FlLine(
                color: AppColors.mutedGrey.withValues(alpha: 0.6),
                strokeWidth: 1.2,
                dashArray: [4, 4],
              );
            }
            return FlLine(
              color: AppColors.mutedGrey.withValues(alpha: 0.08),
              strokeWidth: 0.8,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: scheduledDays.toDouble(),
              color: AppColors.mutedGrey.withValues(alpha: 0.6),
              strokeWidth: 1.2,
              dashArray: [4, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 4, bottom: 2),
                style: const TextStyle(
                  color: AppColors.mutedGrey,
                  fontSize: 9,
                  fontFamily: AppTheme.fontPrimary,
                ),
                labelResolver: (line) => 'Goal ($scheduledDays)',
              ),
            ),
          ],
        ),
        barGroups: [
          for (int i = 0; i < 12; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: weekCompletions[i].toDouble(),
                  color: habitColor,
                  width: 12,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Line chart showing raw values for the last 30 days with a target dashed line.
class NumericProgressLineChart extends StatelessWidget {
  final HabitDto habit;
  final List<HabitEntryDto> entries;
  final Color habitColor;

  const NumericProgressLineChart({
    super.key,
    required this.habit,
    required this.entries,
    required this.habitColor,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);

    final entryMap = <DateTime, double>{};
    for (final e in entries) {
      final dt = DateTime.utc(e.date.year, e.date.month, e.date.day);
      entryMap[dt] = e.value;
    }

    final dates = <DateTime>[];
    final spots = <FlSpot>[];
    double maxEntryValue = 0.0;

    for (int i = 29; i >= 0; i--) {
      final date = todayUtc.subtract(Duration(days: i));
      dates.add(date);

      final val = entryMap[date] ?? 0.0;
      if (val > maxEntryValue) {
        maxEntryValue = val;
      }
      spots.add(FlSpot((29 - i).toDouble(), val));
    }

    final target = habit.targetValue ?? 1.0;
    final maxY = max(max(target, maxEntryValue) * 1.15, 1.0);

    final unitStr =
        (habit.unit != null && habit.unit!.isNotEmpty) ? ' ${habit.unit}' : '';
    final targetStr = target == target.roundToDouble()
        ? target.toInt().toString()
        : target.toString();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        minX: 0,
        maxX: 29,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surface,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final date = dates[spot.x.toInt()];
                final dateStr = DateFormat('d MMM').format(date);
                final valStr = spot.y == spot.y.roundToDouble()
                    ? spot.y.toInt().toString()
                    : spot.y.toStringAsFixed(1);
                return LineTooltipItem(
                  '$dateStr\n$valStr$unitStr',
                  const TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    fontFamily: AppTheme.fontPrimary,
                  ),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: max(1, (maxY / 4).roundToDouble()),
              getTitlesWidget: (value, meta) {
                if (value == value.roundToDouble() &&
                    value >= 0 &&
                    value <= maxY) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: AppColors.mutedGrey,
                      fontSize: 10,
                      fontFamily: AppTheme.fontPrimary,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < dates.length && idx % 7 == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      DateFormat('d MMM').format(dates[idx]),
                      style: const TextStyle(
                        color: AppColors.mutedGrey,
                        fontSize: 9,
                        fontFamily: AppTheme.fontPrimary,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: max(1, (maxY / 4).roundToDouble()),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.mutedGrey.withValues(alpha: 0.08),
              strokeWidth: 0.8,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (habit.targetValue != null && habit.targetValue! > 0)
              HorizontalLine(
                y: target,
                color: Colors.white.withValues(alpha: 0.4),
                strokeWidth: 1.5,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 6, bottom: 2),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontFamily: AppTheme.fontPrimary,
                  ),
                  labelResolver: (line) => 'Target: $targetStr$unitStr',
                ),
              ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.2,
            color: habitColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: habitColor,
                  strokeWidth: 1.5,
                  strokeColor: AppColors.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: habitColor.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
