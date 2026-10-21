import 'dart:math';
import 'package:habit_tracker/data/database/quote_entity.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/objectbox.g.dart';

/// Service responsible for selecting quotes for the splash screen and daily reflections.
class QuoteService {
  final Box<QuoteEntity> _quoteBox;
  final Random _random;

  QuoteService(Store store, {Random? random})
      : _quoteBox = store.box<QuoteEntity>(),
        _random = random ?? Random();

  /// Selects a quote according to PROD-05 selection logic:
  /// 1. Query for today's day-of-year matching active quote.
  /// 2. Otherwise pick a random active quote.
  /// 3. If the box is empty, return the hardcoded fallback:
  ///    "Become who you are." — Friedrich Nietzsche
  QuoteDto pickQuote({DateTime? now}) {
    final today = now ?? DateTime.now();
    final firstDayOfYear = DateTime(today.year, 1, 1);
    final dayOfYear = today.difference(firstDayOfYear).inDays + 1;

    // 1. Check for day-of-year match among active quotes
    final dayQuery = _quoteBox
        .query(QuoteEntity_.dayOfYear
            .equals(dayOfYear)
            .and(QuoteEntity_.isActive.equals(true)))
        .build();
    final dayMatch = dayQuery.findFirst();
    dayQuery.close();

    if (dayMatch != null) {
      return dayMatch.toDto();
    }

    // 2. Pick a random active quote
    final activeQuery = _quoteBox
        .query(QuoteEntity_.isActive.equals(true))
        .build();
    final activeQuotes = activeQuery.find();
    activeQuery.close();

    if (activeQuotes.isNotEmpty) {
      final index = _random.nextInt(activeQuotes.length);
      return activeQuotes[index].toDto();
    }

    // 3. Hardcoded fallback
    return const QuoteDto(
      id: 'fallback',
      text: 'Become who you are.',
      author: 'Friedrich Nietzsche',
      isActive: true,
    );
  }
}
