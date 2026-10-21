import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/database/app_database.dart';
import 'package:habit_tracker/data/models/dtos/custom_persona_dto.dart';
import 'package:habit_tracker/data/repositories/custom_persona_repository.dart';
import 'package:habit_tracker/presentation/screens/ai/ai_personas.dart';

void main() {
  setUp(() async {
    await AppDatabase.openStore();
  });

  tearDown(() {
    AppDatabase.closeStore();
  });

  group('CustomPersonaRepository', () {
    test('createPersona persists new persona and returns DTO', () async {
      final store = AppDatabase.instance;
      final repo = CustomPersonaRepository(store);

      final persona = await repo.createPersona(
        name: 'Sherlock Holmes',
        tagline: 'Elementary, my dear Watson',
        systemPrompt: 'You are Sherlock Holmes. Analyze habit logs with relentless deductive reasoning.',
        imagePath: '/path/to/sherlock.png',
      );

      expect(persona.id, isNotEmpty);
      expect(persona.name, 'Sherlock Holmes');
      expect(persona.tagline, 'Elementary, my dear Watson');
      expect(persona.systemPrompt, contains('deductive reasoning'));
      expect(persona.imagePath, '/path/to/sherlock.png');

      final fetched = repo.getPersonaById(persona.id);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Sherlock Holmes');
      expect(fetched.tagline, 'Elementary, my dear Watson');
    });

    test('updatePersona modifies existing custom persona', () async {
      final store = AppDatabase.instance;
      final repo = CustomPersonaRepository(store);

      final created = await repo.createPersona(
        name: 'Tony Stark',
        tagline: 'Genius, billionaire, playboy, philanthropist',
        systemPrompt: 'Help build iron discipline.',
      );

      final updatedDto = CustomPersonaDto(
        id: created.id,
        name: 'Iron Man',
        tagline: 'I am Iron Man',
        systemPrompt: 'Push your limits with cutting-edge tech discipline.',
        imagePath: '/images/ironman.jpg',
        createdAt: created.createdAt,
      );

      await repo.updatePersona(updatedDto);

      final fetched = repo.getPersonaById(created.id);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Iron Man');
      expect(fetched.tagline, 'I am Iron Man');
      expect(fetched.systemPrompt, contains('cutting-edge'));
      expect(fetched.imagePath, '/images/ironman.jpg');
    });

    test('deletePersona deletes persona correctly', () async {
      final store = AppDatabase.instance;
      final repo = CustomPersonaRepository(store);

      final persona = await repo.createPersona(
        name: 'Temporary Persona',
        tagline: 'Here for a moment',
        systemPrompt: 'Temporary guidance.',
      );

      expect(repo.getPersonaById(persona.id), isNotNull);

      await repo.deletePersona(persona.id);

      expect(repo.getPersonaById(persona.id), isNull);
    });

    test('getAllPersonas returns all custom personas', () async {
      final store = AppDatabase.instance;
      final repo = CustomPersonaRepository(store);

      await repo.createPersona(
        name: 'Persona Alpha',
        tagline: 'Tagline A',
        systemPrompt: 'Prompt A',
      );
      await repo.createPersona(
        name: 'Persona Beta',
        tagline: 'Tagline B',
        systemPrompt: 'Prompt B',
      );

      final all = await repo.getAllPersonas();
      expect(all.length, greaterThanOrEqualTo(2));
      final names = all.map((p) => p.name).toList();
      expect(names, contains('Persona Alpha'));
      expect(names, contains('Persona Beta'));
    });

    test('AiPersona.fromIdString resolves both default and custom personas in ObjectBox', () async {
      final store = AppDatabase.instance;
      final repo = CustomPersonaRepository(store);

      // 1. Default persona
      final sakuta = AiPersona.fromIdString('sakuta');
      expect(sakuta, isNotNull);
      expect(sakuta!.name, 'Sakuta Azusagawa');
      expect(sakuta.isCustom, isFalse);

      // 2. Custom persona
      final customDto = await repo.createPersona(
        name: 'Marcus Aurelius',
        tagline: 'You have power over your mind',
        systemPrompt: 'Stoic philosopher emperor guiding daily habits.',
      );

      final marcus = AiPersona.fromIdString(customDto.id);
      expect(marcus, isNotNull);
      expect(marcus!.name, 'Marcus Aurelius');
      expect(marcus.tagline, 'You have power over your mind');
      expect(marcus.isCustom, isTrue);
      expect(marcus.id.name, customDto.id);
    });
  });
}
