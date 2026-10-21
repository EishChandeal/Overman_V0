import 'package:uuid/uuid.dart';
import 'package:habit_tracker/data/database/quote_entity.dart';
import 'package:habit_tracker/objectbox.g.dart';

/// Seeds initial quotes into ObjectBox on first application launch.
class QuoteSeeder {
  static const List<Map<String, String>> initialQuotes = [
    {
      'text': 'Become who you are.',
      'author': 'Friedrich Nietzsche',
    },
    {
      'text': 'He who has a why to live can bear almost any how.',
      'author': 'Friedrich Nietzsche',
    },
    {
      'text': 'Without music, life would be a mistake.',
      'author': 'Friedrich Nietzsche',
    },
    {
      'text': 'It does not matter how slowly you go as long as you do not stop.',
      'author': 'Confucius',
    },
    {
      'text': 'We are what we repeatedly do. Excellence, then, is not an act but a habit.',
      'author': 'Aristotle',
    },
    {
      'text': 'With great power comes great responsibility.',
      'author': 'Uncle Ben',
    },
    {
      'text': "Push beyond your limits. That's what makes a Super Saiyan.",
      'author': 'Vegeta',
    },
    {
      'text': 'It is our choices that show what we truly are, far more than our abilities.',
      'author': 'Albus Dumbledore',
    },
    {
      'text': 'Blessed by the heavens above, you stand invicible under the sun.',
      'author': 'Takehiko Inoue',
    },
    {
      'text': 'My sword lies among the heavens and the earth.',
      'author': 'Takehiko Inoue',
    },
  ];

  /// Seeds quotes into the store only if the box is currently empty.
  static Future<void> seedIfEmpty(Store store) async {
    final box = store.box<QuoteEntity>();
    if (box.count() > 0) return;

    final entities = initialQuotes.map((q) {
      return QuoteEntity(
        id: const Uuid().v4(),
        text: q['text']!,
        author: q['author'],
        dayOfYear: null,
        isActive: true,
      );
    }).toList();

    box.putMany(entities);
  }
}
