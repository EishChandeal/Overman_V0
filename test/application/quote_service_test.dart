import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/application/services/quote_service.dart';
import 'package:habit_tracker/data/database/app_database.dart';
import 'package:habit_tracker/data/database/quote_entity.dart';
import 'package:habit_tracker/data/seeders/quote_seeder.dart';

void main() {
  setUp(() async {
    await AppDatabase.openStore();
  });

  tearDown(() {
    AppDatabase.closeStore();
  });

  group('QuoteService & QuoteSeeder tests', () {
    test('QuoteSeeder seeds 10 quotes when empty and is idempotent', () async {
      final store = AppDatabase.instance;
      final box = store.box<QuoteEntity>();
      expect(box.count(), 0);

      // Seed first time
      await QuoteSeeder.seedIfEmpty(store);
      expect(box.count(), 10);

      // Seed second time - should be a no-op
      await QuoteSeeder.seedIfEmpty(store);
      expect(box.count(), 10);
    });

    test('pickQuote returns hardcoded fallback when store is empty', () {
      final store = AppDatabase.instance;
      final service = QuoteService(store);

      final quote = service.pickQuote();
      expect(quote.text, 'Become who you are.');
      expect(quote.author, 'Friedrich Nietzsche');
      expect(quote.id, 'fallback');
    });

    test('pickQuote selects matching active quote when dayOfYear matches today', () {
      final store = AppDatabase.instance;
      final box = store.box<QuoteEntity>();

      final testDate = DateTime.utc(2026, 10, 21);
      final firstDay = DateTime.utc(testDate.year, 1, 1);
      final dayOfYear = testDate.difference(firstDay).inDays + 1;

      // Put quotes: one matching dayOfYear, one other active, one inactive matching
      final matchingQuote = QuoteEntity(
        id: 'q-match',
        text: 'The unexamined life is not worth living.',
        author: 'Socrates',
        dayOfYear: dayOfYear,
        isActive: true,
      );
      final otherQuote = QuoteEntity(
        id: 'q-other',
        text: 'Know thyself.',
        author: 'Temple of Apollo',
        dayOfYear: null,
        isActive: true,
      );
      box.putMany([matchingQuote, otherQuote]);

      final service = QuoteService(store);
      final picked = service.pickQuote(now: testDate);

      expect(picked.id, 'q-match');
      expect(picked.text, 'The unexamined life is not worth living.');
      expect(picked.author, 'Socrates');
    });

    test('pickQuote ignores inactive quote even if dayOfYear matches', () {
      final store = AppDatabase.instance;
      final box = store.box<QuoteEntity>();

      final testDate = DateTime.utc(2026, 10, 21);
      final firstDay = DateTime.utc(testDate.year, 1, 1);
      final dayOfYear = testDate.difference(firstDay).inDays + 1;

      final inactiveMatch = QuoteEntity(
        id: 'q-inactive',
        text: 'Inactive match',
        author: 'Nobody',
        dayOfYear: dayOfYear,
        isActive: false,
      );
      final activeFallback = QuoteEntity(
        id: 'q-active',
        text: 'Active fallback',
        author: 'Somebody',
        dayOfYear: null,
        isActive: true,
      );
      box.putMany([inactiveMatch, activeFallback]);

      final service = QuoteService(store);
      final picked = service.pickQuote(now: testDate);

      expect(picked.id, 'q-active');
      expect(picked.text, 'Active fallback');
    });

    test('pickQuote falls back to random active quote when no dayOfYear match', () {
      final store = AppDatabase.instance;
      final box = store.box<QuoteEntity>();

      final q1 = QuoteEntity(
        id: 'q-1',
        text: 'First active quote',
        author: 'Author 1',
        isActive: true,
      );
      final q2 = QuoteEntity(
        id: 'q-2',
        text: 'Second active quote',
        author: 'Author 2',
        isActive: true,
      );
      box.putMany([q1, q2]);

      // Seed deterministic Random to pick index 1
      final random = Random(42);
      final service = QuoteService(store, random: random);

      final picked = service.pickQuote(now: DateTime.utc(2026, 1, 15));
      expect(picked.isActive, isTrue);
      expect(['q-1', 'q-2'], contains(picked.id));
    });
  });
}
