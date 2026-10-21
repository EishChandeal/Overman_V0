import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/database/app_database.dart';
import 'package:habit_tracker/data/repositories/app_session_repository.dart';

void main() {
  setUp(() async {
    await AppDatabase.openStore();
  });

  tearDown(() {
    AppDatabase.closeStore();
  });

  group('AppSessionRepository (STRAT-02-A)', () {
    test('recordTodayIfAbsent inserts a session and is idempotent on the same day', () async {
      final store = AppDatabase.instance;
      final repo = AppSessionRepository(store);

      final now = DateTime(2026, 10, 22, 10, 30);
      await repo.recordTodayIfAbsent(now: now);

      var count = await repo.totalDaysOpened();
      expect(count, 1);

      // Call again on the same day at different time
      final laterSameDay = DateTime(2026, 10, 22, 23, 15);
      await repo.recordTodayIfAbsent(now: laterSameDay);

      count = await repo.totalDaysOpened();
      expect(count, 1, reason: 'Must not insert duplicates for same calendar day');
    });

    test('totalDaysOpened counts multiple unique calendar days', () async {
      final store = AppDatabase.instance;
      final repo = AppSessionRepository(store);

      await repo.recordTodayIfAbsent(now: DateTime(2026, 10, 19, 9, 0));
      await repo.recordTodayIfAbsent(now: DateTime(2026, 10, 20, 14, 0));
      await repo.recordTodayIfAbsent(now: DateTime(2026, 10, 21, 21, 0));

      expect(await repo.totalDaysOpened(), 3);
    });

    test('currentOpenStreak returns 0 when no sessions exist', () async {
      final store = AppDatabase.instance;
      final repo = AppSessionRepository(store);

      expect(await repo.currentOpenStreak(), 0);
    });

    test('currentOpenStreak returns 1 when only today is recorded', () async {
      final store = AppDatabase.instance;
      final repo = AppSessionRepository(store);
      final today = DateTime(2026, 10, 22, 12, 0);

      await repo.recordTodayIfAbsent(now: today);
      expect(await repo.currentOpenStreak(today: today), 1);
    });

    test('currentOpenStreak returns 1 when only yesterday is recorded and today not yet opened', () async {
      final store = AppDatabase.instance;
      final repo = AppSessionRepository(store);
      final today = DateTime(2026, 10, 22, 12, 0);
      final yesterday = DateTime(2026, 10, 21, 8, 0);

      await repo.recordTodayIfAbsent(now: yesterday);
      expect(await repo.currentOpenStreak(today: today), 1);
    });

    test('currentOpenStreak returns 0 if last open was 2 days ago', () async {
      final store = AppDatabase.instance;
      final repo = AppSessionRepository(store);
      final today = DateTime(2026, 10, 22, 12, 0);
      final twoDaysAgo = DateTime(2026, 10, 20, 8, 0);

      await repo.recordTodayIfAbsent(now: twoDaysAgo);
      expect(await repo.currentOpenStreak(today: today), 0);
    });

    test('currentOpenStreak correctly counts consecutive open days ending today', () async {
      final store = AppDatabase.instance;
      final repo = AppSessionRepository(store);
      final today = DateTime(2026, 10, 22);

      // Record 5 days in a row (Oct 18, 19, 20, 21, 22)
      for (int i = 0; i < 5; i++) {
        await repo.recordTodayIfAbsent(
          now: today.subtract(Duration(days: i)),
        );
      }

      expect(await repo.currentOpenStreak(today: today), 5);
    });

    test('currentOpenStreak correctly counts consecutive days ending yesterday when today not opened', () async {
      final store = AppDatabase.instance;
      final repo = AppSessionRepository(store);
      final today = DateTime(2026, 10, 22);

      // Record 3 days ending yesterday (Oct 19, 20, 21)
      for (int i = 1; i <= 3; i++) {
        await repo.recordTodayIfAbsent(
          now: today.subtract(Duration(days: i)),
        );
      }

      expect(await repo.currentOpenStreak(today: today), 3);
    });

    test('currentOpenStreak resets when a gap occurs', () async {
      final store = AppDatabase.instance;
      final repo = AppSessionRepository(store);
      final today = DateTime(2026, 10, 22);

      // Days: Oct 18, 19 (gap on 20), 21, 22
      await repo.recordTodayIfAbsent(now: DateTime(2026, 10, 18));
      await repo.recordTodayIfAbsent(now: DateTime(2026, 10, 19));
      // gap on 20
      await repo.recordTodayIfAbsent(now: DateTime(2026, 10, 21));
      await repo.recordTodayIfAbsent(now: DateTime(2026, 10, 22));

      expect(await repo.currentOpenStreak(today: today), 2);
    });
  });
}
