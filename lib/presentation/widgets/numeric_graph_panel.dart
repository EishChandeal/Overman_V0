import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:habit_tracker/application/providers/providers.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/presentation/theme/app_theme.dart';

/// Panel displaying a 7-day trend bar graph for numeric habits only.
class NumericGraphPanel extends ConsumerWidget {
  final HabitDto habit;

  const NumericGraphPanel({super.key, required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesStream = ref.watch(habitEntriesProvider(habit.id));

    return entriesStream.when(
      data: (entries) => _buildGraph(context, entries),
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
            'Failed to load entries: $err',
            style: const TextStyle(color: AppColors.mutedGrey, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildGraph(BuildContext context, List<HabitEntryDto> entries) {
    final habitColor = HabitVisuals.parseColor(habit.colorHex);
    final now = DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);

    // Build the last 7 days map
    final entryMap = {for (final e in entries) DateTime.utc(e.date.year, e.date.month, e.date.day): e};

    final List<Map<String, dynamic>> daysData = [];
    double maxValue = habit.targetValue ?? 1.0;

    for (int i = 6; i >= 0; i--) {
      final d = todayUtc.subtract(Duration(days: i));
      final entry = entryMap[d];
      final val = entry?.value ?? 0.0;
      if (val > maxValue) {
        maxValue = val;
      }
      daysData.add({
        'date': d,
        'value': val,
        'weekday': DateFormat('E').format(d)[0], // e.g. 'M', 'T', 'W'
        'isToday': i == 0,
      });
    }

    if (maxValue <= 0) {
      maxValue = 1.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with target reminder
        if (habit.targetValue != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Last 7 Days',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mutedGrey,
                    fontFamily: AppTheme.fontPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Daily Goal: ${_formatVal(habit.targetValue!)} ${habit.unit ?? ''}',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 11,
                      color: habitColor,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTheme.fontPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

        // Bar Chart
        Container(
          height: 130,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: daysData.map((d) {
              final double val = d['value'];
              final String label = d['weekday'];
              final bool isToday = d['isToday'];
              final target = habit.targetValue ?? 0.0;
              final isTargetMet = target > 0 && val >= target;

              // Normalized bar height ratio
              final ratio = (val / maxValue).clamp(0.06, 1.0);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Value text on top of bar
                      if (val > 0)
                        Text(
                          _formatCompactVal(val),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isTargetMet ? habitColor : AppColors.mutedGrey,
                          ),
                          maxLines: 1,
                        )
                      else
                        const SizedBox(height: 12),

                      const SizedBox(height: 4),

                      // Animated/Sized bar
                      Flexible(
                        child: FractionallySizedBox(
                          heightFactor: ratio,
                          child: Container(
                            decoration: BoxDecoration(
                              color: val > 0
                                  ? (isTargetMet
                                      ? habitColor
                                      : habitColor.withValues(alpha: 0.45))
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(5),
                              border: isToday
                                  ? Border.all(
                                      color: AppColors.orange,
                                      width: 1.2,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Weekday letter label
                      Text(
                        isToday ? 'Now' : label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday ? AppColors.orange : AppColors.mutedGrey,
                          fontFamily: AppTheme.fontPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _formatVal(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
  }

  String _formatCompactVal(double val) {
    if (val >= 1000) {
      final k = val / 1000;
      return '${k == k.roundToDouble() ? k.toInt() : k.toStringAsFixed(1)}k';
    }
    return _formatVal(val);
  }
}
