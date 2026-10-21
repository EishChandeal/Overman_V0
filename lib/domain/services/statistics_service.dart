import 'package:flutter/foundation.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';

/// Pure domain service calculating habit statistics.
///
/// Pragmatic Clean Architecture Note:
/// To ensure zero-overhead functional evaluation without duplicate boilerplate
/// mapping classes, this pure domain calculation operates directly on immutable
/// data records ([HabitEntryDto], [HabitLimitDto]).
class StatisticsResult {
  final double average;
  final double sum;
  final double completionRate;
  final int totalTrackedDays;
  final int totalMissedDays;
  final double bestValue;
  final Map<int, double> weeklyAverages;

  const StatisticsResult({
    required this.average,
    required this.sum,
    required this.completionRate,
    required this.totalTrackedDays,
    required this.totalMissedDays,
    required this.bestValue,
    required this.weeklyAverages,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StatisticsResult &&
        other.average == average &&
        other.sum == sum &&
        other.completionRate == completionRate &&
        other.totalTrackedDays == totalTrackedDays &&
        other.totalMissedDays == totalMissedDays &&
        other.bestValue == bestValue &&
        mapEquals(other.weeklyAverages, weeklyAverages);
  }

  @override
  int get hashCode => Object.hash(
        average,
        sum,
        completionRate,
        totalTrackedDays,
        totalMissedDays,
        bestValue,
        weeklyAverages.length,
      );

  @override
  String toString() {
    return 'StatisticsResult(average: $average, sum: $sum, completionRate: $completionRate, totalTrackedDays: $totalTrackedDays, totalMissedDays: $totalMissedDays, bestValue: $bestValue, weeklyAveragesSize: ${weeklyAverages.length})';
  }
}

class StatisticsService {
  static StatisticsResult calculate({
    required List<HabitEntryDto> entries,
    HabitLimitDto? activeLimit, // TODO: Wire this in for a later phase
  }) {
    if (entries.isEmpty) {
      return const StatisticsResult(
        average: 0.0,
        sum: 0.0,
        completionRate: 0.0,
        totalTrackedDays: 0,
        totalMissedDays: 0,
        bestValue: 0.0,
        weeklyAverages: {},
      );
    }

    double sum = 0.0;
    int totalTrackedDays = 0;
    int totalMissedDays = 0;
    double bestValue = 0.0;
    final Map<int, List<double>> weeklyValues = {};

    for (final entry in entries) {
      sum += entry.value;
      if (entry.value > 0.0) {
        totalTrackedDays++;
      } else {
        totalMissedDays++;
      }

      if (entry.value > bestValue) {
        bestValue = entry.value;
      }

      final weekYearKey = _getIsoYearWeek(entry.date);
      weeklyValues.putIfAbsent(weekYearKey, () => []).add(entry.value);
    }

    final double average = sum / entries.length;
    final double completionRate = totalTrackedDays / entries.length;

    final Map<int, double> weeklyAverages = {};
    weeklyValues.forEach((week, values) {
      final weekSum = values.reduce((a, b) => a + b);
      weeklyAverages[week] = weekSum / values.length;
    });

    return StatisticsResult(
      average: average,
      sum: sum,
      completionRate: completionRate,
      totalTrackedDays: totalTrackedDays,
      totalMissedDays: totalMissedDays,
      bestValue: bestValue,
      weeklyAverages: weeklyAverages,
    );
  }

  static int _getIsoYearWeek(DateTime date) {
    // Normalize to UTC to avoid local timezone midnight boundary issues
    final dateUtc = DateTime.utc(date.year, date.month, date.day);
    
    // ISO week date calendar:
    // Week 1 is the week with the year's first Thursday in it.
    // Find Thursday of this week:
    final thursday = dateUtc.add(Duration(days: 4 - dateUtc.weekday));
    final firstDayOfYear = DateTime.utc(thursday.year, 1, 1);
    final thursdayOfYear =
        firstDayOfYear.add(Duration(days: 4 - firstDayOfYear.weekday));

    final difference = thursday.difference(thursdayOfYear).inDays;
    final weekNum = (difference / 7).floor() + 1;
    
    // The ISO year is the year of that Thursday
    return thursday.year * 100 + weekNum;
  }
}
