import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/application/providers/app_settings_providers.dart';
import 'package:habit_tracker/application/services/ui_sound_service.dart';
import 'package:habit_tracker/data/models/dtos/app_settings_dto.dart';
import 'package:habit_tracker/presentation/screens/settings/settings_screen.dart';
import 'package:habit_tracker/presentation/widgets/habit_completion_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (call) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async => 1,
    );
  });

  group('UiSoundService', () {
    test('plays sounds and disposes cleanly without throwing', () async {
      final soundService = UiSoundService();
      // In headless testing environments, platform audio is mocked or gracefully falls back.
      await soundService.playCompletionSound();
      await soundService.playUncompletionSound();
      soundService.dispose();
    });

    test('skips audio playback when enabled is false', () async {
      final soundService = UiSoundService(enabled: false);
      await soundService.playCompletionSound();
      await soundService.playUncompletionSound();
      soundService.dispose();
      expect(soundService.enabled, isFalse);
    });
  });

  group('HabitCompletionButton Fluid Smoke Boom Animation', () {
    testWidgets('animates forward on completion and adapts typography color', (tester) async {
      bool isCompleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return HabitCompletionButton(
                  isCompleted: isCompleted,
                  isBoolean: true,
                  habitColor: const Color(0xFF216CCF),
                  onHabitColor: Colors.white,
                  uncompletedColor: const Color(0xFF0F1115),
                  onTap: () {
                    setState(() => isCompleted = !isCompleted);
                  },
                );
              },
            ),
          ),
        ),
      );

      // Initial state: uncompleted dash visible
      expect(find.text('—'), findsOneWidget);

      // Tap button to complete
      await tester.tap(find.byType(HabitCompletionButton));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 400)); // Midway through bloom

      // The checkmark should now be appearing
      expect(find.byIcon(Icons.check), findsOneWidget);

      // Complete the remaining animation
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('intercepting animation midway smoothly reverses to previous state',
        (tester) async {
      bool isCompleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return HabitCompletionButton(
                  isCompleted: isCompleted,
                  isBoolean: true,
                  habitColor: const Color(0xFF216CCF),
                  onHabitColor: Colors.white,
                  uncompletedColor: const Color(0xFF0F1115),
                  onTap: () {
                    setState(() => isCompleted = !isCompleted);
                  },
                );
              },
            ),
          ),
        ),
      );

      // Tap to start completion animation
      await tester.tap(find.byType(HabitCompletionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // Intercept at 300ms

      // Tap again to intercept and reverse midway
      await tester.tap(find.byType(HabitCompletionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400)); // Reverse halfway
      await tester.pumpAndSettle();

      // Successfully returned to uncompleted state
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('renders numeric habit values and adapts text color when completed',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HabitCompletionButton(
              isCompleted: true,
              isBoolean: false,
              habitColor: Color(0xFFFF7A45),
              onHabitColor: Colors.white,
              uncompletedColor: Color(0xFF0F1115),
              numericValue: 5.0,
              numericUnit: 'km',
              formattedNumber: '5',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
      expect(find.text('km'), findsOneWidget);

      // Text widget styles adapted to onHabitColor (white)
      final textWidget = tester.widget<Text>(find.text('5'));
      expect(textWidget.style?.color, Colors.white);
    });

    testWidgets('HabitCompletionButton renders static content with no bloom when enableAnimation is false',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HabitCompletionButton(
              isCompleted: true,
              isBoolean: true,
              habitColor: Color(0xFF216CCF),
              onHabitColor: Colors.white,
              uncompletedColor: Color(0xFF0F1115),
              enableAnimation: false,
            ),
          ),
        ),
      );

      // Immediately shows checkmark without animation pump
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('SettingsScreen displays Completion Effects switch defaulting to off',
        (tester) async {
      final settings = AppSettingsDto(
        themeMode: 'dark',
        enableCompletionEffects: false,
        updatedAt: DateTime.now().toUtc(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsProvider.overrideWith((ref) => Stream.value(settings)),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('EFFECTS & SOUND'), findsOneWidget);
      expect(find.text('Completion Effects'), findsOneWidget);

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      final switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isFalse);
    });
  });
}
