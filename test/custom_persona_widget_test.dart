import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:objectbox/objectbox.dart';

import 'package:habit_tracker/application/providers/providers.dart';
import 'package:habit_tracker/data/database/app_database.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/data/repositories/repositories.dart';
import 'package:habit_tracker/presentation/screens/ai/ai_chat_screen.dart';
import 'package:habit_tracker/presentation/screens/ai/ai_personas.dart';
import 'package:habit_tracker/presentation/screens/ai/ai_settings_screen.dart';
import 'package:habit_tracker/presentation/screens/ai/custom_persona_dialog.dart';
import 'package:habit_tracker/presentation/theme/app_theme.dart';
import 'package:habit_tracker/presentation/widgets/persona_avatar.dart';

void main() {
  late Store testStore;
  late CustomPersonaRepository personaRepo;
  late AiSettingsRepository settingsRepo;

  setUpAll(() async {
    testStore = await AppDatabase.openStore();
    personaRepo = CustomPersonaRepository(testStore);
    settingsRepo = AiSettingsRepository(testStore);
  });

  tearDownAll(() {
    AppDatabase.closeStore();
  });

  group('PersonaAvatar Widget', () {
    testWidgets('renders default persona asset image', (tester) async {
      final defaultPersona = kPersonas.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PersonaAvatar(persona: defaultPersona, radius: 24),
          ),
        ),
      );

      final circleAvatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(circleAvatar.backgroundImage, isA<AssetImage>());
      final assetImg = circleAvatar.backgroundImage as AssetImage;
      expect(assetImg.assetName, defaultPersona.assetPath);
    });

    testWidgets('renders fallback person icon for custom persona without image', (tester) async {
      final customPersona = AiPersona.custom(
        id: 'custom-test-1',
        name: 'Sensei',
        tagline: 'Wise teacher',
        systemPrompt: 'Guide with wisdom.',
        imagePath: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PersonaAvatar(persona: customPersona, radius: 24),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('renders fallback robot icon when persona is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PersonaAvatar(persona: null, radius: 24),
          ),
        ),
      );

      expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
    });
  });

  group('CustomPersonaDialog', () {
    testWidgets('validates required fields and creates custom persona', (tester) async {
      tester.view.physicalSize = const Size(412 * 3, 1200 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      AiPersona? createdResult;
      bool pickImageCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  final result = await showDialog<AiPersona>(
                    context: context,
                    builder: (ctx) => CustomPersonaDialog(
                      repository: personaRepo,
                      onPickImage: () async {
                        pickImageCalled = true;
                        return '/mock/path/profile.png';
                      },
                    ),
                  );
                  createdResult = result;
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Create Custom Character'), findsOneWidget);
      expect(find.text('Choose Profile Picture'), findsOneWidget);

      // 1. Try to save with empty inputs -> Name validation
      await tester.tap(find.byKey(const Key('custom_persona_save_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a character name.'), findsOneWidget);

      // 2. Enter name, try to save -> Prompt validation
      await tester.enterText(
        find.byKey(const Key('custom_persona_name_input')),
        'Master Roshi',
      );
      await tester.tap(find.byKey(const Key('custom_persona_save_btn')));
      await tester.pumpAndSettle();
      expect(
        find.text('Please define character personality instructions.'),
        findsOneWidget,
      );

      // 3. Enter tagline and system prompt
      await tester.enterText(
        find.byKey(const Key('custom_persona_tagline_input')),
        'Turtle Hermit of martial arts',
      );
      await tester.enterText(
        find.byKey(const Key('custom_persona_prompt_input')),
        'Work hard, study well, and eat and sleep plenty! That is the Turtle Hermit way.',
      );

      // 4. Tap Choose Profile Picture
      await tester.tap(find.byKey(const Key('custom_persona_pick_picture_btn')));
      await tester.pumpAndSettle();
      expect(pickImageCalled, isTrue);

      // 5. Save Character
      await tester.tap(find.byKey(const Key('custom_persona_save_btn')));
      await tester.pumpAndSettle();

      // Dialog closed and returned persona
      expect(createdResult, isNotNull);
      expect(createdResult!.name, 'Master Roshi');
      expect(createdResult!.tagline, 'Turtle Hermit of martial arts');
      expect(createdResult!.isCustom, isTrue);

      // Verify in ObjectBox repository
      final fetched = personaRepo.getPersonaById(createdResult!.id.name);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Master Roshi');
      expect(fetched.systemPrompt, contains('Turtle Hermit way'));
    });

    testWidgets('allows editing and deleting an existing custom persona', (tester) async {
      tester.view.physicalSize = const Size(412 * 3, 1200 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Seed a custom persona in DB
      final initialDto = await personaRepo.createPersona(
        name: 'Vegeta Senior',
        tagline: 'Saiyan King',
        systemPrompt: 'Strict discipline.',
      );
      final initialPersona = initialDto.toAiPersona();

      dynamic dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  final result = await showDialog<dynamic>(
                    context: context,
                    builder: (ctx) => CustomPersonaDialog(
                      existingPersona: initialPersona,
                      repository: personaRepo,
                    ),
                  );
                  dialogResult = result;
                },
                child: const Text('Edit Dialog'),
              ),
            ),
          ),
        ),
      );

      // 1. Open Edit Dialog
      await tester.tap(find.text('Edit Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Character'), findsOneWidget);
      expect(find.text('Vegeta Senior'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.byKey(const Key('custom_persona_delete_btn')), findsOneWidget);

      // 2. Edit Tagline & Save
      await tester.enterText(
        find.byKey(const Key('custom_persona_tagline_input')),
        'King of all Saiyans',
      );
      await tester.tap(find.byKey(const Key('custom_persona_save_btn')));
      await tester.pumpAndSettle();

      expect(dialogResult, isA<AiPersona>());
      expect((dialogResult as AiPersona).tagline, 'King of all Saiyans');

      // Verify DB update
      final updatedInDb = personaRepo.getPersonaById(initialDto.id);
      expect(updatedInDb!.tagline, 'King of all Saiyans');

      // 3. Re-open and Delete
      await tester.tap(find.text('Edit Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('custom_persona_delete_btn')));
      await tester.pumpAndSettle();

      // Delete confirmation dialog appears
      expect(find.text('Delete Character'), findsOneWidget);
      expect(find.textContaining('Are you sure you want to delete'), findsOneWidget);

      // Confirm delete
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(dialogResult, 'deleted');
      final deletedCheck = personaRepo.getPersonaById(initialDto.id);
      expect(deletedCheck, isNull);
    });
  });

  group('AiSettingsScreen with Custom Personas', () {
    testWidgets('renders Add Custom button, Custom Persona tile, and newly created custom personas',
        (tester) async {
      tester.view.physicalSize = const Size(412 * 3, 1400 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Create a custom persona in DB
      final custom = await personaRepo.createPersona(
        name: 'Goku Son',
        tagline: 'Always striving beyond limits',
        systemPrompt: 'Push beyond your limits through daily training!',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            objectBoxStoreProvider.overrideWith((ref) async => testStore),
            customPersonaRepositoryProvider.overrideWith((ref) async => personaRepo),
            aiSettingsRepositoryProvider.overrideWith((ref) async => settingsRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AiSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Header and Add Custom button
      expect(find.byKey(const Key('add_custom_persona_btn')), findsOneWidget);
      expect(find.text('Add Custom'), findsOneWidget);

      // Drag up to reveal personas section
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // 2. Verify Default Personas are present
      expect(find.text('Sakuta Azusagawa'), findsOneWidget);
      expect(find.text('Vegeta'), findsOneWidget);

      // 3. Verify Custom Persona is present with edit button
      expect(find.text('Goku Son'), findsOneWidget);
      expect(find.text('Always striving beyond limits'), findsOneWidget);
      expect(find.byKey(Key('edit_persona_${custom.id}')), findsOneWidget);

      // 4. Verify Create Character tile at the end of grid
      expect(find.byKey(const Key('create_character_tile')), findsOneWidget);
      expect(find.text('Custom Persona'), findsOneWidget);
    });

    testWidgets('selects custom persona and navigates to AiChatScreen with custom persona details',
        (tester) async {
      tester.view.physicalSize = const Size(412 * 3, 1400 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Prepare settings with credentials
      await settingsRepo.saveSettings(
        AiSettingsDto(
          apiEndpoint: 'https://generativelanguage.googleapis.com/v1beta',
          apiKey: 'test-api-key',
          updatedAt: DateTime.now(),
        ),
      );

      final custom = await personaRepo.createPersona(
        name: 'Sensei Kakashi',
        tagline: 'The Copy Ninja',
        systemPrompt: 'Guide with ninja discipline and quiet dedication.',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            objectBoxStoreProvider.overrideWith((ref) async => testStore),
            customPersonaRepositoryProvider.overrideWith((ref) async => personaRepo),
            aiSettingsRepositoryProvider.overrideWith((ref) async => settingsRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AiSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Drag up to reveal personas
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // Tap on Sensei Kakashi card to select
      await tester.tap(find.byKey(Key('persona_card_${custom.id}')));
      await tester.pumpAndSettle();

      // Verify setting updated
      final updatedSettings = await settingsRepo.getSettings();
      expect(updatedSettings.selectedPersona, custom.id);

      // Drag down to reveal Start Chat button at bottom
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Start Chat'));
      await tester.pumpAndSettle();

      // Verify navigated to AiChatScreen
      expect(find.byType(AiChatScreen), findsOneWidget);
      expect(find.text('Sensei Kakashi'), findsOneWidget);
      expect(find.text('Chat with Sensei Kakashi'), findsOneWidget);
    });
  });
}
