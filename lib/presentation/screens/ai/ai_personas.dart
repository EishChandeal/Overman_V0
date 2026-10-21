import '../../../data/database/app_database.dart';
import '../../../data/database/custom_persona_entity.dart';
import '../../../objectbox.g.dart';

enum PersonaId {
  sakuta,
  vegeta,
  dumbledore,
  spiderman,
  nietzsche,
  custom,
}

/// Dynamic identifier that supports both enum values and arbitrary custom character IDs,
/// maintaining backward compatibility with `.name` access and enum equality.
class PersonaIdentifier {
  final String name;
  const PersonaIdentifier(this.name);

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is PersonaIdentifier) return other.name == name;
    if (other is PersonaId) return other.name == name;
    if (other is String) return other == name;
    return false;
  }

  @override
  int get hashCode => name.hashCode;
}

class AiPersona {
  final PersonaIdentifier id;
  final String name;
  final String tagline;
  final String assetPath;
  final String? imagePath;
  final String systemPrompt;
  final bool isCustom;

  const AiPersona({
    required this.id,
    required this.name,
    required this.tagline,
    required this.systemPrompt,
    this.assetPath = '',
    this.imagePath,
    this.isCustom = false,
  });

  /// Factory for default static personas.
  factory AiPersona.fromDefault({
    required PersonaId enumId,
    required String name,
    required String tagline,
    required String assetPath,
    required String systemPrompt,
  }) {
    return AiPersona(
      id: PersonaIdentifier(enumId.name),
      name: name,
      tagline: tagline,
      assetPath: assetPath,
      systemPrompt: systemPrompt,
      isCustom: false,
    );
  }

  /// Factory for user-created custom personas.
  factory AiPersona.custom({
    required String id,
    required String name,
    required String tagline,
    required String systemPrompt,
    String? imagePath,
  }) {
    return AiPersona(
      id: PersonaIdentifier(id),
      name: name,
      tagline: tagline,
      systemPrompt: systemPrompt,
      imagePath: imagePath,
      isCustom: true,
    );
  }

  static AiPersona? fromIdString(String? idStr) {
    if (idStr == null) return null;
    final defaultMatch = kPersonas.where((p) => p.id.name == idStr).firstOrNull;
    if (defaultMatch != null) return defaultMatch;

    if (AppDatabase.isOpen) {
      try {
        final box = AppDatabase.instance.box<CustomPersonaEntity>();
        final query = box.query(CustomPersonaEntity_.id.equals(idStr)).build();
        final match = query.findFirst();
        query.close();
        if (match != null) {
          return match.toDto().toAiPersona();
        }
      } catch (_) {
        // Fallback gracefully in testing or before box is open
      }
    }
    return null;
  }

  static AiPersona? fromId(PersonaId? id) {
    if (id == null) return null;
    return kPersonas.where((p) => p.id.name == id.name).firstOrNull;
  }
}

final List<AiPersona> kPersonas = [
  AiPersona.fromDefault(
    enumId: PersonaId.sakuta,
    name: 'Sakuta Azusagawa',
    tagline: 'Empathetic, grounded & honest guidance',
    assetPath: 'assets/persona_dps/Sakuta Azusagawa.jfif',
    systemPrompt:
        'You are like the main character from rascal does not dream series, '
        'helping people with their mental health and providing a cheerful '
        'environment where the user feels welcomed to talk about their issues '
        'regarding their habits, be sure to be respectful and not say anything '
        'inappropriate',
  ),
  AiPersona.fromDefault(
    enumId: PersonaId.vegeta,
    name: 'Vegeta',
    tagline: 'Prince of all Saiyans — unrelenting discipline',
    assetPath: 'assets/persona_dps/Vegeta.jpg',
    systemPrompt:
        'You are the prince of all saiyans , full of pride and ego, inspiring '
        'others to work their hardest just like you , and be the strongest in the '
        'universe,\nYou make people\'s habits better in a strict and determined way',
  ),
  AiPersona.fromDefault(
    enumId: PersonaId.dumbledore,
    name: 'Albus Dumbledore',
    tagline: 'Headmaster of Hogwarts — patient & wise counsel',
    assetPath: 'assets/persona_dps/Albus Dumbledore.jpg',
    systemPrompt:
        'The headmaster of Hogwarts, strongest sorcerer, you use your old and '
        'wise intellect to guide everyone be better about their habits',
  ),
  AiPersona.fromDefault(
    enumId: PersonaId.spiderman,
    name: 'Peter Parker (Spider-Man)',
    tagline: 'Friendly neighborhood hero — never stays down',
    assetPath: 'assets/persona_dps/Spider-Man.jpg',
    systemPrompt:
        'A person who has not been lucky in life , but still manages to be his '
        'best self, work hard, be a hero, and no matter how bad things are, '
        'he always gets back up, you inspire people to be successful in their '
        'life even if things are sad',
  ),
  AiPersona.fromDefault(
    enumId: PersonaId.nietzsche,
    name: 'Friedrich Nietzsche',
    tagline: 'The philosopher of the Übermensch — ruthless truth',
    assetPath: 'assets/persona_dps/Friedrich Nietzsche.jpg',
    systemPrompt:
        'The man himself, and whom this app is named after. He will guide '
        'user with his philosophical ideas of the \'overman\' Ubermensch , '
        'the ideal MAN ,and with this wit and heavy words that carry weights, '
        'sharp insights, and ruthless presentation of truth without appeasing '
        'the user Nietzsche will guide them. In a tough, unapologetic way, '
        'he will help them become the best version of themselves.',
  ),
];
