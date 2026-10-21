import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/application/services/user_rank_service.dart';
import 'package:habit_tracker/presentation/theme/app_theme.dart';

void main() {
  group('UserRankService (STRAT-02-B)', () {
    test('0 days -> commonMan', () {
      final rank = UserRankService.computeRank(
        totalDaysOpened: 0,
        habitStats: [],
      );
      expect(rank, UserRank.commonMan);
      expect(UserRankService.rankLabel(rank), 'Common Man');
      expect(UserRankService.rankColor(rank), const Color(0xFF9E9E9E));
    });

    test('15 days -> man', () {
      final rank = UserRankService.computeRank(
        totalDaysOpened: 15,
        habitStats: [],
      );
      expect(rank, UserRank.man);
      expect(UserRankService.rankLabel(rank), 'Man');
      expect(UserRankService.rankColor(rank), const Color(0xFF4CAF50));
    });

    test('30 days -> theMan', () {
      final rank = UserRankService.computeRank(
        totalDaysOpened: 30,
        habitStats: [],
      );
      expect(rank, UserRank.theMan);
      expect(UserRankService.rankLabel(rank), 'The Man');
      expect(UserRankService.rankColor(rank), AppColors.blue);
    });

    test('60 days -> exceptionalOne', () {
      final rank = UserRankService.computeRank(
        totalDaysOpened: 60,
        habitStats: [],
      );
      expect(rank, UserRank.exceptionalOne);
      expect(UserRankService.rankLabel(rank), 'Exceptional One');
      expect(UserRankService.rankColor(rank), AppColors.orange);
    });

    test('100 days, 50% completion -> chosenOne', () {
      final stats = [
        const HabitCompletionStat(habitId: 'h1', completedDays: 10, activeDays: 20),
      ];
      final rank = UserRankService.computeRank(
        totalDaysOpened: 100,
        habitStats: stats,
      );
      expect(rank, UserRank.chosenOne);
      expect(UserRankService.rankLabel(rank), 'Chosen One');
      expect(UserRankService.rankColor(rank), const Color(0xFFFFD700));
    });

    test('100 days, 96% completion across all habits -> uebermensch', () {
      final stats = [
        const HabitCompletionStat(habitId: 'h1', completedDays: 96, activeDays: 100),
        const HabitCompletionStat(habitId: 'h2', completedDays: 48, activeDays: 50),
      ];
      final rank = UserRankService.computeRank(
        totalDaysOpened: 100,
        habitStats: stats,
      );
      expect(rank, UserRank.uebermensch);
      expect(UserRankService.rankLabel(rank), 'Übermensch');
      expect(UserRankService.rankColor(rank), const Color(0xFF9B59B6));
    });

    test('95 days, 99% completion -> exceptionalOne (not Übermensch — days < 100)', () {
      final stats = [
        const HabitCompletionStat(habitId: 'h1', completedDays: 99, activeDays: 100),
      ];
      final rank = UserRankService.computeRank(
        totalDaysOpened: 95,
        habitStats: stats,
      );
      expect(rank, UserRank.exceptionalOne);
    });

    test('nextRank, rankTargetDays, and daysUntilNextRank computations', () {
      expect(UserRankService.nextRank(UserRank.commonMan), UserRank.man);
      expect(UserRankService.nextRank(UserRank.man), UserRank.theMan);
      expect(UserRankService.nextRank(UserRank.theMan), UserRank.exceptionalOne);
      expect(UserRankService.nextRank(UserRank.exceptionalOne), UserRank.chosenOne);
      expect(UserRankService.nextRank(UserRank.chosenOne), UserRank.uebermensch);
      expect(UserRankService.nextRank(UserRank.uebermensch), isNull);

      expect(UserRankService.rankTargetDays(UserRank.man), 15);
      expect(UserRankService.rankTargetDays(UserRank.theMan), 30);
      expect(UserRankService.rankTargetDays(UserRank.exceptionalOne), 60);
      expect(UserRankService.rankTargetDays(UserRank.chosenOne), 100);

      // Remaining days calculation
      expect(UserRankService.daysUntilNextRank(UserRank.commonMan, 5), 10);
      expect(UserRankService.daysUntilNextRank(UserRank.man, 20), 10);
      expect(UserRankService.daysUntilNextRank(UserRank.theMan, 45), 15);
      expect(UserRankService.daysUntilNextRank(UserRank.exceptionalOne, 75), 25);
      expect(UserRankService.daysUntilNextRank(UserRank.chosenOne, 100), 0);
      expect(UserRankService.daysUntilNextRank(UserRank.uebermensch, 120), 0);
    });
  });
}
