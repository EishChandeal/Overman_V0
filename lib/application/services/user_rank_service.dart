import 'package:flutter/material.dart';
import 'package:habit_tracker/presentation/theme/app_theme.dart';

enum UserRank {
  commonMan,
  man,
  theMan,
  exceptionalOne,
  chosenOne,
  uebermensch,
}

class HabitCompletionStat {
  final String habitId;
  final int completedDays;
  final int activeDays; // days since createdAt that the habit was scheduled

  const HabitCompletionStat({
    required this.habitId,
    required this.completedDays,
    required this.activeDays,
  });

  double get completionRate =>
      activeDays == 0 ? 0.0 : completedDays / activeDays;
}

class UserRankService {
  /// Computes the user's category/rank based on total days the app was opened
  /// and (for Übermensch) completion rates of mature habits (active >= 7 days).
  static UserRank computeRank({
    required int totalDaysOpened,
    required List<HabitCompletionStat> habitStats,
  }) {
    if (totalDaysOpened < 15) {
      return UserRank.commonMan;
    } else if (totalDaysOpened < 30) {
      return UserRank.man;
    } else if (totalDaysOpened < 60) {
      return UserRank.theMan;
    } else if (totalDaysOpened < 100) {
      return UserRank.exceptionalOne;
    }

    // 100+ days opened
    // "Übermensch" condition:
    // 100+ days opened AND all habits (that have been active >= 7 days) have >= 95% completion
    final matureHabits = habitStats.where((s) => s.activeDays >= 7).toList();
    if (matureHabits.isNotEmpty &&
        matureHabits.every((s) => s.completionRate >= 0.95)) {
      return UserRank.uebermensch;
    }

    return UserRank.chosenOne;
  }

  /// Returns human-readable label for the user rank.
  static String rankLabel(UserRank rank) {
    switch (rank) {
      case UserRank.commonMan:
        return 'Common Man';
      case UserRank.man:
        return 'Man';
      case UserRank.theMan:
        return 'The Man';
      case UserRank.exceptionalOne:
        return 'Exceptional One';
      case UserRank.chosenOne:
        return 'Chosen One';
      case UserRank.uebermensch:
        return 'Übermensch';
    }
  }

  /// Returns the badge color representing the user rank.
  static Color rankColor(UserRank rank) {
    switch (rank) {
      case UserRank.commonMan:
        return const Color(0xFF9E9E9E); // Muted grey
      case UserRank.man:
        return const Color(0xFF4CAF50); // Muted green
      case UserRank.theMan:
        return AppColors.blue;
      case UserRank.exceptionalOne:
        return AppColors.orange;
      case UserRank.chosenOne:
        return const Color(0xFFFFD700); // Gold
      case UserRank.uebermensch:
        return const Color(0xFF9B59B6); // Purple / Violet
    }
  }
}
